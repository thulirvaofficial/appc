import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../data/models/category_model.dart';
import 'api_provider.dart';

class CategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? errorMessage;
  final CategoryModel? selectedCategory;

  CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory,
  });

  CategoryState copyWith({
    List<CategoryModel>? categories,
    bool? isLoading,
    String? errorMessage,
    CategoryModel? selectedCategory,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final Ref ref;

  CategoryNotifier(this.ref) : super(CategoryState(isLoading: true)) {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.categories);
      final data = res.data;

      if (data is Map && data['success'] == true && data['categories'] != null) {
        final list = (data['categories'] as List)
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList();
        state = state.copyWith(categories: list, isLoading: false);
      } else if (data is List) {
        final list = data
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList();
        state = state.copyWith(categories: list, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No categories received',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to connect to server: $e',
      );
    }
  }

  void selectCategory(CategoryModel category) {
    state = state.copyWith(selectedCategory: category);
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(ref);
});
