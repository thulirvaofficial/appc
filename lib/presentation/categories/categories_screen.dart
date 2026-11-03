import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/category_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_indicator.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.forestGreen,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () => ref.read(categoryProvider.notifier).fetchCategories(),
          child: categoryState.isLoading && categoryState.categories.isEmpty
              ? const LoadingIndicator(message: 'Loading categories...')
              : categoryState.categories.isEmpty
                  ? EmptyStateView(
                      title: 'No Categories Available',
                      message: 'Categories are being updated from the farm backend.',
                      buttonText: 'Refresh',
                      onButtonPressed: () => ref.read(categoryProvider.notifier).fetchCategories(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      itemCount: categoryState.categories.length,
                      itemBuilder: (context, index) {
                        return CategoryCard(category: categoryState.categories[index]);
                      },
                    ),
        ),
      ),
    );
  }
}

