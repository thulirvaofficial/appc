import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/storage/storage_service.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import 'api_provider.dart';
import 'business_config_provider.dart';
import 'settings_provider.dart';

class CartState {
  final List<CartItemModel> items;
  final double discountAmount;
  final String? appliedCouponCode;
  final String? couponMessage;
  final bool isApplyingCoupon;
  final bool isPickupOnly;
  final double fixedDeliveryCharge;
  final double freeDeliveryThreshold;
  final bool deliveryChargesEnabled;

  CartState({
    this.items = const [],
    this.discountAmount = 0.0,
    this.appliedCouponCode,
    this.couponMessage,
    this.isApplyingCoupon = false,
    this.isPickupOnly = false,
    this.fixedDeliveryCharge = 30.0,
    this.freeDeliveryThreshold = 299.0,
    this.deliveryChargesEnabled = true,
  });

  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);

  double get deliveryCharge {
    if (isPickupOnly) return 0.0;
    if (!deliveryChargesEnabled) return 0.0;
    if (subtotal == 0.0) return 0.0;
    return (subtotal >= freeDeliveryThreshold) ? 0.0 : fixedDeliveryCharge;
  }

  double get grandTotal {
    final raw = subtotal - discountAmount + deliveryCharge;
    return raw > 0.0 ? raw : 0.0;
  }

  CartState copyWith({
    List<CartItemModel>? items,
    double? discountAmount,
    String? appliedCouponCode,
    String? couponMessage,
    bool? isApplyingCoupon,
    bool? isPickupOnly,
    double? fixedDeliveryCharge,
    double? freeDeliveryThreshold,
    bool? deliveryChargesEnabled,
  }) {
    return CartState(
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      appliedCouponCode: appliedCouponCode ?? this.appliedCouponCode,
      couponMessage: couponMessage ?? this.couponMessage,
      isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
      isPickupOnly: isPickupOnly ?? this.isPickupOnly,
      fixedDeliveryCharge: fixedDeliveryCharge ?? this.fixedDeliveryCharge,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      deliveryChargesEnabled: deliveryChargesEnabled ?? this.deliveryChargesEnabled,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;

  CartNotifier(this.ref) : super(CartState()) {
    final biz = ref.read(businessConfigProvider);
    state = state.copyWith(
      fixedDeliveryCharge: biz.fixedDeliveryCharge,
      freeDeliveryThreshold: biz.freeDeliveryThreshold,
      deliveryChargesEnabled: biz.deliveryChargesEnabled,
    );
    _loadCart();

    // Listen to business configuration updates
    ref.listen<BusinessConfigState>(businessConfigProvider, (prev, next) {
      if (next.fixedDeliveryCharge != state.fixedDeliveryCharge ||
          next.freeDeliveryThreshold != state.freeDeliveryThreshold ||
          next.deliveryChargesEnabled != state.deliveryChargesEnabled) {
        state = state.copyWith(
          fixedDeliveryCharge: next.fixedDeliveryCharge,
          freeDeliveryThreshold: next.freeDeliveryThreshold,
          deliveryChargesEnabled: next.deliveryChargesEnabled,
        );
      }
    });

    // Listen to store settings pickup mode
    ref.listen<StoreSettingsState>(settingsProvider, (prev, next) {
      if (next.isPickupOnly != state.isPickupOnly) {
        state = state.copyWith(isPickupOnly: next.isPickupOnly);
      }
    });
  }

  String? _getCurrentUserId() {
    final user = StorageService.getUser();
    return user?['id']?.toString();
  }

  void _loadCart({String? userId}) {
    final effectiveUid = userId ?? _getCurrentUserId();
    final saved = StorageService.getCart(userId: effectiveUid);
    if (saved.isNotEmpty) {
      try {
        final list = saved.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return CartItemModel.fromJson(map);
        }).toList();
        state = state.copyWith(items: list);
        return;
      } catch (_) {}
    }
    state = state.copyWith(items: []);
  }

  void _saveCart() {
    final uid = _getCurrentUserId();
    StorageService.saveCart(state.items.map((i) => i.toJson()).toList(), userId: uid);
  }

  void loadUserCart(String? userId) {
    _loadCart(userId: userId);
  }

  void clearCart() {
    final uid = _getCurrentUserId();
    StorageService.deleteCart(userId: uid);
    state = state.copyWith(
      items: const [],
      discountAmount: 0.0,
      appliedCouponCode: null,
      couponMessage: null,
    );
  }

  void resetState() {
    clearCart();
  }

  int getProductQuantity(dynamic productId) {
    final targetId = productId.toString();
    for (final item in state.items) {
      if (item.product.id.toString() == targetId) {
        return item.quantity;
      }
    }
    return 0;
  }

  void addToCart(ProductModel product, {int quantity = 1, String? variant, ProductVariantModel? variantModel}) {
    final list = [...state.items];
    final targetId = product.id.toString();
    final effectiveVariantName = variantModel?.name ?? variant ?? (product.variants.isNotEmpty ? product.defaultVariant?.name : null);
    final effectivePrice = variantModel?.price ?? (variantModel != null ? variantModel.price : product.price);

    final idx = list.indexWhere((i) => i.product.id.toString() == targetId && i.selectedVariant == effectiveVariantName);

    if (idx != -1) {
      final existing = list[idx];
      list[idx] = CartItemModel(
        product: existing.product,
        quantity: existing.quantity + quantity,
        selectedVariant: existing.selectedVariant,
        variant: variantModel ?? existing.variant,
        overridePrice: effectivePrice,
      );
    } else {
      list.add(CartItemModel(
        product: product,
        quantity: quantity,
        selectedVariant: effectiveVariantName,
        variant: variantModel,
        overridePrice: effectivePrice,
      ));
    }

    state = state.copyWith(items: list);
    _saveCart();
    _revalidateCouponSilently();
  }

  void updateQuantity(dynamic productId, int newQuantity, {String? variant}) {
    final targetId = productId.toString();
    if (newQuantity <= 0) {
      removeFromCart(targetId, variant: variant);
      return;
    }

    final list = [...state.items];
    final idx = list.indexWhere((i) => i.product.id.toString() == targetId && i.selectedVariant == variant);

    if (idx != -1) {
      final existing = list[idx];
      list[idx] = CartItemModel(
        product: existing.product,
        quantity: newQuantity,
        selectedVariant: existing.selectedVariant,
        variant: existing.variant,
        overridePrice: existing.overridePrice,
      );
      state = state.copyWith(items: list);
      _saveCart();
      _revalidateCouponSilently();
    }
  }

  void removeFromCart(dynamic productId, {String? variant}) {
    final targetId = productId.toString();
    final list = state.items.where((i) => !(i.product.id.toString() == targetId && i.selectedVariant == variant)).toList();
    state = state.copyWith(items: list);
    _saveCart();
    _revalidateCouponSilently();
  }

  void _revalidateCouponSilently() {
    final code = state.appliedCouponCode;
    if (code == null) return;
    if (state.items.isEmpty) {
      removeCoupon();
      return;
    }

    ref.read(apiClientProvider).post(
      ApiEndpoints.validateCoupon,
      data: {
        'code': code,
        'total': state.subtotal,
        'order_amount': state.subtotal,
      },
    ).then((res) {
      final data = res.data;
      if (data != null && data['success'] == true && data['valid'] == true) {
        final discount = double.tryParse((data['discount'] ?? 0).toString()) ?? 0.0;
        state = state.copyWith(discountAmount: discount);
      } else {
        removeCoupon();
      }
    }).catchError((_) {
      if (state.subtotal <= 0) removeCoupon();
    });
  }

  Future<bool> applyCoupon(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return false;

    state = state.copyWith(isApplyingCoupon: true, couponMessage: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(
        ApiEndpoints.validateCoupon,
        data: {
          'code': clean,
          'total': state.subtotal,
          'order_amount': state.subtotal,
        },
      ).timeout(const Duration(seconds: 10));

      final data = res.data;
      if (data['success'] == true && data['valid'] == true) {
        final discount = double.tryParse((data['discount'] ?? 0).toString()) ?? 0.0;
        state = state.copyWith(
          discountAmount: discount,
          appliedCouponCode: clean,
          couponMessage: data['message'] ?? 'Coupon applied successfully!',
          isApplyingCoupon: false,
        );
        return true;
      } else {
        state = state.copyWith(
          discountAmount: 0.0,
          appliedCouponCode: null,
          couponMessage: data['message'] ?? 'Invalid coupon code',
          isApplyingCoupon: false,
        );
        return false;
      }
    } catch (e) {
      final errMsg = e.toString().contains('timed out')
          ? 'Network timeout validating coupon. Please try again.'
          : 'Unable to validate coupon with server. Please check connection.';
      state = state.copyWith(
        discountAmount: 0.0,
        appliedCouponCode: null,
        couponMessage: errMsg,
        isApplyingCoupon: false,
      );
      return false;
    }
  }

  void removeCoupon() {
    state = state.copyWith(
      discountAmount: 0.0,
      appliedCouponCode: null,
      couponMessage: null,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});
