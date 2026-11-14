import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/id_formatter.dart';
import '../../data/models/order_model.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/order_provider.dart';
import '../subscriptions/customer_subscription_details_screen.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/thulirva_app_bar.dart';
import 'order_details_screen.dart';
import 'customer_live_tracking_screen.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  final VoidCallback? onShopNow;

  const MyOrdersScreen({super.key, this.onShopNow});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).fetchOrders();
    });
  }

  final List<String> _filters = const [
    'All Orders',
    'Pending',
    'Active',
    'Processing',
    'Preparing',
    'Ready for Pickup',
    'Out for Delivery',
    'Delivered',
    'Cancelled',
  ];

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'delivered':
        return const Color(0xFFE8F5E9);
      case 'out_for_delivery':
      case 'shipped':
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

  Color _getSubscriptionStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFFE8F5E9);
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'paused':
        return const Color(0xFFE0F2FE);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      case 'expired':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFFFFBEB);
    }
  }

  Color _getSubscriptionStatusFgColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF15803D);
      case 'pending':
        return const Color(0xFFB45309);
      case 'paused':
        return const Color(0xFF0284C7);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFB91C1C);
      case 'expired':
        return const Color(0xFF6B7280);
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
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final feed = orderState.filteredFeed;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      appBar: ThulirvaAppBar(
        showBack: Navigator.canPop(context),
        showCart: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title & Subtitle Header
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Column(
                children: const [
                  Text(
                    'My Orders',
                    style: TextStyle(
                      color: AppColors.forestGreen,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Track and manage your orders & subscriptions',
                    style: TextStyle(
                      color: Color(0xFF556B5D),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // 1. Primary 3-Tab Order Type Filter (All Orders | Product Orders | Subscription Orders)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFECE8D9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTypeTab('all', 'All Orders', orderState.allOrdersCount, orderState.typeFilter == 'all'),
                  _buildTypeTab('product', '🛒 Products', orderState.productOrdersCount, orderState.typeFilter == 'product'),
                  _buildTypeTab('subscription', '📅 Subscriptions', orderState.subscriptionOrdersCount, orderState.typeFilter == 'subscription'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 2. Status Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = (orderState.selectedFilter.toLowerCase() == filter.toLowerCase()) ||
                      (orderState.selectedFilter.toLowerCase() == 'all' && filter == 'All Orders');

                  int count = 0;
                  if (filter == 'All Orders') {
                    if (orderState.typeFilter == 'product') {
                      count = orderState.orders.length;
                    } else if (orderState.typeFilter == 'subscription') {
                      count = orderState.subscriptions.length;
                    } else {
                      count = orderState.allOrdersCount;
                    }
                  } else {
                    final fKey = filter.toLowerCase().replaceAll(' ', '_');
                    count = orderState.filteredFeed.where((item) {
                      if (item.type == CustomerOrderItemType.product) {
                        final s = item.productOrder!.orderStatus.toLowerCase().replaceAll(' ', '_');
                        if (fKey == 'ready_for_pickup') return s == 'ready' || s == 'ready_for_pickup';
                        if (fKey == 'out_for_delivery') return s == 'out_for_delivery' || s == 'shipped';
                        return s == fKey;
                      } else {
                        final s = item.subscriptionOrder!.status.toLowerCase().replaceAll(' ', '_');
                        final p = item.subscriptionOrder!.paymentStatus.toLowerCase().replaceAll(' ', '_');
                        if (fKey == 'pending') return s == 'pending' || p == 'pending';
                        if (fKey == 'active') return s == 'active';
                        if (fKey == 'cancelled') return s == 'cancelled';
                        return s == fKey || p == fKey;
                      }
                    }).length;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(orderProvider.notifier).setFilter(filter == 'All Orders' ? 'All' : filter);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.forestGreen : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.forestGreen : const Color(0xFFE5EDE2),
                            width: 1.2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: AppColors.forestGreen.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF4A5D4E),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF0F4EE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : AppColors.forestGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Order List or Empty State
            Expanded(
              child: orderState.isLoading && orderState.allOrdersCount == 0
                  ? const Center(child: LoadingIndicator(message: 'Loading your orders...'))
                  : orderState.errorMessage != null && orderState.allOrdersCount == 0
                      ? _buildErrorState(orderState.errorMessage!)
                      : feed.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: AppColors.forestGreen,
                              onRefresh: () => ref.read(orderProvider.notifier).fetchOrders(),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                itemCount: feed.length,
                                itemBuilder: (context, index) {
                                  final item = feed[index];
                                  if (item.type == CustomerOrderItemType.product) {
                                    return _buildProductOrderCard(item.productOrder!);
                                  } else {
                                    return _buildSubscriptionOrderCard(item.subscriptionOrder!);
                                  }
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String type, String label, int count, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(orderProvider.notifier).setTypeFilter(type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.forestGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.forestGreen.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF4A5D4E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFDFDAC8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54, color: AppColors.cancelled),
            const SizedBox(height: 12),
            const Text(
              'Unable to load orders',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6E8072)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(orderProvider.notifier).fetchOrders(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 240,
              height: 190,
              child: Image.asset(
                'assets/images/orders_empty_box.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.forestGreen),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Orders Found!',
              style: TextStyle(
                color: AppColors.forestGreen,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No orders or subscriptions match this filter.',
              style: TextStyle(
                color: Color(0xFF6E8072),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.onShopNow != null) {
                    widget.onShopNow!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: const Text(
                  'Shop Now →',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Regular Product Order Card
  Widget _buildProductOrderCard(OrderModel order) {
    final statusBg = _getStatusBgColor(order.orderStatus);
    final statusFg = _getStatusFgColor(order.orderStatus);
    final isPickup = order.isPickup || order.deliveryType.toLowerCase() == 'pickup';
    final sStatus = order.orderStatus.toLowerCase().replaceAll(' ', '_');

    String itemsSummary = '';
    if (order.items.isNotEmpty) {
      final names = order.items.map((it) {
        if (it is Map) {
          return it['name'] ?? it['product_name'] ?? 'Item';
        }
        return it.toString();
      }).toList();
      itemsSummary = names.take(2).join(', ');
      if (names.length > 2) {
        itemsSummary += ' +${names.length - 2} more';
      }
    } else {
      itemsSummary = 'Fresh Farm Products';
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order),
          ),
        );
        if (mounted) {
          ref.read(orderProvider.notifier).fetchOrders();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: THU ID (left) + Badges (right) - Wrap-safe
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          order.formattedOrderId,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
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
                        child: const Padding(
                          padding: EdgeInsets.all(3.0),
                          child: Icon(Icons.copy, size: 13.5, color: Color(0xFF6E8072)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Product Order Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shopping_bag_outlined, size: 10.5, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 3),
                          Text(
                            'PRODUCT',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Order Type and Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPickup ? const Color(0xFFEFF6FF) : const Color(0xFFEDF7EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPickup ? Icons.storefront : Icons.local_shipping_outlined,
                        size: 11.5,
                        color: isPickup ? const Color(0xFF2563EB) : AppColors.forestGreen,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isPickup ? 'Store Pickup' : 'Home Delivery',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isPickup ? const Color(0xFF2563EB) : AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.createdAt.isNotEmpty ? order.createdAt.split('T').first : '',
                    style: const TextStyle(
                      color: Color(0xFF6E8072),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Items Summary
            Text(
              '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}: $itemsSummary',
              style: const TextStyle(
                color: Color(0xFF4A5D4E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Total Amount & View Details
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.paymentStatus.toLowerCase() == 'verified' || order.paymentStatus.toLowerCase() == 'paid'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: order.paymentStatus.toLowerCase() == 'verified' || order.paymentStatus.toLowerCase() == 'paid'
                              ? const Color(0xFF15803D)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPickup && (sStatus == 'out_for_delivery' || sStatus == 'in_transit' || sStatus == 'shipped' || sStatus == 'picked_up')) ...[
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerLiveTrackingScreen(initialOrder: order),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.navigation_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Live Track',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.chevron_right, size: 15, color: AppColors.forestGreen),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Distinct Subscription Order Card
  Widget _buildSubscriptionOrderCard(SubscriptionModel sub) {
    final subIdFormatted = IdFormatter.formatSubscriptionId(sub.id);
    final statusBg = _getSubscriptionStatusBgColor(sub.status);
    final statusFg = _getSubscriptionStatusFgColor(sub.status);

    final paymentVerified = sub.paymentStatus.toLowerCase() == 'verified' || sub.paymentStatus.toLowerCase() == 'paid';
    final paymentRejected = sub.paymentStatus.toLowerCase() == 'rejected';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerSubscriptionDetailsScreen(subscription: sub),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD4E6D2), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Subscription ID (left) + Badges (right) - Wrap-safe
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          subIdFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            color: AppColors.forestGreen,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => IdFormatter.copyToClipboard(context, subIdFormatted, label: 'Subscription ID'),
                        child: const Padding(
                          padding: EdgeInsets.all(3.0),
                          child: Icon(Icons.copy, size: 13.5, color: Color(0xFF6E8072)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Distinct SUBSCRIPTION Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDBA74), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.calendar_month, size: 10.5, color: Color(0xFFC2410C)),
                          SizedBox(width: 3),
                          Text(
                            'SUBSCRIPTION',
                            style: TextStyle(
                              color: Color(0xFFC2410C),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge (Active, Pending, etc.)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sub.status.toUpperCase(),
                        style: TextStyle(
                          color: statusFg,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Plan Name & Frequency / Slot
            Text(
              sub.productName,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2E22),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 2,
              children: [
                Text(
                  '${sub.frequency} • ${sub.timePeriod}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF556B5D),
                  ),
                ),
                if (sub.deliverySlot.isNotEmpty) ...[
                  const Text('•', style: TextStyle(color: Color(0xFF8BA090), fontSize: 11)),
                  const Icon(Icons.access_time, size: 11.5, color: Color(0xFF556B5D)),
                  Text(
                    sub.deliverySlot,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF556B5D),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Customer Name
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13.5, color: Color(0xFF6E8072)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sub.customerName,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334438),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dates: Booked, Starts, Expires with responsive 3-column layout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4EDE2)),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildDateCol('Booked', sub.purchaseDate.split('T').first)),
                  Container(width: 1, height: 24, color: const Color(0xFFE0E8DE), margin: const EdgeInsets.symmetric(horizontal: 4)),
                  Expanded(child: _buildDateCol('Starts', sub.startDate.split('T').first)),
                  Container(width: 1, height: 24, color: const Color(0xFFE0E8DE), margin: const EdgeInsets.symmetric(horizontal: 4)),
                  Expanded(child: _buildDateCol('Expires', sub.expiryDate != null && sub.expiryDate!.isNotEmpty ? sub.expiryDate!.split('T').first : 'Ongoing')),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Price, Payment Verification Status, View Details
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${sub.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment Verification Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: paymentVerified
                            ? const Color(0xFFE8F5E9)
                            : (paymentRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFFF3E0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        paymentVerified
                            ? 'VERIFIED'
                            : (paymentRejected ? 'REJECTED' : 'PENDING VERIFICATION'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: paymentVerified
                              ? const Color(0xFF15803D)
                              : (paymentRejected ? const Color(0xFFB91C1C) : const Color(0xFFD97706)),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.schedule_rounded, size: 12, color: AppColors.forestGreen),
                          SizedBox(width: 4),
                          Text(
                            'Daily 6:00 - 7:00 AM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.chevron_right, size: 15, color: AppColors.forestGreen),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7A8D7E),
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF223528),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
