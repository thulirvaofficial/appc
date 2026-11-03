import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
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
    fetchPlans();
    fetchSubscriptions();
  }

  Future<void> fetchPlans() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.subscriptionPlans);
      final data = res.data;

      if (data['success'] == true && data['plans'] != null) {
        final list = (data['plans'] as List)
            .map((p) => SubscriptionPlanModel.fromJson(p as Map<String, dynamic>))
            .toList();
        state = state.copyWith(plans: list);
      }
    } catch (_) {}
  }

  Future<void> fetchSubscriptions() async {
    final user = ref.read(authProvider).user;
    final ident = user?.id?.toString() ?? user?.email ?? '1';

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('${ApiEndpoints.userSubscriptions}/$ident');
      final data = res.data;

      if (data['success'] == true && data['subscriptions'] != null) {
        final list = (data['subscriptions'] as List)
            .map((s) => SubscriptionModel.fromJson(s as Map<String, dynamic>))
            .toList();
        state = state.copyWith(subscriptions: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createSubscription(Map<String, dynamic> payload) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(ApiEndpoints.subscriptions, data: payload);
      final data = res.data;

      if (data['success'] == true && data['subscription'] != null) {
        final newSub = SubscriptionModel.fromJson(data['subscription'] as Map<String, dynamic>);
        state = state.copyWith(
          subscriptions: [newSub, ...state.subscriptions],
          isSubmitting: false,
        );
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
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref);
});

