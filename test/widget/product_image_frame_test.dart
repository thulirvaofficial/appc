import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/data/models/product_model.dart';
import 'package:thulirva_app/presentation/widgets/product_card.dart';
import 'package:thulirva_app/presentation/widgets/product_image_frame.dart';
import 'package:thulirva_app/providers/business_config_provider.dart';
import 'package:thulirva_app/providers/settings_provider.dart';

class FakeStoreSettingsNotifier extends StoreSettingsNotifier {
  FakeStoreSettingsNotifier(super.ref);

  @override
  Future<void> fetchSettings() async {}
}

class FakeBusinessConfigNotifier extends BusinessConfigNotifier {
  FakeBusinessConfigNotifier(super.ref);

  @override
  Future<void> refreshAll() async {}

  @override
  Future<void> fetchDeliveryConfig() async {}

  @override
  Future<void> fetchLaunchBanner() async {}
}

void main() {
  group('ProductImageFrame & ProductCard Pixel-Perfect Tests', () {
    final mockMilk = ProductModel(
      id: 'prod-milk-1',
      name: 'Farm Fresh Pure Cow Milk',
      category: 'Dairy',
      price: 36.0,
      weight: '500 ml',
      badge: 'Bestseller',
      image: '',
    );

    final mockGhee = ProductModel(
      id: 'prod-ghee-1',
      name: 'Organic Desi Cow Ghee',
      category: 'Ghee & Butter',
      price: 520.0,
      weight: '500 ml',
      badge: 'Pure A2',
      image: '',
    );

    final mockPaneer = ProductModel(
      id: 'prod-paneer-1',
      name: 'Fresh Malai Paneer',
      category: 'Paneer',
      price: 110.0,
      weight: '200 g',
      badge: '',
      image: '',
    );

    final mockOil = ProductModel(
      id: 'prod-oil-1',
      name: 'Cold Pressed Sesame Oil',
      category: 'Cold Pressed Oils',
      price: 240.0,
      weight: '1 L',
      badge: 'Cold Pressed',
      image: '',
    );

    testWidgets('ProductImageFrame renders with strict 3:2 landscape aspect ratio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: ProductImageFrame.forProduct(
                product: mockMilk,
              ),
            ),
          ),
        ),
      );

      final aspectRatioFinder = find.byType(AspectRatio);
      expect(aspectRatioFinder, findsOneWidget);

      final AspectRatio aspectRatioWidget = tester.widget(aspectRatioFinder);
      expect(aspectRatioWidget.aspectRatio, closeTo(1.5, 0.001)); // 3 / 2 = 1.5

      final frameSize = tester.getSize(aspectRatioFinder);
      expect(frameSize.width, equals(300.0));
      expect(frameSize.height, closeTo(200.0, 0.01)); // 300 / 1.5 = 200
    });

    testWidgets('ProductImageFrame clips top corners and applies cream background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              child: ProductImageFrame.forProduct(
                product: mockGhee,
                backgroundColor: const Color(0xFFFAF8EF),
              ),
            ),
          ),
        ),
      );

      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsOneWidget);

      final ClipRRect clipWidget = tester.widget(clipRRectFinder);
      final borderRadius = clipWidget.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, greaterThan(0));
      expect(borderRadius.topRight.x, greaterThan(0));
      expect(borderRadius.bottomLeft.x, equals(0));
      expect(borderRadius.bottomRight.x, equals(0));

      final containerFinder = find.byWidgetPredicate(
        (w) => w is Container && w.color == const Color(0xFFFAF8EF),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('ProductCard embeds ProductImageFrame with badge overlay', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => FakeStoreSettingsNotifier(ref)),
            businessConfigProvider.overrideWith((ref) => FakeBusinessConfigNotifier(ref)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 160,
                height: 222,
                child: ProductCard(product: mockMilk),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProductImageFrame), findsOneWidget);
      expect(find.text('Bestseller'), findsOneWidget);
      expect(find.text('Farm Fresh Pure Cow Milk'), findsOneWidget);
      expect(find.text('₹36'), findsOneWidget);
    });

    testWidgets('Grid with multiple product categories renders with identical image frames and zero overflow on 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final products = [mockMilk, mockGhee, mockPaneer, mockOil];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => FakeStoreSettingsNotifier(ref)),
            businessConfigProvider.overrideWith((ref) => FakeBusinessConfigNotifier(ref)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: products.length,
                itemBuilder: (_, index) => ProductCard(product: products[index]),
              ),
            ),
          ),
        ),
      );

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      final imageFrames = find.byType(ProductImageFrame);
      expect(imageFrames, findsNWidgets(4));

      // Verify all 4 image frames have identical dimensions
      final firstSize = tester.getSize(imageFrames.first);
      for (final element in tester.elementList(imageFrames)) {
        final size = tester.getSize(find.byElementPredicate((e) => e == element));
        expect(size.width, equals(firstSize.width));
        expect(size.height, equals(firstSize.height));
        expect(size.width / size.height, closeTo(1.5, 0.01)); // Exact 3:2
      }
    });

    testWidgets('Grid with multiple product categories renders with identical image frames on 360px screen', (tester) async {
      tester.view.physicalSize = const Size(360 * 2.0, 780 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final products = [mockMilk, mockGhee, mockPaneer, mockOil];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => FakeStoreSettingsNotifier(ref)),
            businessConfigProvider.overrideWith((ref) => FakeBusinessConfigNotifier(ref)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: products.length,
                itemBuilder: (_, index) => ProductCard(product: products[index]),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final imageFrames = find.byType(ProductImageFrame);
      expect(imageFrames, findsNWidgets(4));

      final firstSize = tester.getSize(imageFrames.first);
      for (final element in tester.elementList(imageFrames)) {
        final size = tester.getSize(find.byElementPredicate((e) => e == element));
        expect(size.width, equals(firstSize.width));
        expect(size.height, equals(firstSize.height));
        expect(size.width / size.height, closeTo(1.5, 0.01)); // Strict 3:2
      }
    });

    testWidgets('Grid with multiple product categories renders with identical image frames on 412px screen', (tester) async {
      tester.view.physicalSize = const Size(412 * 2.0, 915 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final products = [mockMilk, mockGhee, mockPaneer, mockOil];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => FakeStoreSettingsNotifier(ref)),
            businessConfigProvider.overrideWith((ref) => FakeBusinessConfigNotifier(ref)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: products.length,
                itemBuilder: (_, index) => ProductCard(product: products[index]),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final imageFrames = find.byType(ProductImageFrame);
      expect(imageFrames, findsNWidgets(4));

      final firstSize = tester.getSize(imageFrames.first);
      for (final element in tester.elementList(imageFrames)) {
        final size = tester.getSize(find.byElementPredicate((e) => e == element));
        expect(size.width, equals(firstSize.width));
        expect(size.height, equals(firstSize.height));
        expect(size.width / size.height, closeTo(1.5, 0.01));
      }
    });
  });
}
