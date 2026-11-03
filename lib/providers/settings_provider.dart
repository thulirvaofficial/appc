import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import 'api_provider.dart';

class StoreSettingsState {
  final bool isPickupOnly;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String storeTimings;
  final String pickupInstructions;
  final bool isLoading;

  const StoreSettingsState({
    this.isPickupOnly = false,
    this.storeName = 'THULIRVA Farm Store',
    this.storeAddress = 'No 1, Mayana Salai, Thimmarajampettai, Kanchipuram - 631601, Tamil Nadu',
    this.storePhone = '+91 93606 71533',
    this.storeTimings = '7:00 AM – 8:00 PM (All 7 Days)',
    this.pickupInstructions = 'Collect directly from the farm store with order ID.',
    this.isLoading = false,
  });

  StoreSettingsState copyWith({
    bool? isPickupOnly,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? storeTimings,
    String? pickupInstructions,
    bool? isLoading,
  }) {
    return StoreSettingsState(
      isPickupOnly: isPickupOnly ?? this.isPickupOnly,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      storeTimings: storeTimings ?? this.storeTimings,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StoreSettingsNotifier extends StateNotifier<StoreSettingsState> {
  final Ref ref;

  StoreSettingsNotifier(this.ref) : super(const StoreSettingsState()) {
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.storeSettings);
      final data = res.data;

      if (data is Map && data['success'] == true && data['settings'] != null) {
        final s = data['settings'] as Map<String, dynamic>;
        state = state.copyWith(
          isPickupOnly: s['pickup_mode'] == true,
          storeName: s['store_name'] ?? state.storeName,
          storeAddress: s['store_address'] ?? state.storeAddress,
          storePhone: s['store_phone'] ?? state.storePhone,
          storeTimings: s['store_timings'] ?? state.storeTimings,
          pickupInstructions: s['pickup_instructions'] ?? state.pickupInstructions,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final settingsProvider = StateNotifierProvider<StoreSettingsNotifier, StoreSettingsState>((ref) {
  return StoreSettingsNotifier(ref);
});
