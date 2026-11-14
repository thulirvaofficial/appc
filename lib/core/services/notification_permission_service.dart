import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';

class NotificationPermissionService {
  static const String _keyPromptDismissed = 'thulirva_notif_prompt_dismissed';
  static const String _keyPermissionGiven = 'thulirva_notif_permission_given';
  static const String _keyPushNotificationsEnabled = 'thulirva_push_notifications_enabled';
  static const String _keyMorningReminderEnabled = 'thulirva_morning_reminder_enabled';

  /// Check whether OS-level notification permission is granted
  static Future<bool> isPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Get the precise permission status (granted, denied, permanentlyDenied, etc.)
  static Future<PermissionStatus> getPermissionStatus() async {
    return await Permission.notification.status;
  }

  /// Request OS-level notification permission
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionGiven, status.isGranted);
    await prefs.setBool(_keyPromptDismissed, true);
    if (status.isGranted) {
      await setPushNotificationsEnabled(true);
    }
    return status.isGranted;
  }

  static Future<bool> wasPromptDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPromptDismissed) ?? false;
  }

  static Future<void> setPromptDismissed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPromptDismissed, value);
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  // --- Push Notifications Toggle State & Backend Sync ---

  /// Check whether in-app push notifications preference is enabled
  static Future<bool> isPushNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPushNotificationsEnabled) ?? true;
  }

  /// Update in-app push notification preference and synchronize with backend
  static Future<void> setPushNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushNotificationsEnabled, enabled);

    // Sync preference with backend
    try {
      final user = StorageService.getUser();
      final userId = user?['id'];
      final apiClient = ApiClient();
      await apiClient.post(
        '/notifications/update-preference',
        data: {
          'user_id': userId,
          'enabled': enabled,
          'role': 'customer',
        },
      );
      if (kDebugMode) {
        print('✓ [NOTIF PREF] Notification preference synced to backend: enabled=$enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [NOTIF PREF ERROR]: Failed to sync preference to backend: $e');
      }
    }
  }

  // --- Early Morning Reminders State ---

  /// Check whether early morning reminder is enabled
  static Future<bool> isMorningReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMorningReminderEnabled) ?? true;
  }

  /// Set early morning reminder enabled state
  static Future<void> setMorningReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMorningReminderEnabled, enabled);
  }
}

