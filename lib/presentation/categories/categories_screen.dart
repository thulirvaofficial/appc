import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../providers/category_provider.dart';
import '../products/products_list_screen.dart';
import '../widgets/category_card.dart';
import '../widgets/thulirva_app_bar.dart';

class CategoriesScreen extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const CategoriesScreen({super.key, this.onNavigateToTab});

  // Default primary 7 categories matching the reference design exactly
  static final List<CategoryModel> _defaultCategories = [
    CategoryModel(
      id: 'fresh_cow_milk',
      name: 'Fresh Cow Milk',
      displayName: 'Fresh Cow Milk',
      description: 'Farm fresh A2 raw & chilled cow milk from our farms',
    ),
    CategoryModel(
      id: 'ghee_butter',
      name: 'Ghee & Butter',
      displayName: 'Ghee & Butter',
      description: 'Traditional hand-churned Bilona ghee and fresh butter',
    ),
    CategoryModel(
      id: 'paneer_tofu',
      name: 'Paneer & Tofu',
      displayName: 'Paneer & Tofu',
      description: 'Soft, melt-in-mouth cottage cheese and protein-rich tofu',
    ),
    CategoryModel(
      id: 'natural_set_curd',
      name: 'Natural Set Curd',
      displayName: 'Natural Set Curd',
      description: 'Naturally cultured probiotic thick curd for a healthy gut',
    ),
    CategoryModel(
      id: 'cold_pressed_oils',
      name: 'Cold-Pressed Oils',
      displayName: 'Cold-Pressed Oils',
      description: 'Traditional wooden chekku cold-pressed oils, unrefined & pure',
    ),
    CategoryModel(
      id: 'pure_spices_masalas',
      name: 'Pure Spices & Masalas',
      displayName: 'Pure Spices & Masalas',
      description: 'Single-origin Salem turmeric, spices and authentic masalas',
    ),
    CategoryModel(
      id: 'vegan_plant_based',
      name: 'Vegan & Plant-Based',
      displayName: 'Vegan & Plant-Based',
      description: 'Nutritious dairy-free and plant-based alternatives',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryState = ref.watch(categoryProvider);
    final categoriesToDisplay =
        categoryState.categories.isNotEmpty ? categoryState.categories : _defaultCategories;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: ThulirvaAppBar(
        showBack: Navigator.canPop(context),
        showSearch: true,
        onSearchTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductsListScreen(initialSearchQuery: ''),
            ),
          );
        },
        showCart: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () => ref.read(categoryProvider.notifier).fetchCategories(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              // Header title & subtitle
              const Center(
                child: Text(
                  'Categories',
                  style: TextStyle(
                    color: AppColors.forestGreen,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  'Explore our fresh & natural product ranges',
                  style: TextStyle(
                    color: Color(0xFF556B5D),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Category Cards List
              ...categoriesToDisplay.map((cat) => CategoryCard(category: cat)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
