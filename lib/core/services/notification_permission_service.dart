import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionService {
  static const String _keyPromptDismissed = 'thulirva_notif_prompt_dismissed';
  static const String _keyPermissionGiven = 'thulirva_notif_permission_given';

  static Future<bool> isPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionGiven, status.isGranted);
    await prefs.setBool(_keyPromptDismissed, true);
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
}
