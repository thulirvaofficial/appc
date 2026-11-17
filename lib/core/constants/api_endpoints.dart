class ApiEndpoints {
  // Live Production Backend URL (Ubuntu VPS with Admin Panel at /admin & API at /api)
  static const String defaultLiveUrl = 'https://thulirva.com/api';

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

  static String get serverRoot => baseUrl.replaceAll('/api', '');

  // Resolve static asset images from backend server
  static String resolveImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('data:image/')) return path;

    String cleanPath = path.replaceAll(r'\', '/').trim();

    // If path is already an absolute URL pointing to /uploads/ without /api/, rewrite it to include /api/
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      final uri = Uri.tryParse(cleanPath);
      if (uri != null && uri.path.startsWith('/uploads/')) {
        return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/api${uri.path}';
      }
      return cleanPath;
    }

    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';

    if (cleanPath.startsWith('/uploads/')) {
      return '$serverRoot/api$cleanPath';
    }
    if (cleanPath.startsWith('/api/uploads/')) {
      return '$serverRoot$cleanPath';
    }
    return '$serverRoot$cleanPath';
  }

  // Returns ordered list of candidate URLs for multi-host image loading
  static List<String> getCandidateImageUrls(String path) {
    if (path.isEmpty) return [];
    if (path.startsWith('data:image/')) return [path];

    String cleanPath = path.replaceAll(r'\', '/').trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      final uri = Uri.tryParse(cleanPath);
      if (uri != null) {
        cleanPath = uri.path;
      }
    }
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';

    final candidates = <String>[];

    // Priority 1: Express endpoint via /api/uploads/
    if (cleanPath.startsWith('/uploads/')) {
      candidates.add('$serverRoot/api$cleanPath');
    } else if (cleanPath.startsWith('/api/uploads/')) {
      candidates.add('$serverRoot$cleanPath');
    }

    final hostList = [
      serverRoot,
      'http://127.0.0.1:5500',
      'http://10.0.2.2:5500',
      'http://15.235.251.225',
      'https://thulirva.com',
    ];

    for (final host in hostList) {
      final cleanHost = host.replaceAll(RegExp(r'/api/?$'), '');
      if (cleanPath.startsWith('/uploads/')) {
        final apiVariant = '$cleanHost/api$cleanPath';
        if (!candidates.contains(apiVariant)) {
          candidates.add(apiVariant);
        }
      } else if (cleanPath.startsWith('/api/uploads/')) {
        final apiVariant = '$cleanHost$cleanPath';
        if (!candidates.contains(apiVariant)) {
          candidates.add(apiVariant);
        }
      }
      final url = '$cleanHost$cleanPath';
      if (!candidates.contains(url)) {
        candidates.add(url);
      }
    }
    return candidates;
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String profile = '/auth/profile';
  static const String updateProfile = '/auth/profile';
  static const String profilePhoto = '/auth/profile/photo';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';

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
  static const String pickupLocations = '/pickup/locations';
  static const String deliveryLocations = '/locations';

  // Serviceability & Dynamic Location Management
  static const String checkServiceability = '/serviceability/check';
  static const String activeServiceableAreas = '/serviceability/active';
  static const String reverseGeocode = '/serviceability/reverse-geocode';
  static const String locationAutocomplete = '/serviceability/autocomplete';

  // Business & Delivery Configuration
  static const String deliveryConfig = '/config/delivery';
  static const String codConfig = '/config/cod';
  static const String calculateDeliveryCharge = '/config/delivery/calculate-charge';
  static const String deliveryAvailability = '/config/delivery/availability';
  static const String launchBanner = '/config/launch-banner';
  static const String paymentQr = '/config/payment-qr';

  // Notifications
  static const String userNotifications = '/notifications/user';
  static const String readNotification = '/notifications';
  static const String markNotificationRead = '/notifications';
  static const String registerPushToken = '/notifications/register-token';
  static const String registerDeviceToken = '/notifications/register-token';
}
