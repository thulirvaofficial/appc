import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyOnboarding = 'thulirva_onboarding_completed';
  static const String _keyToken = 'thulirva_jwt_token';
  static const String _keyUser = 'thulirva_cached_user';
  static const String _keyCart = 'thulirva_mobile_cart';
  static const String _keyPushToken = 'thulirva_fcm_token';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Onboarding
  static bool isOnboardingCompleted() {
    return _prefs?.getBool(_keyOnboarding) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    await _prefs?.setBool(_keyOnboarding, true);
  }

  // Token (Secure Storage)
  static Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _keyToken, value: token);
    } catch (_) {
      await _prefs?.setString(_keyToken, token);
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: _keyToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return _prefs?.getString(_keyToken);
  }

  static Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _keyToken);
    } catch (_) {}
    await _prefs?.remove(_keyToken);
  }

  // User
  static Future<void> saveUser(Map<String, dynamic> userMap) async {
    await _prefs?.setString(_keyUser, jsonEncode(userMap));
  }

  static Map<String, dynamic>? getUser() {
    final str = _prefs?.getString(_keyUser);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUser() async {
    await _prefs?.remove(_keyUser);
  }

  static Future<void> clearAuthSession() async {
    await deleteToken();
    await deleteUser();
  }

  // Push Token
  static Future<void> savePushToken(String token) async {
    await _prefs?.setString(_keyPushToken, token);
  }

  static String? getPushToken() {
    return _prefs?.getString(_keyPushToken);
  }

  // Cart
  static Future<void> saveCart(List<Map<String, dynamic>> cart) async {
    await _prefs?.setString(_keyCart, jsonEncode(cart));
  }

  static List<dynamic> getCart() {
    final str = _prefs?.getString(_keyCart);
    if (str == null || str.isEmpty) return [];
    try {
      final decoded = jsonDecode(str);
      if (decoded is List) return decoded;
    } catch (_) {}
    return [];
  }

  static Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    await _prefs?.clear();
  }
}
