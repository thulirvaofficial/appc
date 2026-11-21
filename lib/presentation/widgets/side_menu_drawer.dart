import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/my_orders_screen.dart';
import '../profile/about_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../profile/addresses_screen.dart';
import '../profile/offers_screen.dart';
import '../../core/services/app_update_service.dart';
import 'app_settings_dialog.dart';
import 'app_update_dialog.dart';

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
                    icon: Icons.calendar_month_outlined,
                    title: 'Milk Subscription',
                    onTap: () {
                      Navigator.pop(context);
                      onSelectTab?.call(2);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.event_repeat_outlined,
                    title: 'My Subscriptions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubscriptionsScreen(initialTabIndex: 1)),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Orders',
                    onTap: () {
                      Navigator.pop(context);
                      if (onSelectTab != null) {
                        onSelectTab!(3);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                        );
                      }
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
                      AppSettingsDialog.show(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.system_update_outlined,
                    title: 'Check for Updates',
                    onTap: () async {
                      Navigator.pop(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Checking for Thulirva updates...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      final info = await ref.read(appUpdateProvider.notifier).checkForUpdate(manualCheck: true);
                      if (info != null && info.updateAvailable && context.mounted) {
                        AppUpdateDialog.show(context, info);
                      } else if (context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Thulirva is up to date (v${info?.currentVersion ?? "latest"}).'),
                            backgroundColor: AppColors.forestGreen,
                          ),
                        );
                      }
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
        title: const Row(
          children: [
            Icon(Icons.headset_mic, color: AppColors.forestGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text('Farm Support', style: TextStyle(color: AppColors.forestGreen, fontSize: 18), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📞 Phone / WhatsApp:\n+91 93606 71533', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Text('✉️ Email:\nsupport@thulirva.com', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Text('⏰ Morning Support Hours:\n5:30 AM – 8:00 PM (All 7 Days)'),
            ],
          ),
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
}

