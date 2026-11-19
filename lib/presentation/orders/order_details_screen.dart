import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/id_formatter.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import 'customer_live_tracking_screen.dart';
import '../widgets/thulirva_delivery_proof_widget.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  late OrderModel _currentOrder;
  int _selectedRating = 5;
  final Set<String> _selectedTags = {'⚡ Super Fast', '🥛 Fresh & Cold'};
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmittingRating = false;

  final List<String> _ratingTagOptions = [
    '⚡ Super Fast',
    '🥛 Fresh & Cold',
    '😊 Polite Partner',
    '📦 Clean Packaging',
    '📍 Exact Doorstep',
  ];

  Timer? _statusPollingTimer;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    if (_currentOrder.orderStatus.toLowerCase() == 'delivered') {
      _loadDeliveryDetails();
    }
    _startLiveStatusPolling();
  }

  void _startLiveStatusPolling() {
    // 5-second polling fallback to synchronize status with centralized backend
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final orderId = _currentOrder.id.toString();
        final fresh = await ref.read(orderProvider.notifier).fetchOrderDetails(orderId);
        if (fresh != null && mounted) {
          final oldStatus = _currentOrder.orderStatus.toLowerCase();
          final newStatus = fresh.orderStatus.toLowerCase();
          if (oldStatus != newStatus || fresh.deliveryProofUrl != _currentOrder.deliveryProofUrl) {
            setState(() {
              _currentOrder = fresh;
            });
            if (newStatus == 'delivered' && (_currentOrder.deliveryProofUrl == null || _currentOrder.deliveryProofUrl!.isEmpty)) {
              _loadDeliveryDetails();
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _loadDeliveryDetails() async {
    try {
      final data = await ref.read(orderProvider.notifier).fetchDeliveryProofDetails(_currentOrder.id.toString());
      if (data != null && mounted) {
        setState(() {
          _currentOrder = _currentOrder.copyWith(
            deliveryProofUrl: data['delivery_proof_url'] ?? data['proof_url'],
            deliveredAt: data['delivered_at'] ?? data['delivery_proof_timestamp'],
          );
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'delivered':
        return const Color(0xFFE8F5E9);
      case 'out_for_delivery':
      case 'shipped':
      case 'in_transit':
      case 'pickup_confirmed':
        return const Color(0xFFE0F2FE);
      case 'ready_for_pickup':
      case 'ready':
        return const Color(0xFFEFF6FF);
      case 'preparing':
      case 'processing':
        return const Color(0xFFFEF3C7);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFFFFBEB);
    }
  }

  Color _getStatusFgColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'delivered':
        return const Color(0xFF15803D);
      case 'out_for_delivery':
      case 'shipped':
      case 'in_transit':
      case 'pickup_confirmed':
        return const Color(0xFF0284C7);
      case 'ready_for_pickup':
      case 'ready':
        return const Color(0xFF2563EB);
      case 'preparing':
      case 'processing':
        return const Color(0xFFB45309);
      case 'cancelled':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFD97706);
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'preparing':
        return 'Preparing';
      case 'ready':
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'shipped':
      case 'out_for_delivery':
      case 'in_transit':
      case 'picked_up':
      case 'pickup_confirmed':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _callPartner(String? phone) async {
    final raw = phone ?? '7904880944';
    final clean = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot dial $raw on this device')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone dialer for $raw')),
        );
      }
    }
  }

  void _openLiveTrackingMap(BuildContext context, OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerLiveTrackingScreen(initialOrder: order),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (_isSubmittingRating) return;
    setState(() => _isSubmittingRating = true);

    try {
      final success = await ref.read(orderProvider.notifier).rateOrder(
            orderId: _currentOrder.id.toString(),
            rating: _selectedRating,
            feedback: _feedbackController.text.trim(),
            tags: _selectedTags.toList(),
          );

      if (success) {
        setState(() {
          _currentOrder = _currentOrder.copyWith(
            rating: _selectedRating.toDouble(),
            feedback: _feedbackController.text.trim(),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.forestGreen,
              content: Row(
                children: [
                  Icon(Icons.star, color: Color(0xFFFBBF24)),
                  SizedBox(width: 10),
                  Text('Thank you! Your rating has been recorded.', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit rating. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
      }
    }
  }

  void _showAssistanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Order Assistance', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestGreen)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need help with order ${_currentOrder.formattedOrderId}?', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text('Our farm dispatch team is available from 6:00 AM to 9:00 PM.'),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone, color: AppColors.forestGreen),
                title: const Text('+91 79048 80944', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                trailing: const Icon(Icons.copy, size: 16),
                onTap: () => IdFormatter.copyToClipboard(context, '+917904880944', label: 'Support Phone'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email, color: AppColors.forestGreen),
                title: const Text('support@thulirva.com', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                trailing: const Icon(Icons.copy, size: 16),
                onTap: () => IdFormatter.copyToClipboard(context, 'support@thulirva.com', label: 'Support Email'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if provider has newer instance of this order
    final liveOrders = ref.watch(orderProvider).orders;
    final found = liveOrders.where((o) => o.id.toString() == _currentOrder.id.toString() || o.orderNumber == _currentOrder.orderNumber);
    final order = found.isNotEmpty ? found.first : _currentOrder;

    final statusBg = _getStatusBgColor(order.orderStatus);
    final statusFg = _getStatusFgColor(order.orderStatus);
    final isPickup = order.isPickup || order.deliveryType.toLowerCase() == 'pickup';
    final isDelivered = order.orderStatus.toLowerCase() == 'delivered';
    final isCancelled = order.orderStatus.toLowerCase() == 'cancelled';
    final isTrackable = !isPickup && !isDelivered && !isCancelled;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                order.formattedOrderId,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16.5,
                  color: AppColors.forestGreen,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => IdFormatter.copyToClipboard(context, order.formattedOrderId, label: 'Order ID'),
              child: const Icon(Icons.copy, size: 15, color: AppColors.forestGreen),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.forestGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.forestGreen),
            onPressed: () => _showAssistanceDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: const Color(0xFFE5EDE2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      order.orderStatus.toLowerCase() == 'delivered'
                          ? Icons.check_circle_outline
                          : (order.orderStatus.toLowerCase() == 'cancelled'
                              ? Icons.cancel_outlined
                              : (isPickup ? Icons.storefront : Icons.local_shipping_outlined)),
                      color: statusFg,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatStatusLabel(order.orderStatus),
                                style: TextStyle(
                                  color: statusFg,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPickup ? const Color(0xFFEFF6FF) : const Color(0xFFEDF7EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isPickup ? 'Store Pickup' : 'Home Delivery',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isPickup ? const Color(0xFF2563EB) : AppColors.forestGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ordered on ${order.createdAt}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // DELIVERY SCHEDULE TIMING CARD (Matching Subscription Card Style)
            _buildDeliveryTimingScheduleCard(order),
            const SizedBox(height: 16),

            // Order Tracking Timeline
            _buildTimelineCard(order.orderStatus, isPickup),
            const SizedBox(height: 16),

            // LIVE TRACKING & PARTNER CARD (When Out for Delivery or Active)
            if (isTrackable && !isPickup) ...[
              _buildLiveTrackingBanner(order),
              const SizedBox(height: 16),
            ],

            // DELIVERY PROOF & VERIFICATION (When Delivered)
            if (isDelivered) ...[
              _buildCustomerDeliveryProofCard(order),
              const SizedBox(height: 16),
            ],

            // PARTNER RATING CARD (When Delivered)
            if (isDelivered) ...[
              _buildPartnerRatingCard(order),
              const SizedBox(height: 16),
            ],

            // Delivery Address or Store Pickup Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: const Color(0xFFE5EDE2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isPickup ? Icons.storefront : Icons.location_on, color: AppColors.forestGreen, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        isPickup ? 'Farm Store Pickup Details' : 'Delivery Address',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.forestGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  if (isPickup) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Store Location: ${order.pickupLocationName ?? 'Thulirva Farm Store, Chennai'}',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A5D4E)),
                    ),
                    if (order.pickupSlot != null && order.pickupSlot!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Pickup Time Slot: ${order.pickupSlot}',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 4),
                    Text('${order.address}, ${order.city} - ${order.pincode}', style: AppTypography.bodySmall.copyWith(color: AppColors.textMid)),
                  ],
                  const SizedBox(height: 6),
                  Text('📞 Phone: ${order.customerPhone}', style: AppTypography.bodySmall.copyWith(color: AppColors.textLight)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ordered Items List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: const Color(0xFFE5EDE2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items in Order (${order.items.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.forestGreen)),
                  const SizedBox(height: 12),
                  if (order.items.isEmpty)
                    const Text('Farm fresh dairy products pack', style: TextStyle(color: AppColors.textLight))
                  else
                    ...order.items.map((i) {
                      final name = (i is Map) ? (i['name'] ?? i['product_name'] ?? 'Dairy Product') : i.toString();
                      final qty = (i is Map) ? (i['quantity'] ?? 1) : 1;
                      final price = (i is Map) ? (i['price'] ?? 0) : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('• $name x $qty', style: AppTypography.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    }),
                  const Divider(height: 20),

                  // Itemized Price Breakdown
                  _buildPriceRow('Subtotal', '₹${order.subtotal > 0 ? order.subtotal.toStringAsFixed(0) : order.total.toStringAsFixed(0)}'),
                  const SizedBox(height: 4),
                  _buildPriceRow(
                    isPickup ? 'Store Pickup Fee' : 'Delivery Charge',
                    isPickup ? 'FREE' : (order.deliveryCharge > 0 ? '₹${order.deliveryCharge.toStringAsFixed(0)}' : 'FREE'),
                    isHighlight: isPickup || order.deliveryCharge == 0,
                  ),
                  if (order.discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    _buildPriceRow('Discount', '-₹${order.discountAmount.toStringAsFixed(0)}', isNegative: true),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.forestGreen)),
                      Text('₹${order.total.toStringAsFixed(0)}', style: AppTypography.price.copyWith(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: const Color(0xFFE5EDE2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.forestGreen)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: order.paymentStatus.toLowerCase() == 'verified' || order.paymentStatus.toLowerCase() == 'paid'
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.paymentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: order.paymentStatus.toLowerCase() == 'verified' || order.paymentStatus.toLowerCase() == 'paid'
                                ? const Color(0xFF15803D)
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Method: ${order.paymentMethod}', style: AppTypography.bodySmall),
                  if (order.transactionId != null && order.transactionId!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('UTR: ', style: TextStyle(fontSize: 12, color: Color(0xFF6E8072))),
                        Text(
                          order.transactionId!,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.forestGreen),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => IdFormatter.copyToClipboard(context, order.transactionId!, label: 'UTR'),
                          child: const Icon(Icons.copy, size: 13, color: Color(0xFF6E8072)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Order Assistance Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showAssistanceDialog(context),
                icon: const Icon(Icons.support_agent, color: AppColors.forestGreen),
                label: const Text(
                  'Need Help With This Order?',
                  style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.forestGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTrackingBanner(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner Top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F9FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0284C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Order Is On The Way!',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0369A1)),
                      ),
                      Text(
                        'Chilled farm dairy en route to your location',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Partner Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFE8F5E9),
                      backgroundImage: (order.partnerPhoto != null && order.partnerPhoto!.isNotEmpty)
                          ? NetworkImage(ApiEndpoints.resolveImageUrl(order.partnerPhoto!))
                          : null,
                      child: (order.partnerPhoto == null || order.partnerPhoto!.isEmpty)
                          ? const Icon(Icons.person, color: AppColors.forestGreen, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.partnerName ?? 'Finding a delivery partner...',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF1E293B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${order.partnerRating?.toStringAsFixed(1) ?? '5.0'} • ${order.partnerVehicle ?? 'Delivery Partner'}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFE8F5E9)),
                      icon: const Icon(Icons.phone, color: AppColors.forestGreen, size: 20),
                      onPressed: () => _callPartner(order.partnerPhone),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Track on Map Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _openLiveTrackingMap(context, order),
                    icon: const Icon(Icons.map_outlined, color: Colors.white, size: 18),
                    label: const Text(
                      'Track Live On Map',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportIssueModal() {
    String selectedIssue = 'Items missing or damaged';
    final notesController = TextEditingController();
    bool isSubmitting = false;

    final issues = [
      'Items missing or damaged',
      'Package left at wrong doorstep',
      'Seal / packaging broken',
      'Delivery quality problem',
      'Other delivery issue',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(Icons.report_problem_outlined, color: Color(0xFFD97706), size: 22),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Report Delivery Issue',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'We take doorstep delivery quality seriously. Please let us know what happened.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMid),
                ),
                const SizedBox(height: 16),
                ...issues.map((iss) {
                  final isSelected = selectedIssue == iss;
                  return InkWell(
                    onTap: () => setModalState(() => selectedIssue = iss),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 18,
                            color: isSelected ? AppColors.forestGreen : AppColors.textLight,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              iss,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.forestGreen : AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional details or notes...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
                    filled: true,
                    fillColor: const Color(0xFFFAF7F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5EDE2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5EDE2)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      setModalState(() => isSubmitting = true);
                      final ok = await ref.read(orderProvider.notifier).reportOrderIssue(
                        orderId: _currentOrder.id.toString(),
                        issueType: selectedIssue,
                        notes: notesController.text.trim(),
                      );
                      if (modalCtx.mounted) Navigator.pop(modalCtx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? '✓ Issue reported. Our support team is reviewing your report.'
                                : 'Failed to submit report. Please try again or call support.'),
                            backgroundColor: ok ? AppColors.forestGreen : Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDeliveryProofCard(OrderModel order) {
    final hasProof = (order.deliveryProofUrl ?? '').isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Doorstep Delivery Verified',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF15803D)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DELIVERED',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (hasProof) ...[
            ThulirvaDeliveryProofWidget(
              proofSource: order.deliveryProofUrl,
              height: 170,
              enableZoom: true,
              title: 'Doorstep Delivery Proof — ${order.formattedOrderId}',
            ),
            const SizedBox(height: 10),
          ],
          if (order.deliveredAt != null && order.deliveredAt!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMid),
                const SizedBox(width: 6),
                Text('Handover: ${order.deliveredAt}', style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showReportIssueModal,
              icon: const Icon(Icons.flag_outlined, size: 15, color: Color(0xFFD97706)),
              label: const Text('Report Delivery Issue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFDE68A)),
                backgroundColor: const Color(0xFFFFFBEB),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerRatingCard(OrderModel order) {
    final hasRated = (order.rating != null && order.rating! > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFFE5EDE2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Rate Your Delivery Experience',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.forestGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasRated) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < order.rating!.toInt() ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 22,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${order.rating!.toInt()} / 5 Stars',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1F2937)),
                      ),
                    ],
                  ),
                  if (order.feedback != null && order.feedback!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"${order.feedback}"',
                      style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Color(0xFF4B5563)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  const Text(
                    'Thank you for helping us keep Thulirva farm deliveries exceptional!',
                    style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Star selector
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      starNum <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    onPressed: () {
                      setState(() => _selectedRating = starNum);
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),

            // Experience Tag Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _ratingTagOptions.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE8F5E9),
                  checkmarkColor: AppColors.forestGreen,
                  labelStyle: TextStyle(color: isSelected ? AppColors.forestGreen : const Color(0xFF4B5563)),
                  backgroundColor: const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: isSelected ? AppColors.forestGreen : Colors.transparent),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Feedback Text Field
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Share a quick compliment or suggestion for the partner...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.forestGreen),
                ),
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: _isSubmittingRating ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmittingRating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Submit Delivery Rating',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isHighlight = false, bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6E8072))),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isNegative
                ? const Color(0xFF15803D)
                : (isHighlight ? const Color(0xFF15803D) : const Color(0xFF2C3E30)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineCard(String status, bool isPickup) {
    final s = status.toLowerCase().replaceAll(' ', '_');
    int currentStep = 0;
    if (s == 'processing' || s == 'preparing') currentStep = 1;
    if (s == 'ready' || s == 'ready_for_pickup') currentStep = 2;
    if (s == 'shipped' || s == 'out_for_delivery' || s == 'in_transit' || s == 'picked_up' || s == 'pickup_confirmed') currentStep = 2;
    if (s == 'delivered' || s == 'collected') currentStep = 3;

    final steps = isPickup
        ? ['Placed', 'Preparing', 'Ready at Store', 'Collected']
        : ['Placed', 'Preparing', 'Out for Delivery', 'Delivered'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFFE5EDE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Timeline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.forestGreen)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length, (idx) {
              final isPassed = idx <= currentStep;
              final isCurrent = idx == currentStep;
              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (idx > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isPassed ? AppColors.forestGreen : const Color(0xFFE5EDE2),
                            ),
                          ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isPassed ? AppColors.forestGreen : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPassed ? AppColors.forestGreen : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isPassed
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : Container(),
                          ),
                        ),
                        if (idx < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: idx < currentStep ? AppColors.forestGreen : const Color(0xFFE5EDE2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[idx],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                        color: isCurrent ? AppColors.forestGreen : const Color(0xFF6E8072),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimingScheduleCard(OrderModel order) {
    final isPickup = order.isPickup || order.deliveryType.toLowerCase() == 'pickup';
    final effective = (order.deliverySlot != null && order.deliverySlot!.trim().isNotEmpty)
        ? order.deliverySlot!.trim()
        : ((order.pickupSlot != null && order.pickupSlot!.trim().isNotEmpty)
            ? order.pickupSlot!.trim()
            : '');

    final hasSlot = effective.isNotEmpty;

    String slotName = isPickup ? 'Farm Store Pickup Window' : 'Scheduled Delivery Window';
    String timeRange = effective;

    if (effective.contains('(') && effective.contains(')')) {
      final parts = effective.split('(');
      slotName = parts[0].trim();
      timeRange = parts[1].replaceAll(')', '').trim();
    } else if (effective.toLowerCase().contains('morning')) {
      slotName = 'Morning Delivery';
      if (!timeRange.contains(':')) timeRange = '6:00 AM – 7:00 AM';
    } else if (effective.toLowerCase().contains('evening')) {
      slotName = 'Evening Delivery';
      if (!timeRange.contains(':')) timeRange = '6:00 PM – 7:00 PM';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasSlot ? const Color(0xFFE8F5E9) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSlot ? const Color(0xFFC8E6C9) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasSlot ? const Color(0xFFC8E6C9).withOpacity(0.4) : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSlot ? Icons.access_time_filled_rounded : Icons.schedule_rounded,
              size: 22,
              color: hasSlot ? const Color(0xFF1B5E20) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slotName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: hasSlot ? const Color(0xFF1B5E20) : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasSlot ? timeRange : 'Delivery time not specified',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: hasSlot ? FontWeight.w700 : FontWeight.w500,
                    color: hasSlot ? const Color(0xFF2E7D32) : const Color(0xFF6B7280),
                    fontStyle: hasSlot ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
