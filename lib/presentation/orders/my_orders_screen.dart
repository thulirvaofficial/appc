import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/thulirva_app_bar.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  final VoidCallback? onShopNow;

  const MyOrdersScreen({super.key, this.onShopNow});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final List<_OrderFilter> _filters = const [
    _OrderFilter(label: 'All', icon: Icons.inventory_2_outlined),
    _OrderFilter(label: 'Processing', icon: Icons.access_time),
    _OrderFilter(label: 'Shipped', icon: Icons.local_shipping_outlined),
    _OrderFilter(label: 'Delivered', icon: Icons.check_circle_outline),
    _OrderFilter(label: 'Store Pickup', icon: Icons.storefront_outlined),
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.delivered;
      case 'shipped':
        return AppColors.shipped;
      case 'cancelled':
        return AppColors.cancelled;
      default:
        return AppColors.processing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final orders = orderState.filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: ThulirvaAppBar(
        showBack: Navigator.canPop(context),
        showCart: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title & Subtitle Header
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
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
                    'Track and manage your orders',
                    style: TextStyle(
                      color: Color(0xFF556B5D),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Filter Pills Row (All, Processing, Shipped, Delivered)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected =
                      orderState.selectedFilter.toLowerCase() == filter.label.toLowerCase();

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(orderProvider.notifier).setFilter(filter.label);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.forestGreen : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? AppColors.forestGreen : const Color(0xFFDCE8D8),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              filter.icon,
                              size: 15,
                              color: isSelected ? Colors.white : AppColors.forestGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              filter.label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textDark,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
            const SizedBox(height: 16),

            // Content Area (Orders List or Empty State)
            Expanded(
              child: orderState.isLoading && orders.isEmpty
                  ? const LoadingIndicator(message: 'Loading orders...')
                  : orders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.forestGreen,
                          onRefresh: () => ref.read(orderProvider.notifier).fetchOrders(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderCard(orders[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Reference-faithful Empty State
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustrated Box with milk bottle, curd bowl, and leaves
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

            // Headline
            const Text(
              'No Orders Yet!',
              style: TextStyle(
                color: AppColors.forestGreen,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            const Text(
              'You haven\'t placed any orders yet.',
              style: TextStyle(
                color: Color(0xFF6E8072),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Shop Now -> Pill Button
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

  // Dynamic Order Card
  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.orderStatus);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.forestGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.orderStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'} • ${order.createdAt.isNotEmpty ? order.createdAt.split('T').first : ''}',
              style: const TextStyle(
                color: Color(0xFF6E8072),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '₹' + order.total.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.forestGreen),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderFilter {
  final String label;
  final IconData icon;

  const _OrderFilter({required this.label, required this.icon});
}
