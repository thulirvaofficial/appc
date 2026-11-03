import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/order_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../orders/order_details_screen.dart';
import '../profile/offers_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_indicator.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_status':
        return Icons.local_shipping_outlined;
      case 'subscription_expiry':
        return Icons.event_repeat_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      case 'new_product':
        return Icons.eco_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_status':
        return AppColors.forestGreen;
      case 'subscription_expiry':
        return AppColors.processing;
      case 'promotion':
        return Colors.purple.shade700;
      case 'new_product':
        return AppColors.naturalGreen;
      default:
        return AppColors.forestGreen;
    }
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, NotificationModel notif) {
    ref.read(notificationProvider.notifier).markAsRead(notif.id);

    // Rule 18: Notification Deep Links
    // When customer taps an order notification -> Order Details
    // When customer taps subscription expiry -> Subscription Details
    if (notif.type == 'order_status') {
      final orderId = notif.data?['order_id'] ?? 'THU258963';
      final orders = ref.read(orderProvider).orders;
      final matched = orders.firstWhere(
        (o) => o.id.toString() == orderId.toString(),
        orElse: () => OrderModel(
          id: orderId,
          customerName: 'Valued Customer',
          customerPhone: '9876543210',
          address: 'Doorstep Delivery',
          city: 'Chennai',
          pincode: '600078',
          items: const [],
          total: 398,
          orderStatus: 'dispatched',
          createdAt: notif.createdAt,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: matched)),
      );
    } else if (notif.type == 'subscription_expiry') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
      );
    } else if (notif.type == 'promotion') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OffersScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final notifications = notifState.notifications;

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
          child: notifState.isLoading && notifications.isEmpty
              ? const LoadingIndicator(message: 'Loading notifications...')
              : notifications.isEmpty
                  ? const EmptyStateView(
                      title: 'No Notifications Yet',
                      message: 'We will notify you about farm orders, delivery schedules, and subscription reminders.',
                      emoji: '🔔',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final icon = _getNotificationIcon(notif.type);
                        final color = _getNotificationColor(notif.type);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: notif.isRead ? Colors.white : AppColors.paleGreen.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            border: Border.all(
                              color: notif.isRead ? AppColors.border : AppColors.softGreen,
                              width: notif.isRead ? 1 : 1.5,
                            ),
                          ),
                          child: ListTile(
                            onTap: () => _handleNotificationTap(context, ref, notif),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                      fontSize: 13.5,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                if (!notif.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.naturalGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                notif.message,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMid,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

