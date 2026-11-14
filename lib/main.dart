import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/firebase_notification_service.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log all Flutter errors explicitly to console
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    debugPrint('🚨 [FLUTTER ERROR]: ${details.exceptionAsString()}');
  };

  // Initialize Local Storage Services (SharedPreferences & SecureStorage)
  await StorageService.init();

  // Initialize Firebase Cloud Messaging & Push Notifications
  await FirebaseNotificationService.initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: ThulirvaCustomerApp(),
    ),
  );
}

class ThulirvaCustomerApp extends StatelessWidget {
  const ThulirvaCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'THULIRVA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
