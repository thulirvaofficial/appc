import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thulirva_app/data/models/order_model.dart';
import 'package:thulirva_app/data/models/subscription_model.dart';
import 'package:thulirva_app/presentation/orders/my_orders_screen.dart';
import 'package:thulirva_app/providers/order_provider.dart';

class MockOrderNotifier extends OrderNotifier {
  MockOrderNotifier(super.ref, OrderState mockState) {
    state = mockState;
  }

  @override
  Future<void> fetchOrders() async {}
}

void main() {
  final sampleOrder = OrderModel(
    id: 9821,
    userId: 101,
    customerName: 'Karthik Raja',
    customerPhone: '9840198211',
    address: 'Besant Nagar, Chennai',
    city: 'Chennai',
    pincode: '600090',
    items: [
      {'name': 'Bilona Cow Ghee (500ml)', 'quantity': 1, 'price': 499}
    ],
    total: 499,
    paymentMethod: 'UPI Direct',
    paymentStatus: 'verified',
    orderStatus: 'delivered',
    createdAt: '2026-11-10T10:00:00Z',
    orderNumber: 'ORD9821',
  );

  final sampleSubscription = SubscriptionModel(
    id: 'SUB-20261110-8492',
    userId: 101,
    customerName: 'Karthik Raja',
    customerPhone: '9840198211',
    productName: 'Fresh Cow Milk (1 Litre)',
    timePeriod: 'Daily Morning (30 Days)',
    frequency: 'Daily',
    quantity: 1,
    deliverySlot: '6:00 AM - 7:00 AM',
    pricePerDelivery: 82.0,
    totalPrice: 2460.0,
    startDate: '2026-11-10',
    expiryDate: '2026-12-10',
    address: 'Besant Nagar, Chennai',
    paymentStatus: 'verified',
    status: 'Active',
    createdAt: '2026-11-10T10:30:00Z',
  );

  group('Customer Order State & Filter Tests', () {
    test('Counts are calculated accurately for combined, product, and subscription orders', () {
      final state = OrderState(
        orders: [sampleOrder],
        subscriptions: [sampleSubscription],
      );

      expect(state.allOrdersCount, 2);
      expect(state.productOrdersCount, 1);
      expect(state.subscriptionOrdersCount, 1);
    });

    test('All Orders filter returns combined feed sorted latest first', () {
      final state = OrderState(
        orders: [sampleOrder],
        subscriptions: [sampleSubscription],
        typeFilter: 'all',
      );

      final feed = state.filteredFeed;
      expect(feed.length, 2);
      // Subscription was created at 10:30, Order at 10:00, so Subscription is first
      expect(feed.first.type, CustomerOrderItemType.subscription);
      expect(feed.last.type, CustomerOrderItemType.product);
    });

    test('Product Orders filter returns only product orders', () {
      final state = OrderState(
        orders: [sampleOrder],
        subscriptions: [sampleSubscription],
        typeFilter: 'product',
      );

      final feed = state.filteredFeed;
      expect(feed.length, 1);
      expect(feed.first.type, CustomerOrderItemType.product);
      expect(feed.first.productOrder?.orderId, 'ORD9821');
    });

    test('Subscription Orders filter returns only subscription purchases', () {
      final state = OrderState(
        orders: [sampleOrder],
        subscriptions: [sampleSubscription],
        typeFilter: 'subscription',
      );

      final feed = state.filteredFeed;
      expect(feed.length, 1);
      expect(feed.first.type, CustomerOrderItemType.subscription);
      expect(feed.first.subscriptionOrder?.productName, 'Fresh Cow Milk (1 Litre)');
    });
  });

  group('Customer My Orders Screen Widget Tests', () {
    testWidgets('Renders 3 type filters and both Product and Subscription order cards', (tester) async {
      final mockState = OrderState(
        orders: [sampleOrder],
        subscriptions: [sampleSubscription],
        typeFilter: 'all',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderProvider.overrideWith((ref) => MockOrderNotifier(ref, mockState)),
          ],
          child: const MaterialApp(
            home: MyOrdersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('My Orders'), findsOneWidget);

      // Check 3 Type Filter Tabs
      expect(find.text('All Orders'), findsWidgets);
      expect(find.text('🛒 Products'), findsOneWidget);
      expect(find.text('📅 Subscriptions'), findsOneWidget);

      // Check Product Order Badges & Content
      expect(find.text('PRODUCT'), findsOneWidget);
      expect(find.text(sampleOrder.formattedOrderId), findsWidgets);

      // Check Subscription Order Badges & Content
      expect(find.text('SUBSCRIPTION'), findsOneWidget);
      expect(find.text('SUB-20261110-8492'), findsWidgets);
      expect(find.text('Fresh Cow Milk (1 Litre)'), findsOneWidget);
      expect(find.text('₹2460'), findsOneWidget);
      expect(find.text('VERIFIED'), findsWidgets);
      expect(find.text('View Details'), findsWidgets);
    });
  });
}
