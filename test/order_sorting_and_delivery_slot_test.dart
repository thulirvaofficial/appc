import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thulirva_app/data/models/order_model.dart';
import 'package:thulirva_app/presentation/orders/my_orders_screen.dart';
import 'package:thulirva_app/presentation/orders/order_details_screen.dart';
import 'package:thulirva_app/providers/order_provider.dart';

void main() {
  group('Customer App Order Sorting & Delivery Timing Tests', () {
    test('OrderModel parses createdDateTime and deliverySlot accurately', () {
      final json = {
        'id': '101',
        'order_number': 'THU-20261119-0101',
        'customer_name': 'Karthik',
        'customer_phone': '9876543210',
        'address': 'Porur',
        'city': 'Chennai',
        'pincode': '600116',
        'items': [],
        'total': 150.0,
        'created_at': '2026-11-19T10:00:00.000Z',
        'delivery_slot': 'Morning Delivery (06:00 AM – 07:00 AM)',
        'delivery_slot_id': 'morning',
        'delivery_start_time': '06:00 AM',
        'delivery_end_time': '07:00 AM',
      };

      final order = OrderModel.fromJson(json);
      expect(order.orderId, 'THU-20261119-0101');
      expect(order.deliverySlot, 'Morning Delivery (06:00 AM – 07:00 AM)');
      expect(order.deliveryStartTime, '06:00 AM');
      expect(order.deliveryEndTime, '07:00 AM');
      expect(order.createdDateTime.year, 2026);
      expect(order.createdDateTime.month, 11);
      expect(order.createdDateTime.day, 19);
    });

    test('OrderState sorts orders strictly descending by creation date (newest first)', () {
      final oldOrder = OrderModel(
        id: '1',
        customerName: 'Old User',
        customerPhone: '1111111111',
        address: 'Adyar',
        city: 'Chennai',
        pincode: '600020',
        items: [],
        total: 100,
        createdAt: '2026-11-10T08:00:00.000Z',
      );

      final newOrder = OrderModel(
        id: '2',
        customerName: 'New User',
        customerPhone: '2222222222',
        address: 'Porur',
        city: 'Chennai',
        pincode: '600116',
        items: [],
        total: 200,
        createdAt: '2026-11-19T15:30:00.000Z',
      );

      final state = OrderState(
        orders: [oldOrder, newOrder], // intentionally placed old first
        typeFilter: 'all',
        selectedFilter: 'All',
      );

      // Verify filteredFeed places newOrder at index 0
      final feed = state.filteredFeed;
      expect(feed.length, 2);
      expect(feed[0].id, '2');
      expect(feed[1].id, '1');

      // Verify filteredOrders places newOrder at index 0
      final productOrders = state.filteredOrders;
      expect(productOrders.length, 2);
      expect(productOrders[0].id, '2');
      expect(productOrders[1].id, '1');
    });

    testWidgets('MyOrdersScreen renders delivery timing banner for scheduled orders', (tester) async {
      final orderWithSlot = OrderModel(
        id: '101',
        orderNumber: 'THU-20261119-0101',
        customerName: 'Anand Kumar',
        customerPhone: '9876543210',
        address: 'Porur',
        city: 'Chennai',
        pincode: '600116',
        items: [{'name': 'Farm Fresh Cow Milk 1L', 'quantity': 1, 'price': 65}],
        total: 65,
        createdAt: '2026-11-19T10:00:00.000Z',
        deliverySlot: 'Morning Delivery (06:00 AM – 07:00 AM)',
      );

      await tester.binding.setSurfaceSize(const Size(375, 812));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderProvider.overrideWith((ref) => _FakeOrderNotifier([orderWithSlot])),
          ],
          child: const MaterialApp(
            home: MyOrdersScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify slot name and time range appear
      expect(find.textContaining('Morning Delivery'), findsWidgets);
      expect(find.textContaining('06:00 AM – 07:00 AM'), findsWidgets);
    });

    testWidgets('OrderDetailsScreen renders delivery schedule card for scheduled order', (tester) async {
      final orderWithSlot = OrderModel(
        id: '101',
        orderNumber: 'THU-20261119-0101',
        customerName: 'Anand Kumar',
        customerPhone: '9876543210',
        address: 'Porur',
        city: 'Chennai',
        pincode: '600116',
        items: [{'name': 'Farm Fresh Cow Milk 1L', 'quantity': 1, 'price': 65}],
        total: 65,
        createdAt: '2026-11-19T10:00:00.000Z',
        deliverySlot: 'Morning Delivery (06:00 AM – 07:00 AM)',
      );

      await tester.binding.setSurfaceSize(const Size(375, 812));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderDetailsScreen(key: const ValueKey('withSlot'), order: orderWithSlot),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Morning Delivery'), findsOneWidget);
      expect(find.text('06:00 AM – 07:00 AM'), findsOneWidget);
    });

    testWidgets('OrderDetailsScreen renders fallback for legacy orders without slot', (tester) async {
      final legacyOrder = OrderModel(
        id: '99',
        orderNumber: 'THU-20261110-0099',
        customerName: 'Legacy Customer',
        customerPhone: '9876543210',
        address: 'Adyar',
        city: 'Chennai',
        pincode: '600020',
        items: [{'name': 'Curd 500g', 'quantity': 1, 'price': 45}],
        total: 45,
        createdAt: '2026-11-10T10:00:00.000Z',
        deliverySlot: null,
      );

      await tester.binding.setSurfaceSize(const Size(375, 812));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderDetailsScreen(key: const ValueKey('legacy'), order: legacyOrder),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Delivery time not specified'), findsOneWidget);
    });
  });
}

class _FakeOrderNotifier extends StateNotifier<OrderState> implements OrderNotifier {
  _FakeOrderNotifier(List<OrderModel> orders)
      : super(OrderState(orders: orders, typeFilter: 'all', selectedFilter: 'All'));

  @override
  Future<void> fetchOrders() async {}

  @override
  void resetState() {}

  @override
  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  @override
  void setTypeFilter(String type) {
    state = state.copyWith(typeFilter: type);
  }

  @override
  Future<OrderModel?> fetchOrderTrackingDetails(String orderId) async => null;

  @override
  Future<Map<String, dynamic>> fetchDeliveryProofDetails(String orderId) async => {};

  @override
  Future<OrderModel?> placeOrder(Map<String, dynamic> payload) async => null;

  @override
  Future<bool> cancelOrder(String orderId) async => false;

  @override
  Future<bool> rateOrder({
    required String orderId,
    required int rating,
    String feedback = '',
    List<String> tags = const [],
  }) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
