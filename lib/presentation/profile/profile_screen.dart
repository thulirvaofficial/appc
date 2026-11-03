import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/my_orders_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../widgets/thulirva_text_field.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).updateProfile(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: addrCtrl.text.trim(),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('App Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Push Notifications', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Receive order & subscription updates', style: TextStyle(fontSize: 12)),
              value: true,
              activeThumbColor: AppColors.forestGreen,
              onChanged: (_) {},
            ),
            SwitchListTile(
              title: const Text('Early Morning Reminders', style: TextStyle(fontSize: 14)),
              subtitle: const Text('5:30 AM dispatch alert', style: TextStyle(fontSize: 12)),
              value: true,
              activeThumbColor: AppColors.forestGreen,
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done', style: TextStyle(color: AppColors.forestGreen))),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Contact Thulirva Customer Care:', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('📞 Phone: +91 79048 80944'),
            SizedBox(height: 4),
            Text('✉️ Email: support@thulirva.com'),
            SizedBox(height: 4),
            Text('⏰ Operating Hours: 6:00 AM - 9:00 PM'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'T';

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Mockup Screen 12: Solid Dark Green Header with Avatar, Name, Email, and Search/Settings
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: const BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Top Actions Row (Search & Settings)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search, color: Colors.white, size: 22),
                              onPressed: () {
                                onSelectTab?.call(0);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.tune, color: Colors.white, size: 22),
                              onPressed: () => _showSettingsDialog(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Centered Circular Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(
                      user?.name ?? 'Kamesh S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      user?.email ?? 'kamesh@example.com',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Menu Options (Mockup Screen 12: My Orders, My Addresses, My Wallet & Offers, Notifications, Help & Support, About Thulirva, Settings)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'My Orders',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
                      },
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.location_on_outlined,
                      title: 'My Addresses',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()));
                      },
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.confirmation_number_outlined,
                      title: 'My Wallet & Offers',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen()));
                      },
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      },
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () => _showHelpSupportDialog(context),
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.info_outline,
                      title: 'About Thulirva',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                      },
                    ),
                    const Divider(height: 1),
                    _buildTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () => _showSettingsDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Logout / Login Tile
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: authState.isAuthenticated
                    ? _buildTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        textColor: AppColors.cancelled,
                        iconColor: AppColors.cancelled,
                        showArrow: false,
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
                      )
                    : _buildTile(
                        icon: Icons.login,
                        title: 'Sign In / Register',
                        textColor: AppColors.forestGreen,
                        iconColor: AppColors.forestGreen,
                        showArrow: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.forestGreen, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
        ),
      ),
      trailing: showArrow ? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20) : null,
      onTap: onTap,
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Farm Support', style: TextStyle(color: AppColors.forestGreen)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 Phone / WhatsApp:\n+91 93606 71533', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Text('✉️ Email:\nsupport@thulirva.com', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Text('⏰ Working Hours:\n5:30 AM – 8:00 PM (Daily)'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
