import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/my_orders_screen.dart';
import '../profile/about_screen.dart';
import '../profile/addresses_screen.dart';
import '../profile/offers_screen.dart';
import '../subscriptions/subscriptions_screen.dart';

class SideMenuDrawer extends ConsumerWidget {
  final void Function(int tabIndex)? onSelectTab;

  const SideMenuDrawer({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'T';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.forestGreen,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Guest Customer',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'Sign in for farm deliveries',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items (Mockup Screen 13: Exact Order)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(0);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.grid_view_outlined,
                    title: 'Shop by Category',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(1);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Orders',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'My Addresses',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddressesScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.confirmation_number_outlined,
                    title: 'My Wallet & Offers',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OffersScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About Thulirva',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      _showServerSettingsDialog(context, ref);
                    },
                  ),
                  const Divider(height: 16),
                  if (authState.isAuthenticated)
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      textColor: AppColors.cancelled,
                      iconColor: AppColors.cancelled,
                      onTap: () async {
                        Navigator.pop(context);
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                    )
                  else
                    _buildMenuItem(
                      icon: Icons.login,
                      title: 'Login / Register',
                      textColor: AppColors.forestGreen,
                      iconColor: AppColors.forestGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Footer branding
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'THULIRVA v1.0.0 • Rooted in Nature',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.forestGreen,
        size: 22,
      ),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(
          color: textColor ?? AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 12,
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.headset_mic, color: AppColors.forestGreen),
            SizedBox(width: 8),
            Text('Farm Support', style: TextStyle(color: AppColors.forestGreen, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('📞 Phone / WhatsApp:\n+91 93606 71533', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Text('✉️ Email:\nsupport@thulirva.com', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Text('⏰ Morning Support Hours:\n5:30 AM – 8:00 PM (All 7 Days)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.forestGreen)),
          ),
        ],
      ),
    );
  }

  void _showServerSettingsDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: ApiEndpoints.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.dns, color: AppColors.forestGreen),
            SizedBox(width: 8),
            Text('API Server Settings', style: TextStyle(color: AppColors.forestGreen, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your backend API URL:\n(e.g. Render, Railway, Wi-Fi IP or Localhost)',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMid),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'https://backend-fprs.onrender.com/api',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiEndpoints.setBaseUrl(newUrl);
                ref.read(productProvider.notifier).fetchProducts();
                ref.read(categoryProvider.notifier).fetchCategories();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Server URL updated to: $newUrl'),
                    backgroundColor: AppColors.forestGreen,
                  ),
                );
              }
            },
            child: const Text('Save & Connect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

