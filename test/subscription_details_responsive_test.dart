import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/data/models/subscription_model.dart';
import 'package:thulirva_app/presentation/subscriptions/customer_subscription_details_screen.dart';

void main() {
  final sampleSub = SubscriptionModel(
    id: '1042',
    userId: '99',
    customerName: 'Karthik Raja',
    customerPhone: '9876543210',
    productName: 'Farm Fresh A2 Desi Cow Milk (Pure & Raw)',
    timePeriod: '30 Days',
    pricePerDelivery: 85.0,
    totalPrice: 2550.0,
    startDate: '2026-11-10',
    frequency: 'Daily (Mon-Sun)',
    quantity: 1,
    deliverySlot: 'Morning (05:30 AM - 07:00 AM)',
    address: 'Plot 42, Green Farms Layout, Pollachi Main Road, Coimbatore, Tamil Nadu - 642001',
    expiryDate: '2026-12-10',
    nextRenewalDate: '2026-12-11',
    transactionId: 'UPI/20261110/98765432101234567890',
    paymentStatus: 'Verification Pending',
    status: 'Active',
  );

  final testWidths = [320.0, 360.0, 393.0, 430.0];

  for (final width in testWidths) {
    testWidgets('CustomerSubscriptionDetailsScreen renders without overflow at ${width}px width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CustomerSubscriptionDetailsScreen(subscription: sampleSub),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
