import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thulirva_app/data/models/subscription_model.dart';
import 'package:thulirva_app/presentation/subscriptions/subscriptions_screen.dart';
import 'package:thulirva_app/providers/subscription_provider.dart';

void main() {
  testWidgets('Test SubscriptionsScreen rendering My Subscriptions tab', (WidgetTester tester) async {
    final mockJson = {
      "id": "SUB-7055",
      "user_id": 3,
      "customer_name": "hello",
      "customer_phone": "9777888874",
      "customer_email": "kameshthehacker01@gmail.com",
      "plan_id": 1,
      "product_id": null,
      "product_name": "Fresh Cow Milk (500ml)",
      "product_image": "/assets/images/products/fresh_cow_milk.jpg",
      "time_period": "Daily Morning (30 Days)",
      "frequency": "Daily",
      "quantity": 1,
      "delivery_slot": "Morning: 6:00 AM - 7:00 AM",
      "price_per_delivery": "44.00",
      "total_price": "1320.00",
      "start_date": "2026-11-08",
      "address": "thiruverkadu",
      "city": "Chennai",
      "pincode": "600000",
      "payment_method": "UPI Direct Payment (7904880944@superyes)",
      "payment_status": "Paid (Verification Pending)",
      "status": "Active",
      "transaction_id": "123456789012",
      "payment_proof": "",
      "created_at": "2026-11-07T13:44:55.591Z"
    };

    final subModel = SubscriptionModel.fromJson(mockJson);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionProvider.overrideWith((ref) => MockSubscriptionNotifier([subModel])),
        ],
        child: const MaterialApp(
          home: SubscriptionsScreen(initialTabIndex: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fresh Cow Milk (500ml)'), findsOneWidget);
    expect(find.text('PENDING APPROVAL'), findsOneWidget);
    expect(find.text('₹1320'), findsOneWidget);
  });
}

class MockSubscriptionNotifier extends StateNotifier<SubscriptionState> implements SubscriptionNotifier {
  MockSubscriptionNotifier(List<SubscriptionModel> subs)
      : super(SubscriptionState(subscriptions: subs, isLoading: false));

  @override
  Future<void> fetchPlans() async {}

  @override
  Future<void> fetchSubscriptions({String? explicitIdent}) async {}

  @override
  Future<bool> createSubscription(Map<String, dynamic> payload) async => true;

  @override
  Future<bool> updateStatus(String subId, String newStatus) async => true;

  @override
  Future<bool> pauseSubscription(String subId) async => true;

  @override
  Future<bool> resumeSubscription(String subId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
