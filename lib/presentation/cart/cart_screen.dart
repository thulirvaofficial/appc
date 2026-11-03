import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../checkout/checkout_screen.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/thulirva_button.dart';

class CartScreen extends ConsumerStatefulWidget {
  final VoidCallback? onContinueShopping;

  const CartScreen({super.key, this.onContinueShopping});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final items = cartState.items;

    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.lightCream,
        appBar: AppBar(
          title: const Text(
            'My Cart',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: AppColors.forestGreen,
          automaticallyImplyLeading: false,
          centerTitle: true,
          elevation: 0,
        ),
        body: EmptyStateView(
          title: 'Your Cart is Empty',
          message: 'Add farm fresh milk, ghee, paneer, and oils to your cart.',
          emoji: '🛒',
          buttonText: 'Start Shopping',
          onButtonPressed: widget.onContinueShopping,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'My Cart (${cartState.totalItemCount})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.forestGreen,
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => cartNotifier.clearCart(),
            child: const Text('Clear', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (cartState.isPickupOnly) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.forestGreen, width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🏪', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'STORE PICKUP ORDER (FREE)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Doorstep delivery is temporarily paused. Please collect your fresh farm produce directly from THULIRVA Farm Store (Kanchipuram).',
                                  style: TextStyle(fontSize: 12, color: AppColors.textMid, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // List of Cart Items
                  ...items.map((item) => _buildCartItemCard(item, cartNotifier)),
                  const SizedBox(height: 16),

                  // Promo Code Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.confirmation_number_outlined, color: AppColors.forestGreen, size: 18),
                            SizedBox(width: 8),
                            Text('Have a Promo / Coupon Code?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: TextField(
                                  controller: _couponController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. FARM10',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                onPressed: cartState.isApplyingCoupon
                                    ? null
                                    : () async {
                                        final code = _couponController.text.trim();
                                        if (code.isNotEmpty) {
                                          final ok = await cartNotifier.applyCoupon(code);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(cartState.couponMessage ?? (ok ? 'Coupon Applied!' : 'Invalid code')),
                                                backgroundColor: ok ? AppColors.naturalGreen : AppColors.cancelled,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forestGreen,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: cartState.isApplyingCoupon
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                        if (cartState.appliedCouponCode != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '✓ ${cartState.appliedCouponCode} applied: -₹${cartState.discountAmount.toStringAsFixed(0)}',
                                style: const TextStyle(color: AppColors.naturalGreen, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  _couponController.clear();
                                  cartNotifier.removeCoupon();
                                },
                                child: const Text('Remove', style: TextStyle(color: AppColors.cancelled, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bill Breakdown Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Item Total', '₹${cartState.subtotal.toStringAsFixed(0)}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          cartState.isPickupOnly ? 'Farm Store Pickup' : 'Delivery Charge',
                          cartState.deliveryCharge == 0
                              ? 'FREE'
                              : '₹${cartState.deliveryCharge.toStringAsFixed(0)}',
                          isFree: cartState.deliveryCharge == 0,
                        ),
                        if (cartState.discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _buildSummaryRow('Promo Discount', '-₹${cartState.discountAmount.toStringAsFixed(0)}', isDiscount: true),
                        ],
                        const Divider(height: 20),
                        _buildSummaryRow('Total', '₹${cartState.grandTotal.toStringAsFixed(0)}', isTotal: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Checkout Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forestGreen.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: ThulirvaButton(
                text: 'Proceed to Checkout • ₹${cartState.grandTotal.toStringAsFixed(0)}',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(item, CartNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.lightCream,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildItemImage(item.product),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => notifier.removeFromCart(item.product.id, variant: item.selectedVariant),
                      child: const Text('Remove', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ),
                  ],
                ),
                Text(
                  item.selectedVariant ?? item.product.weight,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${item.totalPrice.toStringAsFixed(0)}', style: AppTypography.price.copyWith(fontSize: 16)),
                    QuantitySelector(
                      quantity: item.quantity,
                      onQuantityChanged: (q) => notifier.updateQuantity(item.product.id, q, variant: item.selectedVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isFree = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)
              : AppTypography.bodyMedium.copyWith(color: AppColors.textMid),
        ),
        Text(
          value,
          style: isTotal
              ? AppTypography.price.copyWith(fontSize: 18)
              : (isFree || isDiscount)
                  ? const TextStyle(color: AppColors.naturalGreen, fontWeight: FontWeight.w700, fontSize: 13.5)
                  : AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildItemImage(ProductModel product) {
    if (product.fullImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: product.fullImageUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildFallback(product),
      );
    }
    return _buildFallback(product);
  }

  Widget _buildFallback(ProductModel product) {
    String asset = 'assets/images/products/fresh_cow_milk.jpg';
    final nameLower = product.name.toLowerCase();
    if (nameLower.contains('ghee')) {
      asset = 'assets/images/products/pure_cow_ghee.jpg';
    } else if (nameLower.contains('paneer')) {
      asset = 'assets/images/products/fresh_paneer.jpg';
    } else if (nameLower.contains('oil') || nameLower.contains('masala')) {
      asset = 'assets/images/products/product_lineup.jpg';
    }

    return Image.asset(asset, fit: BoxFit.cover);
  }
}

