import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../orders/my_orders_screen.dart';
import '../orders/order_details_screen.dart';
import '../profile/offers_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../widgets/thulirva_app_bar.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';

  final List<_NotifFilter> _filters = const [
    _NotifFilter(label: 'All', icon: Icons.notifications_none),
    _NotifFilter(label: 'Orders', icon: Icons.inventory_2_outlined),
    _NotifFilter(label: 'Subscription', icon: Icons.calendar_today_outlined),
    _NotifFilter(label: 'Offers', icon: Icons.local_offer_outlined),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  void _handleDeepLink(_VisualNotif notif) {
    ref.read(notificationProvider.notifier).markAsRead(notif.id);

    final cat = notif.category.toLowerCase();
    if (cat.contains('order')) {
      final orders = ref.read(orderProvider).orders;
      if (orders.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: orders.first)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
        );
      }
    } else if (cat.contains('sub')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
      );
    } else if (cat.contains('offer')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OffersScreen()),
      );
    }
  }

  _VisualNotif _mapModelToVisual(NotificationModel model) {
    final tLower = model.type.toLowerCase();
    final titleLower = model.title.toLowerCase();

    String category = 'All';
    IconData icon = Icons.notifications_active_outlined;
    Color iconBg = const Color(0xFFDCEFD7);
    Color iconColor = AppColors.forestGreen;
    Color cardBg = model.isRead ? Colors.white : const Color(0xFFEBF7EA);

    if (tLower.contains('order') || titleLower.contains('order') || titleLower.contains('delivery')) {
      category = 'Orders';
      icon = Icons.local_shipping_outlined;
      iconBg = const Color(0xFFDCEFD7);
      iconColor = AppColors.forestGreen;
    } else if (tLower.contains('sub') || titleLower.contains('subscription') || titleLower.contains('renew')) {
      category = 'Subscription';
      icon = Icons.calendar_month_outlined;
      iconBg = const Color(0xFFE8F5E9);
      iconColor = AppColors.forestGreen;
    } else if (tLower.contains('offer') || tLower.contains('promo') || titleLower.contains('offer') || titleLower.contains('discount')) {
      category = 'Offers';
      icon = Icons.percent;
      iconBg = const Color(0xFFFDF0D5);
      iconColor = const Color(0xFFB37418);
    } else {
      category = 'All';
      icon = Icons.campaign_outlined;
      iconBg = const Color(0xFFE3F2FD);
      iconColor = const Color(0xFF1976D2);
    }

    String section = 'Earlier';
    String timeAgo = 'Recently';
    try {
      final dt = DateTime.parse(model.createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        section = 'Today';
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes < 1 ? 1 : diff.inMinutes} min ago';
        } else {
          timeAgo = '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
        }
      } else if (diff.inDays == 1) {
        section = 'Yesterday';
        timeAgo = 'Yesterday';
      } else if (diff.inDays < 7) {
        section = 'This Week';
        timeAgo = '${diff.inDays} days ago';
      }
    } catch (_) {}

    return _VisualNotif(
      id: model.id,
      section: section,
      title: model.title,
      message: model.message,
      time: timeAgo,
      category: category,
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      cardBg: cardBg,
      isUnread: !model.isRead,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationProvider);
    final rawNotifications = notifState.notifications;

    // Convert raw models to visual models
    final List<_VisualNotif> allVisuals = rawNotifications.map(_mapModelToVisual).toList();

    // If backend has no notifications yet, generate from user's live orders
    if (allVisuals.isEmpty) {
      final orders = ref.watch(orderProvider).orders;
      for (final o in orders.take(3)) {
        allVisuals.add(
          _VisualNotif(
            id: 'ord_${o.id}',
            section: 'Today',
            title: 'Order #${o.id} — ${o.orderStatus.toUpperCase()}',
            message: 'Your order for ₹${o.total.toStringAsFixed(0)} is currently ${o.orderStatus}.',
            time: 'Live',
            category: 'Orders',
            icon: Icons.inventory_2_outlined,
            iconBg: const Color(0xFFDCEFD7),
            iconColor: AppColors.forestGreen,
            cardBg: const Color(0xFFEBF7EA),
            isUnread: o.orderStatus.toLowerCase() == 'pending',
          ),
        );
      }
    }

    final filtered = allVisuals.where((n) {
      if (_selectedFilter == 'All') return true;
      return n.category.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    // Group filtered notifications by section preserving order
    final Map<String, List<_VisualNotif>> grouped = {};
    for (final n in filtered) {
      grouped.putIfAbsent(n.section, () => []).add(n);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: ThulirvaAppBar(
        showBack: true,
        showNotifications: false,
        showCart: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () async {
            await ref.read(notificationProvider.notifier).fetchNotifications();
            await ref.read(orderProvider.notifier).fetchOrders();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title & Subtitle
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Center(
                    child: Column(
                      children: const [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: AppColors.forestGreen,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Stay updated with your orders, subscription\nand offers',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF556B5D),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter Pills Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter.label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter.label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.forestGreen : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? AppColors.forestGreen : const Color(0xFFDCE8D8),
                                width: 1.2,
                              ),
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
                const SizedBox(height: 14),

                if (notifState.isLoading && allVisuals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
                  )
                else if (allVisuals.isEmpty)
                  // "You're All Caught Up!" Empty State
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEDF7EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.notifications_none, size: 36, color: AppColors.forestGreen),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "You're All Caught Up!",
                            style: TextStyle(
                              color: AppColors.forestGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "No new notifications right now. We'll alert you when your order status updates or new farm fresh items arrive.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF6E8072), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Grouped Notification Sections
                  ...grouped.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppColors.forestGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ...entry.value.map((notif) => _buildNotificationCard(notif)),
                        ],
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(_VisualNotif notif) {
    return GestureDetector(
      onTap: () => _handleDeepLink(notif),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: notif.isUnread ? const Color(0xFFC8E6C9) : const Color(0xFFE5EDE2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: notif.iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(notif.icon, color: notif.iconColor, size: 22),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: const TextStyle(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            notif.time,
                            style: const TextStyle(
                              color: Color(0xFF6E8072),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (notif.isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      color: Color(0xFF4A5D4E),
                      fontSize: 12,
                      height: 1.3,
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

class _NotifFilter {
  final String label;
  final IconData icon;

  const _NotifFilter({required this.label, required this.icon});
}

class _VisualNotif {
  final String id;
  final String section;
  final String title;
  final String message;
  final String time;
  final String category;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color cardBg;
  final bool isUnread;

  _VisualNotif({
    required this.id,
    required this.section,
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.cardBg,
    required this.isUnread,
  });
}
