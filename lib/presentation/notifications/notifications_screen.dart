import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
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

  // Default mock notifications matching the reference screen
  final List<_VisualNotif> _referenceNotifs = [
    _VisualNotif(
      id: 'n1',
      section: 'Today',
      title: 'Out for Delivery',
      message: 'Your milk order #TLV1024 is out for delivery and will reach you today by 8:00 AM.',
      time: '10 min ago',
      category: 'Orders',
      icon: Icons.local_shipping_outlined,
      iconBg: const Color(0xFFDCEFD7),
      iconColor: AppColors.forestGreen,
      cardBg: const Color(0xFFEBF7EA),
      isUnread: true,
    ),
    _VisualNotif(
      id: 'n2',
      section: 'Today',
      title: 'Subscription Renewal',
      message: 'Your monthly subscription will renew in 3 days. Keep it active for uninterrupted delivery.',
      time: '1 hour ago',
      category: 'Subscription',
      icon: Icons.calendar_month_outlined,
      iconBg: const Color(0xFFE8F5E9),
      iconColor: AppColors.forestGreen,
      cardBg: const Color(0xFFF7FAF5),
      isUnread: true,
    ),
    _VisualNotif(
      id: 'n3',
      section: 'Yesterday',
      title: 'Order Delivered',
      message: 'Your order #TLV1018 has been delivered successfully. Thank you!',
      time: 'Yesterday, 5:30 PM',
      category: 'Orders',
      icon: Icons.inventory_2_outlined,
      iconBg: const Color(0xFFFDF0D5),
      iconColor: Color(0xFFB37418),
      cardBg: Colors.white,
      isUnread: false,
    ),
    _VisualNotif(
      id: 'n4',
      section: 'This Week',
      title: 'Special Offer! 🎉',
      message: 'Get 10% off on monthly milk subscriptions. Limited time only!',
      time: 'Mon, 10:00 AM',
      category: 'Offers',
      icon: Icons.percent,
      iconBg: const Color(0xFFDCEFD7),
      iconColor: AppColors.forestGreen,
      cardBg: const Color(0xFFEBF7EA),
      isUnread: false,
    ),
    _VisualNotif(
      id: 'n5',
      section: 'This Week',
      title: 'Welcome to Thulirva! 🌱',
      message: 'Thank you for joining Thulirva. Enjoy fresh, pure and natural dairy products at your doorstep.',
      time: 'Sun, 9:00 AM',
      category: 'All',
      icon: Icons.info_outline,
      iconBg: const Color(0xFFFDF0D5),
      iconColor: Color(0xFFB37418),
      cardBg: Colors.white,
      isUnread: false,
    ),
  ];

  void _handleDeepLink(String category) {
    if (category == 'Orders') {
      final orders = ref.read(orderProvider).orders;
      if (orders.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: orders.first)),
        );
      }
    } else if (category == 'Subscription') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
      );
    } else if (category == 'Offers') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OffersScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _referenceNotifs.where((n) {
      if (_selectedFilter == 'All') return true;
      return n.category.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    // Group filtered notifications by section
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
          onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
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

                const SizedBox(height: 24),

                // "You're All Caught Up!" Section
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 70,
                        child: Image.asset(
                          'assets/images/notifications_bell.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.notifications_active,
                            color: Color(0xFFE5A93C),
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'You\'re All Caught Up!',
                        style: TextStyle(
                          color: AppColors.forestGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'No new notifications at the moment.',
                        style: TextStyle(
                          color: Color(0xFF6E8072),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(_VisualNotif notif) {
    return GestureDetector(
      onTap: () => _handleDeepLink(notif.category),
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
