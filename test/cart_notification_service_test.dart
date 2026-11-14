import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thulirva_app/core/services/cart_notification_service.dart';
import 'package:thulirva_app/core/services/firebase_notification_service.dart';
import 'package:thulirva_app/data/models/product_model.dart';
import 'package:thulirva_app/presentation/cart/cart_screen.dart';

void main() {
  final sampleProduct = ProductModel(
    id: 101,
    name: 'Pure Desi Cow Milk',
    category: 'Dairy',
    price: 90.0,
    weight: '1 Litre',
    description: 'Fresh organic milk',
  );

  testWidgets('CartNotificationService displays, updates on new item, auto-dismisses and navigates', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    CartNotificationService.show(productName: sampleProduct.name, context: context);
                  },
                  child: const Text('Add Milk'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text('Pure Desi Cow Milk added to cart!'), findsNothing);
    expect(find.text('VIEW CART'), findsNothing);

    // Tap Add Milk button
    await tester.tap(find.text('Add Milk'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // Animation settling

    // Notification is visible
    expect(find.text('Pure Desi Cow Milk added to cart!'), findsOneWidget);
    expect(find.text('VIEW CART'), findsOneWidget);

    // Show a second product before 3 seconds elapse (e.g. at 1.5 seconds)
    await tester.pump(const Duration(milliseconds: 1500));
    CartNotificationService.show(productName: 'Organic Ghee');
    await tester.pump();

    // Verify it updated the product name seamlessly without creating duplicates
    expect(find.text('Organic Ghee added to cart!'), findsOneWidget);
    expect(find.text('Pure Desi Cow Milk added to cart!'), findsNothing);
    expect(find.text('VIEW CART'), findsOneWidget);

    // Forward 2 seconds (original timer would have expired at 3s, but reset gives it 3s from 1.5s -> 4.5s)
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Organic Ghee added to cart!'), findsOneWidget);

    // Forward remaining 1.5 seconds (total 3.5s after reset) -> auto-dismissed
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Organic Ghee added to cart!'), findsNothing);

    // Show again and test VIEW CART click navigation
    CartNotificationService.show(productName: 'Wood-Pressed Oil');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Wood-Pressed Oil added to cart!'), findsOneWidget);

    // Tap VIEW CART
    await tester.tap(find.text('VIEW CART'));
    await tester.pumpAndSettle();

    // Verify CartScreen is opened
    expect(find.byType(CartScreen), findsOneWidget);

    // Clean up
    CartNotificationService.hide();
  });
}

