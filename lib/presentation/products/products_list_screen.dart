import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../cart/cart_screen.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/product_card.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  final String? categoryName;
  final String? initialSearchQuery;

  const ProductsListScreen({
    super.key,
    this.categoryName,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categoryTabs = [
    'All',
    'Milk',
    'Curd',
    'Paneer',
    'Ghee',
    'Oils',
    'Masalas',
    'Vegan',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.categoryName != null) {
        ref.read(productProvider.notifier).setCategory(widget.categoryName!);
      }
      if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
        _searchController.text = widget.initialSearchQuery!;
        ref.read(productProvider.notifier).setSearchQuery(widget.initialSearchQuery!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currentSort = ref.watch(productProvider).sortBy;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort Products By', style: AppTypography.titleLarge),
              const SizedBox(height: 14),
              RadioGroup<String>(
                groupValue: currentSort,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(productProvider.notifier).setSortBy(val);
                    Navigator.pop(context);
                  }
                },
                child: Column(
                  children: const [
                    RadioListTile<String>(
                      title: Text('Popular / Featured'),
                      value: 'popular',
                    ),
                    RadioListTile<String>(
                      title: Text('Price: Low to High'),
                      value: 'price_asc',
                    ),
                    RadioListTile<String>(
                      title: Text('Price: High to Low'),
                      value: 'price_desc',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final categoryState = ref.watch(categoryProvider);
    final products = productState.filteredProducts;
    final tabs = categoryState.categories.isNotEmpty
        ? ['All', ...categoryState.categories.map((c) => c.name)]
        : _categoryTabs;

    final title = widget.categoryName != null
        ? '${widget.categoryName} Products'
        : (productState.selectedCategory != 'All'
            ? '${productState.selectedCategory} Products'
            : 'Dairy Products');

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textDark),
            onPressed: _showSortDialog,
          ),
          Consumer(
            builder: (context, ref, _) {
              final cartCount = ref.watch(cartProvider).totalItemCount;
              return IconButton(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  backgroundColor: AppColors.cancelled,
                  label: Text(
                    '$cartCount',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined, color: AppColors.forestGreen),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row (Mockup Screen 6: All, Milk, Curd, Paneer, Butter)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  final isSelected = productState.selectedCategory.toLowerCase() == tab.toLowerCase();

                  return ChoiceChip(
                    label: Text(tab),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(productProvider.notifier).setCategory(tab);
                    },
                    selectedColor: AppColors.forestGreen,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.forestGreen : AppColors.border,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  );
                },
              ),
            ),
          ),

          // Products Grid
          Expanded(
            child: productState.isLoading && products.isEmpty
                ? const LoadingIndicator(message: 'Loading products...')
                : products.isEmpty
                    ? EmptyStateView(
                        title: 'No Products Found',
                        message: 'Try adjusting your search query or category filter.',
                        emoji: '🔍',
                        buttonText: 'Reset Filters',
                        onButtonPressed: () {
                          _searchController.clear();
                          ref.read(productProvider.notifier).setCategory('All');
                          ref.read(productProvider.notifier).setSearchQuery('');
                        },
                      )
                    : RefreshIndicator(
                        color: AppColors.forestGreen,
                        onRefresh: () => ref.read(productProvider.notifier).fetchProducts(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            return ProductCard(product: products[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
