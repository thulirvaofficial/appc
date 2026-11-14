import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../data/models/coupon_model.dart';
import 'api_provider.dart';

class CouponState {
  final List<CouponModel> coupons;
  final bool isLoading;
  final String? errorMessage;

  CouponState({
    this.coupons = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CouponState copyWith({
    List<CouponModel>? coupons,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CouponState(
      coupons: coupons ?? this.coupons,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CouponNotifier extends StateNotifier<CouponState> {
  final Ref ref;

  CouponNotifier(this.ref) : super(CouponState()) {
    fetchCoupons();
  }

  void resetState() {
    state = CouponState();
  }

  Future<void> fetchCoupons() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.coupons).timeout(const Duration(seconds: 10));
      final data = res.data;

      if (data is Map && data['success'] == true && data['coupons'] != null) {
        final list = (data['coupons'] as List)
            .map((c) => CouponModel.fromJson(c as Map<String, dynamic>))
            .where((c) => c.status == 'active')
            .toList();
        state = state.copyWith(coupons: list, isLoading: false, errorMessage: null);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'No active coupons available');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to connect. Please check network and retry.');
    }
  }
}

final couponProvider = StateNotifierProvider<CouponNotifier, CouponState>((ref) {
  return CouponNotifier(ref);
});
