import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/storage/storage_service.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import 'api_provider.dart';
import 'settings_provider.dart';

class CartState {
  final List<CartItemModel> items;
  final double discountAmount;
  final String? appliedCouponCode;
  final String? couponMessage;
  final bool isApplyingCoupon;
  final bool isPickupOnly;

  CartState({
    this.items = const [],
    this.discountAmount = 0.0,
    this.appliedCouponCode,
    this.couponMessage,
    this.isApplyingCoupon = false,
    this.isPickupOnly = false,
  });

  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);

  double get deliveryCharge {
    if (isPickupOnly) return 0.0;
    return (subtotal >= 299.0 || subtotal == 0.0) ? 0.0 : 30.0;
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
  }) {
    return CartState(
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      appliedCouponCode: appliedCouponCode ?? this.appliedCouponCode,
      couponMessage: couponMessage ?? this.couponMessage,
      isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
      isPickupOnly: isPickupOnly ?? this.isPickupOnly,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;

  CartNotifier(this.ref) : super(CartState()) {
    _loadCart();
    // Listen to store settings pickup mode
    ref.listen<StoreSettingsState>(settingsProvider, (prev, next) {
      if (next.isPickupOnly != state.isPickupOnly) {
        state = state.copyWith(isPickupOnly: next.isPickupOnly);
      }
    });
  }

  void _loadCart() {
    final saved = StorageService.getCart();
    if (saved.isNotEmpty) {
      try {
        final list = saved.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return CartItemModel.fromJson(map);
        }).toList();
        state = state.copyWith(items: list);
      } catch (_) {}
    }
  }

  void _saveCart() {
    StorageService.saveCart(state.items.map((i) => i.toJson()).toList());
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

  void addToCart(ProductModel product, {int quantity = 1, String? variant}) {
    final list = [...state.items];
    final targetId = product.id.toString();
    final idx = list.indexWhere((i) => i.product.id.toString() == targetId && i.selectedVariant == variant);

    if (idx != -1) {
      final existing = list[idx];
      list[idx] = CartItemModel(
        product: existing.product,
        quantity: existing.quantity + quantity,
        selectedVariant: existing.selectedVariant,
      );
    } else {
      list.add(CartItemModel(
        product: product,
        quantity: quantity,
        selectedVariant: variant,
      ));
    }

    state = state.copyWith(items: list);
    _saveCart();
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
      );
      state = state.copyWith(items: list);
      _saveCart();
    }
  }

  void removeFromCart(dynamic productId, {String? variant}) {
    final targetId = productId.toString();
    final list = state.items.where((i) => !(i.product.id.toString() == targetId && i.selectedVariant == variant)).toList();
    state = state.copyWith(items: list);
    _saveCart();
  }

  void clearCart() {
    state = state.copyWith(items: const [], discountAmount: 0.0, appliedCouponCode: null, couponMessage: null);
    _saveCart();
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
      );

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
      // Fallback promo
      if (clean == 'FARM10') {
        final disc = state.subtotal * 0.10;
        state = state.copyWith(
          discountAmount: disc,
          appliedCouponCode: clean,
          couponMessage: '10% Farm discount applied!',
          isApplyingCoupon: false,
        );
        return true;
      }

      state = state.copyWith(
        discountAmount: 0.0,
        appliedCouponCode: null,
        couponMessage: e.toString(),
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
