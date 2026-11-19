import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/presentation/common/no_internet_screen.dart';

void main() {
  testWidgets('NoInternetScreen renders all required UI elements according to reference design',
      (WidgetTester tester) async {
    bool retryTapped = false;
    int selectedTab = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: NoInternetScreen(
            showBottomNav: true,
            currentTabIndex: 0,
            onRetrySuccess: () {
              retryTapped = true;
            },
            onSelectTab: (idx) {
              selectedTab = idx;
            },
          ),
        ),
      ),
    );

    // 1. Verify Top Branded Header
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);

    // 2. Verify Heading and Description Text
    expect(find.text('No Internet Connection'), findsOneWidget);
    expect(
      find.text(
        "We couldn't reach the server. Please check your internet connection and try again.",
      ),
      findsOneWidget,
    );

    // 3. Verify Try Again Button
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    // 4. Verify Bottom Navigation Bar Items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // 5. Test Tab Selection Callback
    await tester.tap(find.text('Subscriptions'));
    await tester.pumpAndSettle();
    expect(selectedTab, 2);

    // 6. Test Try Again Button Tap Interaction
    await tester.tap(find.text('Try Again'));
    await tester.pump(); // Start loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

