import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../checkout/checkout_screen.dart';
import '../widgets/quantity_selector.dart';

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

    // Empty Cart View
    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF7EE),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(0, cartNotifier, context),

              // Empty State Illustration
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 160,
                          child: Image.asset(
                            'assets/images/orders_empty_box.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_cart_outlined,
                              size: 72,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your Cart is Empty',
                          style: TextStyle(
                            color: AppColors.forestGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add farm fresh A2 milk, bilona ghee, paneer, and groceries to your cart.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF6E8072), fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 180,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: widget.onContinueShopping ?? () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forestGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Shop Now →', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Active Cart View
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Row
            _buildHeader(cartState.totalItemCount, cartNotifier, context),

            // 2. Scrollable Body: Items, Coupon, Order Summary
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Store Pickup Notice (if active)
                  if (cartState.isPickupOnly) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF7EB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.forestGreen, width: 1.2),
                      ),
                      child: Row(
                        children: const [
                          Text('🏪', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'STORE PICKUP ORDER (FREE) — Pickup from THULIRVA Farm Store.',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Actual Cart Item Cards
                  ...items.map((item) => _buildCartItemCard(item, cartNotifier)),
                  const SizedBox(height: 12),

                  // Coupon Section
                  _buildCouponSection(cartState, cartNotifier),
                  const SizedBox(height: 14),

                  // Bill Breakdown Details
                  _buildBillSummary(cartState),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // 3. Pinned Bottom Checkout Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE5EDE2), width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Proceed to Checkout',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ₹${cartState.grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFF7D97B)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count, CartNotifier notifier, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.forestGreen, size: 24),
              onPressed: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 40),
          Text(
            count > 0 ? 'My Cart ($count)' : 'My Cart',
            style: const TextStyle(
              color: AppColors.forestGreen,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (count > 0)
            TextButton(
              onPressed: () => notifier.clearCart(),
              child: const Text(
                'Clear',
                style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.w700, fontSize: 13),
              ),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item, CartNotifier notifier) {
    final prod = item.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7EE),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildItemImage(prod),
          ),
          const SizedBox(width: 12),

          // Details & Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        prod.name,
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => notifier.removeFromCart(prod.id, variant: item.selectedVariant),
                      child: const Icon(Icons.delete_outline, color: Color(0xFFD32F2F), size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.selectedVariant ?? (prod.weight.isNotEmpty ? prod.weight : prod.category),
                  style: const TextStyle(color: Color(0xFF6E8072), fontSize: 11.5),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    QuantitySelector(
                      quantity: item.quantity,
                      onQuantityChanged: (q) => notifier.updateQuantity(prod.id, q, variant: item.selectedVariant),
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

  Widget _buildCouponSection(CartState state, CartNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.confirmation_number_outlined, color: AppColors.forestGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Have a Promo / Coupon Code?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.forestGreen),
              ),
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
                    decoration: InputDecoration(
                      hintText: 'Enter promo code (e.g. TLV10)',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8A9A7A)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFFFAF7EE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5EDE2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5EDE2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: state.isApplyingCoupon
                      ? null
                      : () async {
                          final code = _couponController.text.trim();
                          if (code.isNotEmpty) {
                            final ok = await notifier.applyCoupon(code);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? '✓ Coupon applied!' : (state.couponMessage ?? 'Invalid coupon')),
                                  backgroundColor: ok ? AppColors.naturalGreen : AppColors.cancelled,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: state.isApplyingCoupon
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
          if (state.appliedCouponCode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '✓ ${state.appliedCouponCode} applied: -₹${state.discountAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _couponController.clear();
                    notifier.removeCoupon();
                  },
                  child: const Text('Remove', style: TextStyle(color: Color(0xFFD32F2F), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillSummary(CartState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Item Total', '₹${state.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            state.isPickupOnly ? 'Farm Store Pickup' : 'Delivery Charge',
            state.deliveryCharge == 0 ? 'FREE' : '₹${state.deliveryCharge.toStringAsFixed(0)}',
            isFree: state.deliveryCharge == 0,
          ),
          if (state.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Promo Discount', '-₹${state.discountAmount.toStringAsFixed(0)}', isDiscount: true),
          ],
          const Divider(height: 20, color: Color(0xFFE5EDE2)),
          _buildSummaryRow('Total Amount', '₹${state.grandTotal.toStringAsFixed(0)}', isTotal: true),
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
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? AppColors.forestGreen : const Color(0xFF556B5D),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 13.5,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
            color: isTotal
                ? AppColors.forestGreen
                : (isFree || isDiscount)
                    ? const Color(0xFF2E7D32)
                    : AppColors.forestGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildItemImage(ProductModel prod) {
    if (prod.fullImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: prod.fullImageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: const Color(0xFFF3F7F2),
          child: const Center(
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen)),
          ),
        ),
        errorWidget: (_, __, ___) => _buildFallback(prod),
      );
    }
    return _buildFallback(prod);
  }

  Widget _buildFallback(ProductModel prod) {
    String asset = 'assets/images/products/fresh_cow_milk.jpg';
    final nameLower = prod.name.toLowerCase();
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
