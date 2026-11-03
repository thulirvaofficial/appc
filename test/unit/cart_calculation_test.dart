import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/data/models/cart_item_model.dart';
import 'package:thulirva_app/data/models/product_model.dart';

void main() {
  group('Cart Calculations & Free Delivery Tests', () {
    final productA = ProductModel(
      id: 1,
      name: 'Fresh Cow Milk (500ml)',
      category: 'Milk',
      price: 44.0,
      weight: '500 ml',
    );

    final productB = ProductModel(
      id: 2,
      name: 'Pure Bilona Cow Ghee (500ml)',
      category: 'Ghee',
      price: 520.0,
      weight: '500 ml',
    );

    test('Under ₹299 subtotal incurs ₹30 delivery charge', () {
      final item = CartItemModel(product: productA, quantity: 2); // 44 * 2 = 88
      final subtotal = item.totalPrice;
      final delivery = subtotal >= 299 ? 0.0 : 30.0;
      final total = subtotal + delivery;

      expect(subtotal, 88.0);
      expect(delivery, 30.0);
      expect(total, 118.0);
    });

    test('Above ₹299 subtotal gets FREE delivery', () {
      final item = CartItemModel(product: productB, quantity: 1); // 520
      final subtotal = item.totalPrice;
      final delivery = subtotal >= 299 ? 0.0 : 30.0;
      final total = subtotal + delivery;

      expect(subtotal, 520.0);
      expect(delivery, 0.0);
      expect(total, 520.0);
    });

    test('Promo discount reduces total correctly', () {
      final item = CartItemModel(product: productB, quantity: 1); // 520
      final subtotal = item.totalPrice;
      final delivery = subtotal >= 299 ? 0.0 : 30.0;
      const discount = 52.0; // 10%
      final total = subtotal - discount + delivery;

      expect(total, 468.0);
    });
  });
}

