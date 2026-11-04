import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_permission_service.dart';

class NotificationPermissionModal extends StatefulWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDismissed;

  const NotificationPermissionModal({
    super.key,
    this.onGranted,
    this.onDismissed,
  });

  static Future<void> showIfEligible(BuildContext context) async {
    final granted = await NotificationPermissionService.isPermissionGranted();
    if (granted) return;

    final dismissed = await NotificationPermissionService.wasPromptDismissed();
    if (dismissed) return;

    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const NotificationPermissionModal(),
    );
  }

  static Future<void> showForcePrompt(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const NotificationPermissionModal(),
    );
  }

  @override
  State<NotificationPermissionModal> createState() => _NotificationPermissionModalState();
}

class _NotificationPermissionModalState extends State<NotificationPermissionModal> {
  bool _isRequesting = false;

  Future<void> _handleEnable() async {
    setState(() => _isRequesting = true);
    final granted = await NotificationPermissionService.requestPermission();
    if (!mounted) return;
    setState(() => _isRequesting = false);

    Navigator.pop(context);

    if (granted) {
      widget.onGranted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Notifications enabled! You will receive live delivery updates.'),
          backgroundColor: AppColors.naturalGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      widget.onDismissed?.call();
    }
  }

  Future<void> _handleMaybeLater() async {
    await NotificationPermissionService.setPromptDismissed(true);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3DA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Bell Graphic with Green Ring
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7EB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8E6C9), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_active_rounded,
                size: 40,
                color: AppColors.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Never Miss a Fresh Delivery!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.forestGreen,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'Stay updated with live delivery notifications and early morning dispatch alerts.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF556B5D),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          // Feature List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7EE),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5EDE2)),
            ),
            child: Column(
              children: [
                _buildFeatureRow(
                  icon: Icons.local_shipping_outlined,
                  title: 'Live Order Tracking',
                  desc: 'Get notified when your milk and dairy are dispatched and out for delivery.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE5EDE2)),
                ),
                _buildFeatureRow(
                  icon: Icons.alarm_on_outlined,
                  title: '5:30 AM Morning Dispatch',
                  desc: 'Confirmation when fresh A2 milk arrives at your doorstep before sunrise.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE5EDE2)),
                ),
                _buildFeatureRow(
                  icon: Icons.storefront_outlined,
                  title: 'Store Pickup Ready Alerts',
                  desc: 'Instant notice when your self-pickup order is packed and ready for collection.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary Enable Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isRequesting ? null : _handleEnable,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 2,
              ),
              child: _isRequesting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Enable Notifications',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // Maybe Later Button
          TextButton(
            onPressed: _isRequesting ? null : _handleMaybeLater,
            child: const Text(
              'Maybe Later',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6E8072),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFE2F0DE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.forestGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF6E8072),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

