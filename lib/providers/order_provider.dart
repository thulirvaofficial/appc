import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../data/models/order_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class OrderState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? errorMessage;
  final String selectedFilter; // 'All', 'Processing', 'Shipped', 'Delivered', 'Cancelled'
  final bool isPlacingOrder;

  OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter = 'All',
    this.isPlacingOrder = false,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? errorMessage,
    String? selectedFilter,
    bool? isPlacingOrder,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
    );
  }

  List<OrderModel> get filteredOrders {
    if (selectedFilter == 'All') return orders;
    final f = selectedFilter.toLowerCase();
    return orders.where((o) => o.orderStatus.toLowerCase() == f).toList();
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final Ref ref;

  OrderNotifier(this.ref) : super(OrderState()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final user = ref.read(authProvider).user;
    final ident = user?.id?.toString() ?? user?.email ?? '1';

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiEndpoints.userOrders}/$ident');
      final data = res.data;

      if (data['success'] == true && data['orders'] != null) {
        final list = (data['orders'] as List)
            .map((o) => OrderModel.fromJson(o as Map<String, dynamic>))
            .toList();
        state = state.copyWith(orders: list, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to load orders',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<OrderModel?> placeOrder(Map<String, dynamic> payload) async {
    state = state.copyWith(isPlacingOrder: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(ApiEndpoints.orders, data: payload);
      final data = res.data;

      if (data['success'] == true && data['order'] != null) {
        final newOrder = OrderModel.fromJson(data['order'] as Map<String, dynamic>);
        state = state.copyWith(
          orders: [newOrder, ...state.orders],
          isPlacingOrder: false,
        );
        return newOrder;
      } else {
        state = state.copyWith(
          isPlacingOrder: false,
          errorMessage: data['message'] ?? 'Failed to place order',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isPlacingOrder: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref);
});

