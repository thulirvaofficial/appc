import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_notification_service.dart';
import '../../core/services/notification_permission_service.dart';

class AppSettingsDialog extends StatefulWidget {
  const AppSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AppSettingsDialog(),
    );
  }

  @override
  State<AppSettingsDialog> createState() => _AppSettingsDialogState();
}

class _AppSettingsDialogState extends State<AppSettingsDialog> with WidgetsBindingObserver {
  bool _osPermissionGranted = false;
  bool _pushNotificationsPref = true;
  bool _morningReminderPref = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from Android App Settings, re-check OS permission
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final osGranted = await NotificationPermissionService.isPermissionGranted();
    final pushPref = await NotificationPermissionService.isPushNotificationsEnabled();
    final morningPref = await NotificationPermissionService.isMorningReminderEnabled();

    if (mounted) {
      setState(() {
        _osPermissionGranted = osGranted;
        _pushNotificationsPref = pushPref;
        _morningReminderPref = morningPref;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePushToggle(bool val) async {
    if (val) {
      // If user wants to turn on, check if OS permission is allowed
      if (!_osPermissionGranted) {
        final granted = await NotificationPermissionService.requestPermission();
        if (!granted) {
          // If still denied, prompt to open device settings
          if (mounted) {
            _showPermissionDeniedDialog();
          }
          return;
        }
        setState(() => _osPermissionGranted = true);
      }
      setState(() => _pushNotificationsPref = true);
      await NotificationPermissionService.setPushNotificationsEnabled(true);
    } else {
      // User turned off notifications
      setState(() => _pushNotificationsPref = false);
      await NotificationPermissionService.setPushNotificationsEnabled(false);
    }
  }

  Future<void> _handleMorningReminderToggle(bool val) async {
    setState(() => _morningReminderPref = val);
    await NotificationPermissionService.setMorningReminderEnabled(val);
    if (val) {
      await FirebaseNotificationService.scheduleDailyMorningReminder(hour: 5, minute: 30);
    } else {
      await FirebaseNotificationService.cancelDailyMorningReminder();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Notifications Blocked',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestGreen),
        ),
        content: const Text(
          'Android system notifications are currently disabled for Thulirva. '
          'To receive order, delivery, and payment updates, please enable notifications in your phone settings.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              NotificationPermissionService.openSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePushActive = _osPermissionGranted && _pushNotificationsPref;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Row(
        children: const [
          Icon(Icons.settings_outlined, color: AppColors.forestGreen, size: 22),
          SizedBox(width: 8),
          Text(
            'App Settings',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestGreen, fontSize: 18),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Push Notifications Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: effectivePushActive ? const Color(0xFFFAF7EE) : const Color(0xFFF7F7F7),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Push Notifications',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                      ),
                      subtitle: Text(
                        !_osPermissionGranted
                            ? 'Blocked by phone settings • Tap to configure'
                            : (_pushNotificationsPref
                                ? 'Alerts active (Orders, Subscriptions, Payments)'
                                : 'Alerts muted by customer'),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: !_osPermissionGranted
                              ? Colors.red.shade700
                              : (_pushNotificationsPref ? const Color(0xFF4A6B53) : Colors.grey.shade600),
                          fontWeight: !_osPermissionGranted ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      value: effectivePushActive,
                      activeThumbColor: AppColors.forestGreen,
                      onChanged: (val) => _handlePushToggle(val),
                    ),
                  ),
                  if (!_osPermissionGranted) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => NotificationPermissionService.openSettings(),
                        icon: const Icon(Icons.settings, size: 14, color: AppColors.forestGreen),
                        label: const Flexible(
                          child: Text(
                            'Open Device Notification Settings',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // 2. Early Morning Reminders Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _morningReminderPref ? const Color(0xFFFAF7EE) : const Color(0xFFF7F7F7),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        'Early Morning Reminders',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                      ),
                      subtitle: const Text(
                        '5:30 AM daily milk dispatch alert with sound & vibration',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF4A6B53)),
                      ),
                      value: _morningReminderPref,
                      activeThumbColor: AppColors.forestGreen,
                      onChanged: (val) => _handleMorningReminderToggle(val),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Done',
            style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
