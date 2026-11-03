import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_indicator.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final List<String> _filters = ['All', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

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
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.forestGreen,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Tabs (Mockup Screen 11: All, Processing, Shipped, Delivered)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = orderState.selectedFilter.toLowerCase() == filter.toLowerCase();

                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(orderProvider.notifier).setFilter(filter);
                    },
                    selectedColor: AppColors.forestGreen,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.forestGreen : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: orderState.isLoading && orders.isEmpty
                ? const LoadingIndicator(message: 'Loading orders...')
                : orders.isEmpty
                    ? EmptyStateView(
                        title: 'No Orders Found',
                        message: 'You have no ${orderState.selectedFilter.toLowerCase()} orders yet.',
                        emoji: '📦',
                        buttonText: 'Refresh',
                        onButtonPressed: () => ref.read(orderProvider.notifier).fetchOrders(),
                      )
                    : RefreshIndicator(
                        color: AppColors.forestGreen,
                        onRefresh: () => ref.read(orderProvider.notifier).fetchOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(orders[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.lightCream,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/products/fresh_cow_milk.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Text('🥛', style: TextStyle(fontSize: 28))),
              ),
            ),
            const SizedBox(width: 14),

            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.forestGreen,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.orderStatus.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.items.length} item${order.items.length > 1 ? 's' : ''} • ₹${order.total.toStringAsFixed(0)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.createdAt,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

