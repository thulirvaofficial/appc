import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

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
    final statusColor = _getStatusColor(order.orderStatus);

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text('Order #${order.id}', style: AppTypography.displaySmall.copyWith(fontSize: 18)),
        backgroundColor: Colors.white,
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
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      order.orderStatus.toLowerCase() == 'delivered'
                          ? Icons.check_circle_outline
                          : (order.orderStatus.toLowerCase() == 'cancelled'
                              ? Icons.cancel_outlined
                              : Icons.local_shipping_outlined),
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${order.orderStatus.toUpperCase()}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
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

            // Delivery Address Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: AppColors.forestGreen, size: 18),
                      SizedBox(width: 6),
                      Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${order.address}, ${order.city} - ${order.pincode}', style: AppTypography.bodySmall.copyWith(color: AppColors.textMid)),
                  Text('📞 ${order.customerPhone}', style: AppTypography.bodySmall.copyWith(color: AppColors.textLight)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items in Order (${order.items.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
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
                            Text('• $name x $qty', style: AppTypography.bodyMedium),
                            Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount Paid', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('₹${order.total.toStringAsFixed(0)}', style: AppTypography.price.copyWith(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Verification Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Details', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 8),
                  Text('Method: ${order.paymentMethod}', style: AppTypography.bodySmall),
                  if (order.transactionId != null && order.transactionId!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('UTR / Transaction ID: ${order.transactionId}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.forestGreen)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

