// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../firebase_options.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../storage/storage_service.dart';
import 'notification_permission_service.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/orders/my_orders_screen.dart';
import '../../presentation/profile/offers_screen.dart';
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

  static const String channelId = 'thulirva_general_channel';
  static const String channelName = 'THULIRVA General Updates';
  static const String channelDesc = 'Real-time updates, offers, and announcements from Thulirva';

  // Deduplication cache for message IDs
  static final Set<String> _processedMessageIds = <String>{};

  // Custom Raw Resource Notification Sound
  static const soundResource = RawResourceAndroidNotificationSound('thulirva_notification');

  static const int morningReminderNotificationId = 530;

  // 5 Android Notification Channels (with sound & high importance)
  static const AndroidNotificationChannel morningRemindersChannel = AndroidNotificationChannel(
    'thulirva_morning_reminders_v2',
    'THULIRVA Morning Reminders',
    description: 'Daily morning milk delivery reminders at 5:30 AM',
    importance: Importance.max,
    playSound: true,
    sound: soundResource,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel ordersChannel = AndroidNotificationChannel(
    'thulirva_orders_channel_v2',
    'THULIRVA Orders',
    description: 'Real-time updates on your dairy orders and deliveries',
    importance: Importance.max,
    playSound: true,
    sound: soundResource,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel subscriptionsChannel = AndroidNotificationChannel(
    'thulirva_subscriptions_channel_v2',
    'THULIRVA Subscriptions',
    description: 'Milk subscription alerts, renewals & pause status',
    importance: Importance.max,
    playSound: true,
    sound: soundResource,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel paymentsChannel = AndroidNotificationChannel(
    'thulirva_payments_channel_v2',
    'THULIRVA Payments',
    description: 'Payment confirmations, receipts, and refund alerts',
    importance: Importance.max,
    playSound: true,
    sound: soundResource,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
    'thulirva_general_channel_v2',
    'THULIRVA Updates',
    description: 'General farm updates, offers & daily notifications',
    importance: Importance.max,
    playSound: true,
    sound: soundResource,
    enableVibration: true,
    showBadge: true,
  );

  /// Initialize Firebase & Push Notification Listeners
  static Future<void> initialize() async {
    try {
      // 1. Initialize Firebase Core & Timezones
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      } catch (_) {}

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

      // Create all Android Notification Channels
      final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(ordersChannel);
        await androidPlatform.createNotificationChannel(subscriptionsChannel);
        await androidPlatform.createNotificationChannel(paymentsChannel);
        await androidPlatform.createNotificationChannel(generalChannel);
        await androidPlatform.createNotificationChannel(morningRemindersChannel);
        // Legacy fallback channel
        await androidPlatform.createNotificationChannel(
          const AndroidNotificationChannel(
            'thulirva_channel',
            'THULIRVA Alerts',
            description: 'Legacy notification alerts',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
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

      // 11. Schedule Morning Milk Reminder if enabled
      final isMorningReminderOn = await NotificationPermissionService.isMorningReminderEnabled();
      if (isMorningReminderOn) {
        await scheduleDailyMorningReminder();
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
          'app_type': 'customer',
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
            'app_type': 'customer',
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
            'app_type': 'customer',
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
            'thulirva_general_channel_v2',
            'THULIRVA Updates',
            channelDescription: 'General farm updates, offers & daily notifications',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: soundResource,
            enableVibration: true,
            visibility: NotificationVisibility.public,
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

  /// Compute next occurrence of morning reminder
  static tz.TZDateTime _nextInstanceOfMorningTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedule daily 5:30 AM morning milk delivery reminder with sound & vibration
  static Future<void> scheduleDailyMorningReminder({int hour = 5, int minute = 30}) async {
    try {
      final scheduledTime = _nextInstanceOfMorningTime(hour, minute);
      await _localNotifications.zonedSchedule(
        morningReminderNotificationId,
        'Thulirva – Morning Milk Reminder',
        'Your fresh milk delivery is scheduled. Have a wonderful morning!',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'thulirva_morning_reminders_v2',
            'THULIRVA Morning Reminders',
            channelDescription: 'Daily morning milk delivery reminders at 5:30 AM',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            sound: soundResource,
            enableVibration: true,
            visibility: NotificationVisibility.public,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: jsonEncode({
          'type': 'subscription',
          'title': 'Morning Milk Reminder',
          'body': 'Your fresh milk delivery is scheduled. Have a wonderful morning!',
        }),
      );
      if (kDebugMode) {
        print('⏰ [REMINDER] Daily morning reminder active for $hour:${minute.toString().padLeft(2, '0')} (Next: $scheduledTime)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [REMINDER ERROR]: Failed to schedule morning reminder: $e');
      }
    }
  }

  /// Cancel daily morning reminder
  static Future<void> cancelDailyMorningReminder() async {
    try {
      await _localNotifications.cancel(morningReminderNotificationId);
      if (kDebugMode) {
        print('🛑 [REMINDER] Daily morning reminder cancelled.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [REMINDER CANCEL ERROR]: $e');
      }
    }
  }

  /// Handle Foreground Push Messages
  static void _handleForegroundMessage(RemoteMessage message) async {
    final isPushEnabled = await NotificationPermissionService.isPushNotificationsEnabled();
    if (!isPushEnabled) {
      if (kDebugMode) {
        print('🔇 [FCM] Notification suppressed because Push Notifications toggle is OFF');
      }
      return;
    }

    final msgId = message.messageId ?? '${message.sentTime?.millisecondsSinceEpoch}_${message.data.hashCode}';
    if (_processedMessageIds.contains(msgId)) return;
    _processedMessageIds.add(msgId);
    if (_processedMessageIds.length > 100) _processedMessageIds.clear();

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'THULIRVA Update';
    final body = notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';
    final type = (message.data['type'] ?? '').toString().toLowerCase();

    // Map to specific high-importance channel with sound
    String targetChannel = 'thulirva_general_channel_v2';
    String targetChannelName = 'THULIRVA Updates';
    String targetChannelDesc = 'General farm updates & notifications';

    if (type.contains('order')) {
      targetChannel = 'thulirva_orders_channel_v2';
      targetChannelName = 'THULIRVA Orders';
      targetChannelDesc = 'Real-time updates on your dairy orders';
    } else if (type.contains('sub')) {
      targetChannel = 'thulirva_subscriptions_channel_v2';
      targetChannelName = 'THULIRVA Subscriptions';
      targetChannelDesc = 'Milk subscription alerts & renewals';
    } else if (type.contains('pay') || type.contains('receipt') || type.contains('refund')) {
      targetChannel = 'thulirva_payments_channel_v2';
      targetChannelName = 'THULIRVA Payments';
      targetChannelDesc = 'Payment confirmations & receipts';
    }

    // Show Heads-Up Notification via Local Notifications
    _localNotifications.show(
      msgId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          targetChannel,
          targetChannelName,
          channelDescription: targetChannelDesc,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: soundResource,
          enableVibration: true,
          visibility: NotificationVisibility.public,
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

    if (type.contains('coupon') || type.contains('offer')) {
      _navigateToOffers();
    } else if (type.contains('sub')) {
      _navigateToSubscriptions();
    } else if (type.contains('order') || type.contains('pay') || type.contains('pickup')) {
      _navigateToOrders();
    } else {
      _navigateToNotifications();
    }
  }

  static void _navigateToOffers() {
    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      nav.push(MaterialPageRoute(builder: (_) => const OffersScreen()));
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
