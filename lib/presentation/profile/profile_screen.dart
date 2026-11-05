import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/my_orders_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../widgets/thulirva_app_bar.dart';
import '../widgets/thulirva_text_field.dart';
import '../../core/services/notification_permission_service.dart';
import 'about_screen.dart';
import 'addresses_screen.dart';
import 'offers_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final void Function(int tabIndex)? onSelectTab;

  const ProfileScreen({super.key, this.onSelectTab});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final addrCtrl = TextEditingController(text: user?.address ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThulirvaTextField(controller: nameCtrl, label: 'Full Name'),
            const SizedBox(height: 10),
            ThulirvaTextField(controller: phoneCtrl, label: 'Phone Number', keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            ThulirvaTextField(controller: addrCtrl, label: 'Default Address'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6E8072))),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).updateProfile(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: addrCtrl.text.trim(),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return FutureBuilder<bool>(
            future: NotificationPermissionService.isPermissionGranted(),
            builder: (ctx, snap) {
              final isGranted = snap.data ?? false;
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestGreen)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Push Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(isGranted ? 'Alerts active • Tap to open system settings' : 'Alerts disabled • Tap to turn on', style: const TextStyle(fontSize: 12)),
                      value: isGranted,
                      activeThumbColor: AppColors.forestGreen,
                      onChanged: (val) async {
                        if (val) {
                          await NotificationPermissionService.requestPermission();
                        } else {
                          await NotificationPermissionService.openSettings();
                        }
                        setDialogState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Early Morning Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('5:30 AM milk dispatch alert', style: TextStyle(fontSize: 12)),
                      value: true,
                      activeThumbColor: AppColors.forestGreen,
                      onChanged: (_) {},
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done', style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700)),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Contact Thulirva Customer Care:', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            Text('📞 Phone: +91 79048 80944'),
            SizedBox(height: 6),
            Text('✉️ Email: support@thulirva.com'),
            SizedBox(height: 6),
            Text('⏰ Operating Hours: 6:00 AM - 9:00 PM'),
          ],
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
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'T';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: ThulirvaAppBar(
        showBack: false,
        showNotifications: true,
        showSettings: true,
        onSettingsTap: () => _showSettingsDialog(context),
        showCart: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          child: Column(
            children: [
              // 1. Pastoral Farm Header Card (Clean Background without text)
              Container(
                width: double.infinity,
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forestGreen.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Clean Background (cows in pasture on right, green gradient on left)
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/profile_clean_bg.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.forestGreen),
                      ),
                    ),

                    // User Info Row (Rendered EXACTLY ONCE via Flutter Widgets)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          // User Avatar Circle
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AppColors.forestGreen,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Name, Email, and Customer Badge
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user?.name ?? 'Valued Customer',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.email ?? 'customer@thulirva.com',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCEFD7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '👤 Customer',
                                    style: TextStyle(
                                      color: AppColors.forestGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Edit Profile Pencil Icon
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                            onPressed: () => _showEditProfileDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Profile Menu Options
              _buildMenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'My Orders',
                subtitle: 'Track and manage orders',
                onTap: () {
                  if (onSelectTab != null) {
                    onSelectTab!(4); // Orders is tab 4
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                    );
                  }
                },
              ),
              _buildMenuItem(
                icon: Icons.calendar_month_outlined,
                title: 'My Subscriptions',
                subtitle: 'Active daily milk & dairy plans',
                onTap: () {
                  if (onSelectTab != null) {
                    onSelectTab!(2); // Subscriptions is tab 2
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubscriptionsScreen(initialTabIndex: 1)),
                    );
                  }
                },
              ),
              _buildMenuItem(
                icon: Icons.location_on_outlined,
                title: 'My Addresses',
                subtitle: 'Manage delivery addresses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressesScreen()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.wallet_outlined,
                title: 'My Wallet & Offers',
                subtitle: 'Wallet, rewards and offers',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OffersScreen()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.notifications_none_outlined,
                title: 'Notifications',
                subtitle: 'Order updates and offers',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Contact support',
                onTap: () => _showHelpSupportDialog(context),
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'About Thulirva',
                subtitle: 'About the company',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'App/account settings',
                onTap: () => _showSettingsDialog(context),
              ),
              const SizedBox(height: 10),

              // 3. Red Logout Card
              GestureDetector(
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.power_settings_new, color: Color(0xFFD32F2F), size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Color(0xFFD32F2F), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F7F0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.forestGreen, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6E8072),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFA5B8AA), size: 20),
          ],
        ),
      ),
    );
  }
}
