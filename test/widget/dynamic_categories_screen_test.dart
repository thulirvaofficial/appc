import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/data/models/category_model.dart';
import 'package:thulirva_app/presentation/categories/categories_screen.dart';
import 'package:thulirva_app/presentation/widgets/category_card.dart';
import 'package:thulirva_app/providers/category_provider.dart';

void main() {
  group('Dynamic Category Content Synchronization Tests', () {
    testWidgets('CategoryCard renders description when provided from backend', (tester) async {
      final categoryWithDesc = CategoryModel(
        id: 1,
        name: 'Milk',
        displayName: 'Fresh Cow Milk',
        description: 'Custom admin-configured fresh milk description.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(category: categoryWithDesc),
          ),
        ),
      );

      expect(find.text('Fresh Cow Milk'), findsOneWidget);
      expect(find.text('Custom admin-configured fresh milk description.'), findsOneWidget);
    });

    testWidgets('CategoryCard completely omits description widget when null or empty', (tester) async {
      final categoryWithoutDesc = CategoryModel(
        id: 2,
        name: 'Ghee',
        displayName: 'Pure Ghee',
        description: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(category: categoryWithoutDesc),
          ),
        ),
      );

      expect(find.text('Pure Ghee'), findsOneWidget);
      // Ensure no fallback marketing text like "Traditional hand-churned..." is rendered!
      expect(find.textContaining('Traditional hand-churned', findRichText: true), findsNothing);
      expect(find.textContaining('Pure farm fresh', findRichText: true), findsNothing);
    });

    testWidgets('CategoriesScreen displays dynamic categories from categoryProvider', (tester) async {
      final mockCategories = [
        CategoryModel(
          id: 10,
          name: 'A2 Butter',
          displayName: 'A2 Cultured Butter',
          description: 'Grass-fed churned butter',
          displayOrder: 1,
        ),
        CategoryModel(
          id: 11,
          name: 'Organic Honey',
          displayName: 'Raw Forest Honey',
          description: null, // Test without description
          displayOrder: 2,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryProvider.overrideWith((ref) => MockCategoryNotifier(mockCategories)),
          ],
          child: const MaterialApp(
            home: CategoriesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('A2 Cultured Butter'), findsOneWidget);
      expect(find.text('Grass-fed churned butter'), findsOneWidget);
      expect(find.text('Raw Forest Honey'), findsOneWidget);
    });
  });
}

class MockCategoryNotifier extends StateNotifier<CategoryState> implements CategoryNotifier {
  final List<CategoryModel> initialList;

  MockCategoryNotifier(this.initialList)
      : super(CategoryState(categories: initialList, isLoading: false));

  @override
  Future<void> fetchCategories() async {
    state = state.copyWith(categories: initialList, isLoading: false);
  }

  @override
  void selectCategory(CategoryModel category) {
    state = state.copyWith(selectedCategory: category);
  }

  @override
  Ref get ref => throw UnimplementedError();
}
