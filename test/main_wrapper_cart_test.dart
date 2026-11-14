import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/data/models/cart_item_model.dart';
import 'package:thulirva_app/presentation/cart/cart_screen.dart';
import 'package:thulirva_app/providers/cart_provider.dart';

void main() {
  testWidgets('Reproduce phone cart state with exact phone JSON', (WidgetTester tester) async {
    const rawJson = '''
    [{"product":{"id":1,"name":"test","category":"Dairy","category_name":null,"price":999.0,"compare_price":9999.0,"weight":"test","stock":77,"badge":null,"emoji":"🥛","image":"/assets/images/uploads/prod_1793730913452_691.jpg","description":"","status":"active","variants":[{"id":101,"product_id":1,"name":"test","weight_value":"test","unit":"unit","price":999.0,"compare_price":9999.0,"stock":77,"is_default":true,"is_active":true}]},"product_id":1,"name":"test","price":999.0,"unit_price":999.0,"image":"/assets/images/uploads/prod_1793730913452_691.jpg","quantity":1,"selectedVariant":"test","variant":null}]
    ''';

    final list = (jsonDecode(rawJson) as List).map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();

    final container = ProviderContainer();
    container.read(cartProvider.notifier).addToCart(list.first.product, variant: list.first.selectedVariant);

    tester.view.physicalSize = const Size(1080, 2412);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: CartScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final cartTitleFinder = find.text('My Cart (1)');
    final itemFinder = find.text('test');
    final checkoutFinder = find.text('Proceed to Checkout');

    expect(cartTitleFinder, findsOneWidget);
    expect(itemFinder, findsWidgets);
    expect(checkoutFinder, findsOneWidget);
  });
}


