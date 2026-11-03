import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thulirva_app/core/storage/storage_service.dart';
import 'package:thulirva_app/core/theme/app_theme.dart';
import 'package:thulirva_app/presentation/auth/login_screen.dart';
import 'package:thulirva_app/presentation/onboarding/onboarding_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('Onboarding Screen displays headlines and page indicator', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const OnboardingScreen(),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Pure Goodness'), findsOneWidget);
    expect(find.textContaining('Fresh, Natural and Healthy'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });

  testWidgets('Login Screen renders with email, password fields, and brand name', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('THULIRVA'), findsOneWidget);
    expect(find.text('Login to Your Account'), findsOneWidget);
    expect(find.text('Email or Phone'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
