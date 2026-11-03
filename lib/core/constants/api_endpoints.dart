import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Live Render Production Backend URL
  static const String defaultLiveUrl = 'https://backend-fprs.onrender.com/api';

  static String _customBaseUrl = '';
  static void setBaseUrl(String url) => _customBaseUrl = url;

  // Primary Base URL: Defaults to Live Render Backend first
  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) return _customBaseUrl;

    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    // Connects to live Render API first
    return defaultLiveUrl;
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String updateProfile = '/auth/profile';

  // Products
  static const String products = '/products';
  static const String featuredProducts = '/products/featured';

  // Categories
  static const String categories = '/categories';

  // Orders
  static const String orders = '/orders';
  static const String userOrders = '/orders/user';

  // Subscriptions
  static const String subscriptions = '/subscriptions';
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String userSubscriptions = '/subscriptions/user';

  // Addresses
  static const String addresses = '/addresses';
  static const String userAddresses = '/addresses/user';

  // Coupons
  static const String coupons = '/coupons';
  static const String validateCoupon = '/coupons/validate';

  // Settings
  static const String storeSettings = '/settings/store';

  // Notifications
  static const String userNotifications = '/notifications/user';
  static const String readNotification = '/notifications';
  static const String markNotificationRead = '/notifications';
  static const String registerPushToken = '/notifications/register-token';
}
