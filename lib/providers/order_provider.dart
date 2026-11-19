import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/utils/safe_parse_util.dart';
import '../data/models/order_model.dart';
import '../data/models/subscription_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

enum CustomerOrderItemType { product, subscription }

class CustomerOrderFeedItem {
  final CustomerOrderItemType type;
  final OrderModel? productOrder;
  final SubscriptionModel? subscriptionOrder;
  final DateTime createdDateTime;

  CustomerOrderFeedItem.product(this.productOrder)
      : type = CustomerOrderItemType.product,
        subscriptionOrder = null,
        createdDateTime = productOrder?.createdDateTime ?? _parseDate(productOrder?.createdAt);

  CustomerOrderFeedItem.subscription(this.subscriptionOrder)
      : type = CustomerOrderItemType.subscription,
        productOrder = null,
        createdDateTime = subscriptionOrder?.createdDateTime ?? _parseDate(subscriptionOrder?.createdAt ?? subscriptionOrder?.startDate);

  static DateTime _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String get id => type == CustomerOrderItemType.product
      ? (productOrder?.orderId?.toString() ?? '')
      : (subscriptionOrder?.id ?? '');
}

class OrderState {
  final List<OrderModel> orders;
  final List<SubscriptionModel> subscriptions;
  final bool isLoading;
  final String? errorMessage;
  final String typeFilter; // 'all', 'product', 'subscription'
  final String selectedFilter; 
  final bool isPlacingOrder;

  OrderState({
    this.orders = const [],
    this.subscriptions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.typeFilter = 'all',
    this.selectedFilter = 'All',
    this.isPlacingOrder = false,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    List<SubscriptionModel>? subscriptions,
    bool? isLoading,
    String? errorMessage,
    String? typeFilter,
    String? selectedFilter,
    bool? isPlacingOrder,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      typeFilter: typeFilter ?? this.typeFilter,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
    );
  }

  int get allOrdersCount => orders.length + subscriptions.length;
  int get productOrdersCount => orders.length;
  int get subscriptionOrdersCount => subscriptions.length;

  List<CustomerOrderFeedItem> get filteredFeed {
    List<CustomerOrderFeedItem> feed = [];

    if (typeFilter == 'all') {
      feed = [
        ...orders.map(CustomerOrderFeedItem.product),
        ...subscriptions.map(CustomerOrderFeedItem.subscription),
      ];
      feed.sort((a, b) => b.createdDateTime.compareTo(a.createdDateTime));
    } else if (typeFilter == 'product') {
      feed = orders.map(CustomerOrderFeedItem.product).toList();
      feed.sort((a, b) => b.createdDateTime.compareTo(a.createdDateTime));
    } else if (typeFilter == 'subscription') {
      feed = subscriptions.map(CustomerOrderFeedItem.subscription).toList();
      feed.sort((a, b) => b.createdDateTime.compareTo(a.createdDateTime));
    }

    if (selectedFilter == 'All' || selectedFilter == 'All Orders') {
      feed.sort((a, b) => b.createdDateTime.compareTo(a.createdDateTime));
      return feed;
    }

    final f = selectedFilter.toLowerCase().replaceAll(' ', '_');
    final res = feed.where((item) {
      if (item.type == CustomerOrderItemType.product) {
        final s = item.productOrder!.orderStatus.toLowerCase().replaceAll(' ', '_');
        if (f == 'ready_for_pickup') return s == 'ready' || s == 'ready_for_pickup';
        if (f == 'out_for_delivery') return s == 'out_for_delivery' || s == 'shipped';
        return s == f;
      } else {
        final s = item.subscriptionOrder!.status.toLowerCase().replaceAll(' ', '_');
        final p = item.subscriptionOrder!.paymentStatus.toLowerCase().replaceAll(' ', '_');
        if (f == 'pending') return s == 'pending' || p == 'pending';
        if (f == 'active') return s == 'active';
        if (f == 'cancelled') return s == 'cancelled';
        if (f == 'delivered') return s == 'active';
        return s == f || p == f;
      }
    }).toList();
    res.sort((a, b) => b.createdDateTime.compareTo(a.createdDateTime));
    return res;
  }

  List<OrderModel> get filteredOrders {
    final productOrders = orders.where((o) =>
        o.deliveryType.toLowerCase() != 'subscription' &&
        !o.id.toString().toUpperCase().startsWith('SUB-') &&
        !(o.orderNumber?.toUpperCase().startsWith('SUB-') ?? false)).toList();

    productOrders.sort((a, b) => b.createdDateTime.compareTo(a.createdDateTime));

    if (selectedFilter == 'All' || selectedFilter == 'All Orders') return productOrders;
    final f = selectedFilter.toLowerCase().replaceAll(' ', '_');
    final res = productOrders.where((o) {
      final s = o.orderStatus.toLowerCase().replaceAll(' ', '_');
      if (f == 'ready_for_pickup') {
        return s == 'ready' || s == 'ready_for_pickup';
      }
      if (f == 'out_for_delivery') {
        return s == 'out_for_delivery' || s == 'shipped';
      }
      return s == f;
    }).toList();
    res.sort((a, b) => b.createdDateTime.compareTo(a.createdDateTime));
    return res;
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final Ref ref;

  OrderNotifier(this.ref) : super(OrderState()) {
    fetchOrders();

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id || (previous?.user == null && next.user != null)) {
        fetchOrders();
      }
    });
  }

  void resetState() {
    state = OrderState();
  }

  Future<void> fetchOrders() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      state = OrderState();
      return;
    }

    String ident = '';
    if (user.id != null && user.id.toString() != '0' && user.id.toString() != 'null' && user.id.toString().isNotEmpty) {
      ident = user.id.toString();
    } else if (user.email.isNotEmpty) {
      ident = user.email;
    } else if (user.phone != null && user.phone!.isNotEmpty) {
      ident = user.phone!;
    }

    if (ident.isEmpty) {
      state = OrderState();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);

      List<OrderModel> fetchedOrders = state.orders;
      List<SubscriptionModel> fetchedSubs = state.subscriptions;

      try {
        final ordersRes = await api.get('${ApiEndpoints.userOrders}/$ident');
        if (ordersRes.data != null && ordersRes.data['success'] == true && ordersRes.data['orders'] != null) {
          fetchedOrders = (ordersRes.data['orders'] as List)
              .map((o) => OrderModel.fromJson(o as Map<String, dynamic>))
              .where((o) =>
                  o.deliveryType.toLowerCase() != 'subscription' &&
                  !o.id.toString().toUpperCase().startsWith('SUB-') &&
                  !(o.orderNumber?.toUpperCase().startsWith('SUB-') ?? false))
              .toList();
          fetchedOrders.sort((a, b) => b.createdDateTime.compareTo(a.createdDateTime));
        }
      } catch (_) {}

      try {
        final subsRes = await api.get('${ApiEndpoints.userSubscriptions}/$ident');
        if (subsRes.data != null && subsRes.data['success'] == true && subsRes.data['subscriptions'] != null) {
          fetchedSubs = (subsRes.data['subscriptions'] as List)
              .map((s) => SubscriptionModel.fromJson(s as Map<String, dynamic>))
              .toList();
          fetchedSubs.sort((a, b) => (b.createdDateTime ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdDateTime ?? DateTime.fromMillisecondsSinceEpoch(0)));
        }
      } catch (_) {}

      state = state.copyWith(
        orders: fetchedOrders,
        subscriptions: fetchedSubs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setTypeFilter(String type) {
    state = state.copyWith(typeFilter: type);
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  Future<OrderModel?> fetchOrderTrackingDetails(String orderId) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiEndpoints.orders}/$orderId/tracking');
      if (res.data != null && res.data['success'] == true) {
        final data = res.data as Map<String, dynamic>;
        final partner = data['partner'] as Map<String, dynamic>?;
        final partnerLoc = data['partner_live_location'] as Map<String, dynamic>?;
        final dest = data['customer_destination'] as Map<String, dynamic>?;

        OrderModel? existing;
        for (final o in state.orders) {
          if (o.id.toString() == orderId || o.orderNumber == orderId) {
            existing = o;
            break;
          }
        }

        if (existing != null) {
          final updated = existing.copyWith(
            orderStatus: data['order_status']?.toString() ?? existing.orderStatus,
            partnerName: partner?['name']?.toString() ?? existing.partnerName,
            partnerPhone: partner?['phone']?.toString() ?? existing.partnerPhone,
            partnerPhoto: partner?['photo_url']?.toString() ?? existing.partnerPhoto,
            partnerVehicle: partner?['vehicle_type']?.toString() ?? existing.partnerVehicle,
            partnerRating: partner?['rating'] != null ? SafeParseUtil.toDouble(partner!['rating']) : existing.partnerRating,
            partnerLatitude: partnerLoc?['latitude'] != null ? SafeParseUtil.toDouble(partnerLoc!['latitude']) : existing.partnerLatitude,
            partnerLongitude: partnerLoc?['longitude'] != null ? SafeParseUtil.toDouble(partnerLoc!['longitude']) : existing.partnerLongitude,
            latitude: dest?['latitude'] != null ? SafeParseUtil.toDouble(dest!['latitude']) : existing.latitude,
            longitude: dest?['longitude'] != null ? SafeParseUtil.toDouble(dest!['longitude']) : existing.longitude,
          );
          return updated;
        }
      }
    } catch (_) {}
    return fetchOrderDetails(orderId);
  }

  Future<OrderModel?> fetchOrderDetails(String orderId) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiEndpoints.orders}/$orderId');
      if (res.data != null && res.data['success'] == true && res.data['order'] != null) {
        final fresh = OrderModel.fromJson(res.data['order'] as Map<String, dynamic>);
        final updated = state.orders.map((o) => (o.id.toString() == orderId || o.orderNumber == orderId) ? fresh : o).toList();
        state = state.copyWith(orders: updated);
        return fresh;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> rateOrder({
    required String orderId,
    required int rating,
    String feedback = '',
    List<String> tags = const [],
  }) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(
        '${ApiEndpoints.orders}/$orderId/rate',
        data: {
          'rating': rating,
          'feedback': feedback,
          'tags': tags,
        },
      );
      if (res.data != null && res.data['success'] == true) {
        final updatedOrders = state.orders.map((o) {
          if (o.id.toString() == orderId.toString() || o.orderNumber == orderId) {
            return o.copyWith(rating: rating.toDouble(), feedback: feedback);
          }
          return o;
        }).toList();
        state = state.copyWith(orders: updatedOrders);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reportOrderIssue({
    required String orderId,
    required String issueType,
    String notes = '',
  }) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(
        '${ApiEndpoints.orders}/$orderId/issues',
        data: {
          'issue_type': issueType,
          'notes': notes,
        },
      );
      return res.data != null && res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchDeliveryProofDetails(String orderId) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiEndpoints.orders}/$orderId/delivery-details');
      if (res.data != null && res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['data'] ?? {});
      }
    } catch (_) {}
    return null;
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
          orders: [newOrder, ...state.orders.where((o) => o.id != newOrder.id)],
          isPlacingOrder: false,
        );
        fetchOrders();
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

