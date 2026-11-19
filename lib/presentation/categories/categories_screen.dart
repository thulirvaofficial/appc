import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../providers/category_provider.dart';
import '../products/products_list_screen.dart';
import '../widgets/category_card.dart';
import '../widgets/thulirva_app_bar.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const CategoriesScreen({super.key, this.onNavigateToTab});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryProvider.notifier).fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final categories = categoryState.categories;

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
          child: _buildBody(categoryState, categories),
        ),
      ),
    );
  }

  Widget _buildBody(CategoryState state, List<CategoryModel> categories) {
    // 1. Loading state with no cached categories
    if (state.isLoading && categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.forestGreen,
          strokeWidth: 2.5,
        ),
      );
    }

    // 2. Error state with no cached categories
    if (state.errorMessage != null && categories.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Unable to load categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => ref.read(categoryProvider.notifier).fetchCategories(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    // 3. Empty state
    if (categories.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Center(
            child: Text('🌾', style: TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'No categories found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Please check back later or pull down to refresh.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ],
      );
    }

    // 4. Dynamic Categories List
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
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

        // Dynamic category cards loaded directly from centralized backend
        ...categories.map((cat) => CategoryCard(category: cat)),
        const SizedBox(height: 16),
      ],
    );
  }
}
