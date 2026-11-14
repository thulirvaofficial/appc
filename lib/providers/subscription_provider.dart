import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/storage/storage_service.dart';
import '../data/models/subscription_model.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class SubscriptionState {
  final List<SubscriptionModel> subscriptions;
  final List<SubscriptionPlanModel> plans;
  final bool isLoading;
  final String? errorMessage;
  final bool isSubmitting;

  SubscriptionState({
    this.subscriptions = const [],
    this.plans = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isSubmitting = false,
  });

  List<SubscriptionModel> get activeSubscriptions =>
      subscriptions.where((s) => s.status.toLowerCase() == 'active').toList();

  SubscriptionState copyWith({
    List<SubscriptionModel>? subscriptions,
    List<SubscriptionPlanModel>? plans,
    bool? isLoading,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return SubscriptionState(
      subscriptions: subscriptions ?? this.subscriptions,
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final Ref ref;

  SubscriptionNotifier(this.ref) : super(SubscriptionState()) {
    _loadCachedSubscriptions();
    fetchPlans();
    fetchSubscriptions();

    // Re-fetch subscriptions whenever user auth changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id || (previous?.user == null && next.user != null)) {
        fetchSubscriptions();
      }
    });
  }

  void resetState() {
    state = state.copyWith(subscriptions: [], isLoading: false, errorMessage: null);
  }

  void _loadCachedSubscriptions([String? userId]) {
    try {
      final cached = StorageService.getSubscriptions(userId: userId);
      if (cached.isNotEmpty) {
        final list = cached.map((json) => SubscriptionModel.fromJson(json)).toList();
        state = state.copyWith(subscriptions: list);
      } else {
        state = state.copyWith(subscriptions: []);
      }
    } catch (_) {}
  }

  Future<void> fetchPlans() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.subscriptionPlans);
      final data = res.data;

      if (data is Map && data['success'] == true && data['plans'] != null) {
        final list = (data['plans'] as List)
            .map((p) => SubscriptionPlanModel.fromJson(p as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          state = state.copyWith(plans: list, isLoading: false);
          return;
        }
      }
    } catch (_) {}

    // Real live seed fallback matching website database
    final fallback = [
      SubscriptionPlanModel(
        id: 1,
        productId: 1,
        productName: 'Fresh Cow Milk (500ml)',
        productImage: '/assets/images/products/fresh_cow_milk.jpg',
        timePeriod: 'Daily Morning (30 Days)',
        frequency: 'Daily',
        durationDays: 30,
        price: 1320,
        originalPrice: 1500,
        discountPercent: 12,
        description: 'Pure farm fresh cow milk delivered to your doorstep every morning before 7:00 AM. 100% natural, unadulterated.',
        badge: 'Most Popular',
      ),
      SubscriptionPlanModel(
        id: 2,
        productId: 5,
        productName: 'Fresh Cow Milk (1 Litre)',
        productImage: '/assets/images/products/fresh_cow_milk.jpg',
        timePeriod: 'Daily Morning (30 Days)',
        frequency: 'Daily',
        durationDays: 30,
        price: 2460,
        originalPrice: 2700,
        discountPercent: 9,
        description: '1 Litre family pack chilled cow milk delivered every single morning. Glass-bottle hygiene guaranteed.',
        badge: 'Family Pack',
      ),
      SubscriptionPlanModel(
        id: 3,
        productId: 1,
        productName: 'Fresh Cow Milk (500ml)',
        productImage: '/assets/images/products/fresh_cow_milk.jpg',
        timePeriod: 'Alternate Days (15 Days)',
        frequency: 'Alternate',
        durationDays: 30,
        price: 660,
        originalPrice: 750,
        discountPercent: 12,
        description: 'Delivered every alternate day. Perfect for light households or couples wanting regular fresh milk.',
        badge: 'Flexible Plan',
      ),
      SubscriptionPlanModel(
        id: 4,
        productId: 3,
        productName: 'Fresh Artisanal Paneer (200g)',
        productImage: '/assets/images/products/fresh_paneer.jpg',
        timePeriod: 'Twice a Week (8 Deliveries)',
        frequency: 'Twice Weekly',
        durationDays: 30,
        price: 656,
        originalPrice: 760,
        discountPercent: 14,
        description: 'Ultra-soft chemical-free cottage cheese delivered every Wednesday and Saturday morning.',
        badge: 'Fresh Batch',
      ),
      SubscriptionPlanModel(
        id: 5,
        productId: 2,
        productName: 'Pure Bilona Cow Ghee (500ml)',
        productImage: '/assets/images/products/pure_cow_ghee.jpg',
        timePeriod: 'Monthly Delivery (1 Jar/Month)',
        frequency: 'Monthly',
        durationDays: 30,
        price: 499,
        originalPrice: 600,
        discountPercent: 17,
        description: 'A fresh 500ml jar of fragrant Bilona churned golden ghee dispatched automatically on the 1st of every month.',
        badge: 'Pure Bilona',
      ),
      SubscriptionPlanModel(
        id: 6,
        productId: 4,
        productName: 'Natural Thick Set Curd (500g)',
        productImage: '/assets/images/products/product_lineup.jpg',
        timePeriod: 'Daily Morning (30 Days)',
        frequency: 'Daily',
        durationDays: 30,
        price: 1440,
        originalPrice: 1650,
        discountPercent: 13,
        description: 'Probiotic rich, smooth thick curd prepared every night and delivered fresh with morning milk.',
        badge: 'Probiotic',
      ),
    ];
    state = state.copyWith(plans: fallback, isLoading: false);
  }

  Future<void> fetchSubscriptions({String? explicitIdent}) async {
    final authUser = ref.read(authProvider).user;
    final cachedUser = StorageService.getUser();

    final currentUserId = authUser?.id?.toString() ?? cachedUser?['id']?.toString();
    final ident = explicitIdent ??
        currentUserId ??
        authUser?.phone ??
        cachedUser?['phone']?.toString() ??
        authUser?.email ??
        cachedUser?['email']?.toString();

    if (ident == null || ident.isEmpty) {
      state = state.copyWith(subscriptions: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiEndpoints.userSubscriptions}/$ident');
      final data = res.data;

      if (data is Map && data['success'] == true && data['subscriptions'] != null) {
        final list = (data['subscriptions'] as List)
            .map((s) => SubscriptionModel.fromJson(s as Map<String, dynamic>))
            .toList();

        await StorageService.saveSubscriptions(
          list.map((s) => s.toJson()).toList(),
          userId: currentUserId,
        );
        state = state.copyWith(subscriptions: list, isLoading: false);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SUBSCRIPTION FETCH ERROR]: $e');
      }
    }

    _loadCachedSubscriptions(currentUserId);
    state = state.copyWith(isLoading: false);
  }

  Future<bool> createSubscription(Map<String, dynamic> payload) async {
    if (state.isSubmitting) {
      if (kDebugMode) {
        print('[SUBSCRIPTION PROVIDER]: Ignored duplicate submission - isSubmitting is already active');
      }
      return false;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(ApiEndpoints.subscriptions, data: payload);
      final data = res.data;

      if (data['success'] == true && data['subscription'] != null) {
        final newSub = SubscriptionModel.fromJson(data['subscription'] as Map<String, dynamic>);
        final updatedList = [newSub, ...state.subscriptions.where((s) => s.id != newSub.id)];
        await StorageService.saveSubscriptions(updatedList.map((s) => s.toJson()).toList());
        state = state.copyWith(
          subscriptions: updatedList,
          isSubmitting: false,
        );
        fetchSubscriptions();
        return true;
      }
      state = state.copyWith(isSubmitting: false, errorMessage: data['message'] ?? 'Failed to subscribe');
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateStatus(String subId, String newStatus) async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.put(
        '${ApiEndpoints.subscriptions}/$subId/status',
        data: {'status': newStatus},
      );

      if (res.data['success'] == true) {
        final updated = state.subscriptions.map((s) {
          if (s.id == subId) {
            final json = s.toJson();
            json['status'] = newStatus;
            return SubscriptionModel.fromJson(json);
          }
          return s;
        }).toList();
        state = state.copyWith(subscriptions: updated);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
  Future<bool> pauseSubscription(String subId) => updateStatus(subId, 'paused');
  Future<bool> resumeSubscription(String subId) => updateStatus(subId, 'active');
  Future<bool> cancelSubscription(String subId) => updateStatus(subId, 'cancelled');
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref);
});

