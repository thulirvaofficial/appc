import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../data/models/coupon_model.dart';
import 'api_provider.dart';

class CouponState {
  final List<CouponModel> coupons;
  final bool isLoading;

  CouponState({
    this.coupons = const [],
    this.isLoading = false,
  });

  CouponState copyWith({
    List<CouponModel>? coupons,
    bool? isLoading,
  }) {
    return CouponState(
      coupons: coupons ?? this.coupons,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CouponNotifier extends StateNotifier<CouponState> {
  final Ref ref;

  CouponNotifier(this.ref) : super(CouponState()) {
    fetchCoupons();
  }

  Future<void> fetchCoupons() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.coupons);
      final data = res.data;

      if (data['success'] == true && data['coupons'] != null) {
        final list = (data['coupons'] as List)
            .map((c) => CouponModel.fromJson(c as Map<String, dynamic>))
            .where((c) => c.status == 'active')
            .toList();
        state = state.copyWith(coupons: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final couponProvider = StateNotifierProvider<CouponNotifier, CouponState>((ref) {
  return CouponNotifier(ref);
});

