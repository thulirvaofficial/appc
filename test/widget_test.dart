import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thulirva_app/core/storage/storage_service.dart';
import 'package:thulirva_app/main.dart';
import 'package:thulirva_app/presentation/splash/splash_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('App root initializes with light cream splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ThulirvaCustomerApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify SplashScreen is loaded
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('THULIRVA'), findsOneWidget);

    // Complete pending navigation timer (2600ms)
    await tester.pump(const Duration(milliseconds: 3000));
  });
}
