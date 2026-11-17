import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import 'api_provider.dart';

class BusinessConfigState {
  // Delivery Charges
  final bool deliveryChargesEnabled;
  final double fixedDeliveryCharge;
  final double freeDeliveryThreshold;
  final bool distanceChargesEnabled;
  final double distanceBaseKm;
  final double distanceRatePerKm;
  final int geofenceRadiusMeters;

  // Delivery Availability
  final bool isDeliveryAvailable;
  final bool isAdvanceOrder;
  final String deliveryMode;
  final String availabilityMessage;
  final String nextAvailableTime;
  final bool canOrder;

  // Dynamic Payment QR
  final String upiId;
  final String merchantName;
  final String qrImageUrl;
  final bool isQrActive;
  final int qrVersion;

  // Master Cash on Delivery (COD) Switch
  final bool codEnabled;

  // Dynamic Launch Banner
  final bool bannerEnabled;
  final String bannerHeadline;
  final String bannerSubtitle;
  final String bannerBgColor;
  final String bannerImageUrl;

  final bool isLoading;

  const BusinessConfigState({
    this.deliveryChargesEnabled = true,
    this.fixedDeliveryCharge = 30.0,
    this.freeDeliveryThreshold = 299.0,
    this.distanceChargesEnabled = false,
    this.distanceBaseKm = 5.0,
    this.distanceRatePerKm = 10.0,
    this.geofenceRadiusMeters = 100,
    this.isDeliveryAvailable = true,
    this.isAdvanceOrder = false,
    this.deliveryMode = 'morning_evening',
    this.availabilityMessage = '',
    this.nextAvailableTime = '',
    this.canOrder = true,
    this.upiId = '7904880944@superyes',
    this.merchantName = 'THULIRVA ORGANICS',
    this.qrImageUrl = '',
    this.isQrActive = true,
    this.qrVersion = 1,
    this.codEnabled = true,
    this.bannerEnabled = false,
    this.bannerHeadline = '',
    this.bannerSubtitle = '',
    this.bannerBgColor = '#1B4332',
    this.bannerImageUrl = '',
    this.isLoading = false,
  });

  /// Authoritative client calculation adhering to backend rule
  double calculateDeliveryFee({required double subtotal, bool isPickup = false}) {
    if (isPickup) return 0.0;
    if (!deliveryChargesEnabled) return 0.0;
    if (subtotal <= 0.0) return 0.0;
    if (subtotal >= freeDeliveryThreshold) return 0.0;
    return fixedDeliveryCharge;
  }

  BusinessConfigState copyWith({
    bool? deliveryChargesEnabled,
    double? fixedDeliveryCharge,
    double? freeDeliveryThreshold,
    bool? distanceChargesEnabled,
    double? distanceBaseKm,
    double? distanceRatePerKm,
    int? geofenceRadiusMeters,
    bool? isDeliveryAvailable,
    bool? isAdvanceOrder,
    String? deliveryMode,
    String? availabilityMessage,
    String? nextAvailableTime,
    bool? canOrder,
    String? upiId,
    String? merchantName,
    String? qrImageUrl,
    bool? isQrActive,
    int? qrVersion,
    bool? codEnabled,
    bool? bannerEnabled,
    String? bannerHeadline,
    String? bannerSubtitle,
    String? bannerBgColor,
    String? bannerImageUrl,
    bool? isLoading,
  }) {
    return BusinessConfigState(
      deliveryChargesEnabled: deliveryChargesEnabled ?? this.deliveryChargesEnabled,
      fixedDeliveryCharge: fixedDeliveryCharge ?? this.fixedDeliveryCharge,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      distanceChargesEnabled: distanceChargesEnabled ?? this.distanceChargesEnabled,
      distanceBaseKm: distanceBaseKm ?? this.distanceBaseKm,
      distanceRatePerKm: distanceRatePerKm ?? this.distanceRatePerKm,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      isDeliveryAvailable: isDeliveryAvailable ?? this.isDeliveryAvailable,
      isAdvanceOrder: isAdvanceOrder ?? this.isAdvanceOrder,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      availabilityMessage: availabilityMessage ?? this.availabilityMessage,
      nextAvailableTime: nextAvailableTime ?? this.nextAvailableTime,
      canOrder: canOrder ?? this.canOrder,
      upiId: upiId ?? this.upiId,
      merchantName: merchantName ?? this.merchantName,
      qrImageUrl: qrImageUrl ?? this.qrImageUrl,
      isQrActive: isQrActive ?? this.isQrActive,
      qrVersion: qrVersion ?? this.qrVersion,
      codEnabled: codEnabled ?? this.codEnabled,
      bannerEnabled: bannerEnabled ?? this.bannerEnabled,
      bannerHeadline: bannerHeadline ?? this.bannerHeadline,
      bannerSubtitle: bannerSubtitle ?? this.bannerSubtitle,
      bannerBgColor: bannerBgColor ?? this.bannerBgColor,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BusinessConfigNotifier extends StateNotifier<BusinessConfigState> {
  final Ref ref;

  BusinessConfigNotifier(this.ref) : super(const BusinessConfigState()) {
    refreshAll();
  }

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true);
    await Future.wait([
      fetchDeliveryConfig(),
      fetchCodConfig(),
      fetchPaymentQr(),
      fetchLaunchBanner(),
    ]);
    state = state.copyWith(isLoading: false);
  }

  Future<void> fetchCodConfig() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.codConfig);
      if (res.data != null && res.data['success'] == true) {
        state = state.copyWith(
          codEnabled: res.data['cod_enabled'] ?? state.codEnabled,
        );
      }
    } catch (e) {
      debugPrint('[BusinessConfig] Error fetching COD config: $e');
    }
  }

  Future<void> fetchDeliveryConfig() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.deliveryConfig);
      if (res.data != null && res.data['success'] == true) {
        final cfg = res.data['config'] as Map<String, dynamic>?;
        final avail = res.data['availability'] as Map<String, dynamic>?;

        state = state.copyWith(
          deliveryChargesEnabled: cfg?['delivery_charges_enabled'] ?? state.deliveryChargesEnabled,
          fixedDeliveryCharge: (cfg?['fixed_delivery_charge'] != null)
              ? (cfg!['fixed_delivery_charge'] as num).toDouble()
              : state.fixedDeliveryCharge,
          freeDeliveryThreshold: (cfg?['free_delivery_threshold'] != null)
              ? (cfg!['free_delivery_threshold'] as num).toDouble()
              : state.freeDeliveryThreshold,
          distanceChargesEnabled: cfg?['distance_charges_enabled'] ?? state.distanceChargesEnabled,
          distanceBaseKm: (cfg?['distance_base_km'] != null)
              ? (cfg!['distance_base_km'] as num).toDouble()
              : state.distanceBaseKm,
          distanceRatePerKm: (cfg?['distance_rate_per_km'] != null)
              ? (cfg!['distance_rate_per_km'] as num).toDouble()
              : state.distanceRatePerKm,
          geofenceRadiusMeters: (cfg?['geofence_radius_meters'] != null)
              ? (cfg!['geofence_radius_meters'] as num).toInt()
              : state.geofenceRadiusMeters,
          isDeliveryAvailable: avail?['is_available'] ?? avail?['available'] ?? state.isDeliveryAvailable,
          isAdvanceOrder: avail?['is_advance_order'] ?? state.isAdvanceOrder,
          deliveryMode: avail?['mode'] ?? cfg?['delivery_mode'] ?? state.deliveryMode,
          availabilityMessage: avail?['message'] ?? state.availabilityMessage,
          nextAvailableTime: avail?['next_available_time'] ?? avail?['current_slot'] ?? state.nextAvailableTime,
          canOrder: avail?['can_order'] ?? state.canOrder,
        );
      }
    } catch (e) {
      debugPrint('[BusinessConfig] Error fetching delivery config: $e');
    }
  }

  Future<void> fetchPaymentQr() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.paymentQr);
      if (res.data != null && res.data['success'] == true && res.data['qr'] != null) {
        final qr = res.data['qr'] as Map<String, dynamic>;
        state = state.copyWith(
          upiId: qr['upi_id'] ?? state.upiId,
          merchantName: qr['merchant_name'] ?? state.merchantName,
          qrImageUrl: qr['qr_image_url'] ?? state.qrImageUrl,
          isQrActive: qr['is_active'] ?? state.isQrActive,
          qrVersion: (qr['version'] != null) ? (qr['version'] as num).toInt() : state.qrVersion,
        );
      }
    } catch (e) {
      debugPrint('[BusinessConfig] Error fetching payment QR: $e');
    }
  }

  Future<void> fetchLaunchBanner() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get(ApiEndpoints.launchBanner);
      if (res.data != null && res.data['success'] == true) {
        final b = res.data['banner'] as Map<String, dynamic>?;
        if (b != null && b['enabled'] == true) {
          state = state.copyWith(
            bannerEnabled: true,
            bannerHeadline: b['headline'] ?? '',
            bannerSubtitle: b['subtitle'] ?? '',
            bannerBgColor: b['bg_color'] ?? b['background_color'] ?? '#1B4332',
            bannerImageUrl: b['image_url'] ?? '',
          );
          return;
        }
      }
      state = state.copyWith(
        bannerEnabled: false,
        bannerHeadline: '',
        bannerSubtitle: '',
        bannerImageUrl: '',
      );
    } catch (e) {
      debugPrint('[BusinessConfig] Error fetching launch banner: $e');
      state = state.copyWith(
        bannerEnabled: false,
        bannerHeadline: '',
        bannerSubtitle: '',
        bannerImageUrl: '',
      );
    }
  }
}

final businessConfigProvider =
    StateNotifierProvider<BusinessConfigNotifier, BusinessConfigState>((ref) {
  return BusinessConfigNotifier(ref);
});

