// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../firebase_options.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/orders/my_orders_screen.dart';
import '../../presentation/subscriptions/subscriptions_screen.dart';

// Global Navigator Key for Notification Redirection
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// Top-level Background Messaging Handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  if (kDebugMode) {
    print('🌙 [FCM BACKGROUND MESSAGE]: ${message.messageId} - ${message.notification?.title}');
  }
}

class FirebaseNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String channelId = 'thulirva_channel';
  static const String channelName = 'THULIRVA Farm Notifications';
  static const String channelDesc = 'Real-time updates on orders, milk subscriptions, and farm releases';

  // Deduplication cache for message IDs
  static final Set<String> _processedMessageIds = <String>{};

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Initialize Firebase & Push Notification Listeners
  static Future<void> initialize() async {
    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Set Background Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Configure Android Local Notifications Plugin
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!) as Map<String, dynamic>;
              _routeNotificationPayload(data);
            } catch (_) {
              _navigateToNotifications();
            }
          } else {
            _navigateToNotifications();
          }
        },
      );

      // Create Android Notification Channel
      final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(_channel);
      }

      // 4. Request Permissions
      await requestNotificationPermissions();

      // 5. Configure Foreground Presentation Options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 6. Fetch & Register Device Token
      await _registerDeviceToken();

      // 7. Token Refresh Listener
      _messaging.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });

      // 8. Foreground Message Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 9. App Opened from Background State Listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _routeNotificationPayload(message.data);
      });

      // 10. Check Terminated-state Initial Message
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        // Delay slightly to let initial route render
        Future.delayed(const Duration(milliseconds: 1200), () {
          _routeNotificationPayload(initialMessage.data);
        });
      }

      if (kDebugMode) {
        print('✓ [FCM] Firebase Push Notification Service initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FCM INIT ERROR]: $e');
      }
    }
  }

  /// Request Notification Permissions (Android 13+ & iOS)
  static Future<bool> requestNotificationPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Fetch FCM Token and register with backend
  static Future<void> _registerDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          print('🔑 [FCM TOKEN]: $token');
        }
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FCM TOKEN ERROR]: $e');
      }
    }
  }

  /// Send Device Token to Node.js backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final user = StorageService.getUser();
      final userId = user?['id'];

      final apiClient = ApiClient();
      await apiClient.post(
        ApiEndpoints.registerDeviceToken,
        data: {
          'token': token,
          'platform': 'android',
          'user_id': userId,
          'role': 'customer',
        },
      );
      if (kDebugMode) {
        print('✓ [FCM] Device token registered with backend for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FCM BACKEND REGISTER ERROR]: $e');
      }
    }
  }

  /// Manually sync token after login/logout
  static Future<void> syncUserToken(dynamic userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        final apiClient = ApiClient();
        await apiClient.post(
          ApiEndpoints.registerDeviceToken,
          data: {
            'token': token,
            'platform': 'android',
            'user_id': userId,
            'role': 'customer',
          },
        );
      }
    } catch (_) {}
  }

  /// Disassociate token on logout
  static Future<void> disassociateUserToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        final apiClient = ApiClient();
        await apiClient.post(
          ApiEndpoints.registerDeviceToken,
          data: {
            'token': token,
            'platform': 'android',
            'user_id': null,
            'role': 'guest',
          },
        );
      }
    } catch (_) {}
  }

  /// Trigger immediate high-importance heads-up notification (welcome, orders, etc.)
  static Future<void> showLocalAlert({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload != null ? jsonEncode(payload) : null,
      );
    } catch (_) {}
  }

  /// Handle Foreground Push Messages
  static void _handleForegroundMessage(RemoteMessage message) {
    final msgId = message.messageId ?? '${message.sentTime?.millisecondsSinceEpoch}_${message.data.hashCode}';
    if (_processedMessageIds.contains(msgId)) return;
    _processedMessageIds.add(msgId);
    if (_processedMessageIds.length > 100) _processedMessageIds.clear();

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'THULIRVA Update';
    final body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

    // Show Heads-Up Notification via Local Notifications
    _localNotifications.show(
      msgId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Route to appropriate screen on notification click
  static void _routeNotificationPayload(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toLowerCase();

    if (type.contains('order')) {
      _navigateToOrders();
    } else if (type.contains('sub')) {
      _navigateToSubscriptions();
    } else {
      _navigateToNotifications();
    }
  }

  static void _navigateToOrders() {
    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
    }
  }

  static void _navigateToSubscriptions() {
    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const SubscriptionsScreen(initialTabIndex: 1)));
    }
  }

  static void _navigateToNotifications() {
    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
  }
}
