import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thulirva_app/presentation/auth/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen renders Step 0 (Email Input) correctly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Step 0 Headers and Elements
    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(
      find.text("Don't worry. Enter your registered email address and we'll send you a verification code to securely reset your password."),
      findsOneWidget,
    );
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Send Verification Code'), findsOneWidget);
    expect(find.text('← Back to Sign In'), findsOneWidget);

    // 2. Validate empty email validation
    await tester.tap(find.text('Send Verification Code'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your registered email address'), findsOneWidget);

    // 3. Validate invalid email format validation
    await tester.enterText(find.byType(TextFormField).first, 'invalidemail');
    await tester.tap(find.text('Send Verification Code'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a valid email address'), findsOneWidget);
  });

  testWidgets('Step progress indicator reflects active steps', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 3 step indicators exist
    final progressContainers = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxHeight == 4.5,
    );
    expect(progressContainers, findsNWidgets(3));
  });
}
