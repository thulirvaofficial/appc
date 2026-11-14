import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thulirva_app/presentation/profile/profile_screen.dart';

void main() {
  testWidgets('Tapping My Orders on ProfileScreen invokes onSelectTab with index 3', (WidgetTester tester) async {
    int? selectedTab;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProfileScreen(
              onSelectTab: (index) {
                selectedTab = index;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify My Orders card is present
    final myOrdersFinder = find.text('My Orders');
    expect(myOrdersFinder, findsOneWidget);

    // Tap the My Orders item
    await tester.tap(myOrdersFinder);
    await tester.pumpAndSettle();

    // Verify onSelectTab was called with index 3 (Orders Tab)
    expect(selectedTab, 3);
  });
}

