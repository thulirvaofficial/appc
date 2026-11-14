import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/data/models/product_model.dart';
import 'package:thulirva_app/presentation/cart/cart_screen.dart';
import 'package:thulirva_app/providers/cart_provider.dart';

void main() {
  testWidgets('CartScreen renders item card when cart has 1 product', (WidgetTester tester) async {
    final container = ProviderContainer();

    final testProduct = ProductModel(
      id: 2,
      name: 'test',
      description: 'super',
      category: 'Dairy',
      price: 999.0,
      weight: '500 ml',
      image: '/assets/images/uploads/prod_1793730915013_335.jpg',
      variants: [
        ProductVariantModel(
          id: 201,
          productId: 2,
          name: '500 ml',
          price: 999.0,
          isDefault: true,
        ),
      ],
    );

    // Add product to cart
    container.read(cartProvider.notifier).addToCart(testProduct);

    // Verify item count is 1
    expect(container.read(cartProvider).totalItemCount, 1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CartScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Look for product text
    expect(find.text('test'), findsOneWidget);
    expect(find.text('My Cart (1)'), findsOneWidget);
    expect(find.text('Order Summary'), findsOneWidget);
    expect(find.text('Apply Coupon'), findsOneWidget);
    expect(find.textContaining('Proceed to Checkout'), findsOneWidget);
  });
}
