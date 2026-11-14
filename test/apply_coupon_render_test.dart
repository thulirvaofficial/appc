import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thulirva_app/presentation/cart/apply_coupon_screen.dart';

void main() {
  testWidgets('ApplyCouponScreen renders properly without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ApplyCouponScreen(),
        ),
      ),
    );

    // Initial pump and settle async timers
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Verify AppBar title is present
    expect(find.text('Apply Coupon'), findsOneWidget);

    // Verify input box text is present
    expect(find.text('Have a Promo or Coupon Code?'), findsOneWidget);
  });
}
