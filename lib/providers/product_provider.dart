import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../data/models/product_model.dart';
import 'api_provider.dart';

class ProductState {
  final List<ProductModel> allProducts;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategory;
  final String searchQuery;
  final String sortBy; // 'popular', 'price_asc', 'price_desc'

  ProductState({
    this.allProducts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.sortBy = 'popular',
  });

  ProductState copyWith({
    List<ProductModel>? allProducts,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
    String? searchQuery,
    String? sortBy,
  }) {
    return ProductState(
      allProducts: allProducts ?? this.allProducts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  List<ProductModel> get filteredProducts {
    List<ProductModel> list = [...allProducts];

    // Category filter
    if (selectedCategory != 'All') {
      final catLower = selectedCategory.toLowerCase();
      list = list.where((p) {
        final pCat = p.category.toLowerCase();
        final pCatName = (p.categoryName ?? '').toLowerCase();
        return pCat == catLower || pCatName.contains(catLower) || catLower.contains(pCat);
      }).toList();
    }

    // Search query filter
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final descMatch = (p.description ?? '').toLowerCase().contains(q);
        final catMatch = p.category.toLowerCase().contains(q);
        return nameMatch || descMatch || catMatch;
      }).toList();
    }

    // Sorting
    if (sortBy == 'price_asc') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (sortBy == 'price_desc') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }

    return list;
  }

  List<ProductModel> get featuredProducts {
    return allProducts.take(6).toList();
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final Ref ref;

  ProductNotifier(this.ref) : super(ProductState(isLoading: true)) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.products);
      final data = res.data;

      if (data is Map && data['success'] == true && data['products'] != null) {
        final list = (data['products'] as List)
            .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
            .toList();
        state = state.copyWith(allProducts: list, isLoading: false);
      } else if (data is List) {
        final list = data
            .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
            .toList();
        state = state.copyWith(allProducts: list, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No products received',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to connect to server: $e',
      );
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortBy(String sort) {
    state = state.copyWith(sortBy: sort);
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(ref);
});
