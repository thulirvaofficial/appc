import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/subscription_provider.dart';
import '../orders/customer_live_tracking_screen.dart';

class CustomerSubscriptionDetailsScreen extends ConsumerStatefulWidget {
  final SubscriptionModel subscription;

  const CustomerSubscriptionDetailsScreen({super.key, required this.subscription});

  @override
  ConsumerState<CustomerSubscriptionDetailsScreen> createState() =>
      _CustomerSubscriptionDetailsScreenState();
}

class _CustomerSubscriptionDetailsScreenState
    extends ConsumerState<CustomerSubscriptionDetailsScreen> {
  late SubscriptionModel _sub;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.subscription;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppColors.forestGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleTogglePause() async {
    final isCurrentlyPaused = _sub.isPaused;
    final action = isCurrentlyPaused ? 'Resume' : 'Pause';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$action Deliveries?',
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestGreen),
        ),
        content: Text(
          isCurrentlyPaused
              ? 'Resume daily morning milk deliveries from tomorrow?'
              : 'Temporarily pause deliveries? You can resume anytime without losing your remaining days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep As Is', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyPaused ? AppColors.forestGreen : AppColors.pending,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(action, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      if (isCurrentlyPaused) {
        await ref.read(subscriptionProvider.notifier).resumeSubscription(_sub.id);
        setState(() {
          _sub = _sub.copyWith(status: 'Active');
        });
      } else {
        await ref.read(subscriptionProvider.notifier).pauseSubscription(_sub.id);
        setState(() {
          _sub = _sub.copyWith(status: 'Paused');
        });
      }
      ref.read(orderProvider.notifier).fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Subscription ${isCurrentlyPaused ? "resumed" : "paused"} successfully.'),
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Subscription?',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to cancel this milk subscription? Future morning deliveries will be stopped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep Active', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel Subscription', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(subscriptionProvider.notifier).cancelSubscription(_sub.id);
      setState(() {
        _sub = _sub.copyWith(status: 'Cancelled');
      });
      ref.read(orderProvider.notifier).fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription has been cancelled.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subImg = ApiEndpoints.resolveImageUrl(_sub.productImage ?? '');
    final isPaused = _sub.isPaused;
    final isExpired = _sub.isExpired;
    final isCancelled = _sub.isCancelled;

    Color statusBg = const Color(0xFFEDF7EB);
    Color statusFg = AppColors.forestGreen;
    if (isPaused) {
      statusBg = const Color(0xFFFFF3E0);
      statusFg = AppColors.pending;
    } else if (isExpired) {
      statusBg = const Color(0xFFEEEEEE);
      statusFg = const Color(0xFF757575);
    } else if (isCancelled) {
      statusBg = const Color(0xFFFFEBEE);
      statusFg = AppColors.cancelled;
    }

    final isPaid = _sub.paymentStatus.toLowerCase().contains('paid') ||
        _sub.paymentStatus.toLowerCase().contains('verified');
    final payBg = isPaid ? const Color(0xFFEDF7EB) : const Color(0xFFFFF3E0);
    final payFg = isPaid ? AppColors.forestGreen : const Color(0xFFE65100);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.forestGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Subscription #${_sub.id}',
          style: const TextStyle(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: AppColors.forestGreen, size: 20),
            tooltip: 'Copy ID',
            onPressed: () => _copyToClipboard(_sub.id, 'Subscription ID'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PRODUCT & STATUS BANNER CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5EDE2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: const Color(0xFFFAF7EE),
                          child: subImg.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: subImg,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.local_drink,
                                    color: AppColors.forestGreen,
                                    size: 32,
                                  ),
                                )
                              : const Icon(
                                  Icons.local_drink,
                                  color: AppColors.forestGreen,
                                  size: 32,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sub.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppColors.forestGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_sub.quantity} Litre${_sub.quantity > 1 ? "s" : ""} • ${_sub.frequency}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6E8072),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _sub.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: statusFg,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: payBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _sub.paymentStatus.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: payFg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Plan Price', style: TextStyle(fontSize: 11, color: Color(0xFF6E8072))),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '₹${_sub.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _sub.daysRemaining > 5
                              ? const Color(0xFFE8F5E9)
                              : (_sub.daysRemaining > 0 ? const Color(0xFFFFF3E0) : const Color(0xFFFFEBEE)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _sub.daysRemaining > 0 ? '${_sub.daysRemaining} Days Left' : 'Plan Ended',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _sub.daysRemaining > 5
                                ? const Color(0xFF2E7D32)
                                : (_sub.daysRemaining > 0 ? const Color(0xFFE65100) : const Color(0xFFC62828)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. DELIVERY SCHEDULE & TIME DETAILS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5EDE2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Schedule & Address',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.forestGreen),
                  ),
                  const Divider(height: 20),
                  _buildRow('Preferred Time Slot', _sub.deliverySlot, icon: Icons.access_time),
                  const SizedBox(height: 10),
                  _buildRow('Frequency', _sub.frequency, icon: Icons.repeat),
                  const SizedBox(height: 10),
                  _buildRow('Start Date', _sub.startDate, icon: Icons.play_circle_outline),
                  const SizedBox(height: 10),
                  _buildRow('Expiry Date', _sub.expiryDate ?? '30 Days', icon: Icons.stop_circle_outlined),
                  if (_sub.nextRenewalDate != null && _sub.nextRenewalDate!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildRow('Next Renewal Date', _sub.nextRenewalDate!, icon: Icons.update),
                  ],
                  if (_sub.address.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildRow('Delivery Address', _sub.address, icon: Icons.location_on_outlined),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. PAYMENT & TRANSACTION INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5EDE2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Information',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.forestGreen),
                  ),
                  const Divider(height: 20),
                  _buildRow('Payment Status', _sub.paymentStatus.toUpperCase(), icon: Icons.payment),
                  if (_sub.transactionId != null && _sub.transactionId!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildRow(
                      'UTR Number',
                      _sub.transactionId!,
                      icon: Icons.receipt_outlined,
                      trailingWidget: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              _sub.transactionId!,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _copyToClipboard(_sub.transactionId!, 'UTR Number'),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.copy, size: 14, color: AppColors.forestGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3.5 LIVE 3D DELIVERY TRACKING BUTTON
            if (!isExpired && !isCancelled) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerLiveTrackingScreen(
                          initialOrder: _sub.toOrderModel(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Track Live Delivery in 3D',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],

            // 4. ACTION CONTROLS (Pause/Resume/Cancel)
            if (!isExpired && !isCancelled) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _handleTogglePause,
                      icon: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        size: 18,
                        color: isPaused ? AppColors.forestGreen : AppColors.pending,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isPaused ? 'RESUME DELIVERIES' : 'PAUSE DELIVERIES',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: isPaused ? AppColors.forestGreen : AppColors.pending,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isPaused ? AppColors.forestGreen : AppColors.pending,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _isProcessing ? null : _handleCancelSubscription,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('CANCEL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Support info
            Center(
              child: Text(
                'Need help with your subscription? Reach out to Thulirva Support.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {IconData? icon, Widget? trailingWidget}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.forestGreen),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6E8072),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: trailingWidget ??
              Text(
                value,
                textAlign: TextAlign.end,
                softWrap: true,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
        ),
      ],
    );
  }
}
