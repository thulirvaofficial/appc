import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../checkout/checkout_screen.dart';
import 'apply_coupon_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  final VoidCallback? onContinueShopping;

  const CartScreen({super.key, this.onContinueShopping});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final items = cartState.items;

    return Material(
      color: const Color(0xFFFAF7EE),
      child: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar always visible at top of Cart (Responsive to any screen width)
            _buildTopBar(cartState.totalItemCount, cartNotifier, context),

            // 2. Scrollable Body
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyCartContent(cartNotifier, context)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        // Subheader: "My Cart (X)" & "Review your items and proceed to checkout"
                        _buildHeaderTitle(cartState.totalItemCount),
                        const SizedBox(height: 10),

                        // Cart Item Cards
                        ...items.map((item) => _buildCartItemCard(item, cartNotifier)),
                        const SizedBox(height: 12),

                        // Apply Coupon Section
                        _buildCouponCard(cartState, cartNotifier),
                        const SizedBox(height: 14),

                        // Free Delivery Progress Banner (Dynamic threshold)
                        if (cartState.deliveryChargesEnabled && !cartState.isPickupOnly) ...[
                          _buildFreeDeliveryProgressBanner(cartState),
                          const SizedBox(height: 14),
                        ],

                        // Order Summary Card
                        _buildOrderSummaryCard(cartState),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),

            // 3. Pinned Bottom Checkout Bar: "Proceed to Checkout  →"
            if (items.isNotEmpty) _buildBottomCheckoutBar(cartState, context),
          ],
        ),
      ),
    );
  }

  // Top App Bar with Logo Emblem, Back button, and Clear Cart (Zero overflow)
  Widget _buildTopBar(int count, CartNotifier notifier, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Left: Back button (pops or switches to home tab)
          InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else if (widget.onContinueShopping != null) {
                widget.onContinueShopping!();
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.arrow_back, color: AppColors.forestGreen, size: 24),
            ),
          ),
          const SizedBox(width: 8),

          // Center: Brand Logo + Text (Flexible + FittedBox guarantees NO overflow)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5EDE2), width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo/logo_circle_emblem.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset('assets/images/logo/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'THULIRVA',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.forestGreen,
                          letterSpacing: 1.8,
                        ),
                      ),
                      Text(
                        '— ROOTED IN NATURE —',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A9A7A),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Right: Trash Can + "Clear" button
          if (count > 0)
            InkWell(
              onTap: () => notifier.clearCart(),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.forestGreen, size: 19),
                    SizedBox(width: 2),
                    Text(
                      'Clear',
                      style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: 32),
        ],
      ),
    );
  }

  // Header Title & Subtitle matching reference screenshot
  Widget _buildHeaderTitle(int count) {
    return Column(
      children: [
        Text(
          'My Cart ($count)',
          style: const TextStyle(
            color: AppColors.forestGreen,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Review your items and proceed to checkout',
          style: TextStyle(
            color: Color(0xFF6E8072),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Cart Item Card matching media_1793884250757_c2c74722.jpg reference
  Widget _buildCartItemCard(CartItemModel item, CartNotifier notifier) {
    final prod = item.product;
    final displayName = prod.name.trim().isNotEmpty ? prod.name : 'Farm Fresh Item';
    final variantText = (item.selectedVariant != null && item.selectedVariant!.isNotEmpty)
        ? item.selectedVariant!
        : (prod.weight.isNotEmpty ? prod.weight : 'Standard');
    final displayPrice = item.unitPrice > 0 ? item.unitPrice : (item.overridePrice ?? prod.price);
    final subtitle = (prod.description != null && prod.description!.trim().isNotEmpty)
        ? prod.description!.trim()
        : (displayName.toLowerCase().contains('ghee')
            ? 'Traditional Bilona, pure & aromatic'
            : (displayName.toLowerCase().contains('milk')
                ? 'Farm fresh A2 cow milk, chilled & pure'
                : '100% natural, farm fresh'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Product Image in soft pastel green container
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7EB),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildItemImage(prod),
          ),
          const SizedBox(width: 12),

          // Details & Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title and Heart Wishlist Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.favorite_border, color: AppColors.forestGreen, size: 20),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6E8072), fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Variant Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    variantText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Price & Capsule Quantity Selector Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹${displayPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    // Capsule Quantity Selector: [ -  qty  + ]
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF7EB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD2E8CB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              notifier.updateQuantity(prod.id, item.quantity - 1, variant: item.selectedVariant);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: Icon(Icons.remove, size: 14, color: AppColors.forestGreen),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.forestGreen),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              notifier.addToCart(prod, variant: item.selectedVariant);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: Icon(Icons.add, size: 14, color: AppColors.forestGreen),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  // Coupon Card matching reference design with tap-to-open
  Widget _buildCouponCard(CartState state, CartNotifier notifier) {
    final hasCoupon = state.appliedCouponCode != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasCoupon ? const Color(0xFFC8E6C9) : const Color(0xFFE5EDE2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApplyCouponScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7EE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.forestGreen, width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.percent, color: AppColors.forestGreen, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Apply Coupon',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.forestGreen),
                      ),
                      Text(
                        'Have a coupon code? Apply it here.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF6E8072)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasCoupon)
                  TextButton(
                    onPressed: () => notifier.removeCoupon(),
                    child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 12)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF7EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Apply',
                          style: TextStyle(color: AppColors.forestGreen, fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.forestGreen),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (hasCoupon) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Coupon "${state.appliedCouponCode}" applied! Saved ₹${state.discountAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFreeDeliveryProgressBanner(CartState state) {
    final isFree = state.subtotal >= state.freeDeliveryThreshold;
    final needed = (state.freeDeliveryThreshold - state.subtotal).clamp(0.0, state.freeDeliveryThreshold);
    final progress = state.freeDeliveryThreshold > 0
        ? (state.subtotal / state.freeDeliveryThreshold).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFree ? const Color(0xFFEDF7EB) : const Color(0xFFF9FDF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFree ? const Color(0xFFC8E6C9) : const Color(0xFFE2EEDF),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFree ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                color: isFree ? const Color(0xFF2E7D32) : AppColors.forestGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFree
                      ? 'Free Delivery unlocked on this order! 🎉'
                      : 'Add ₹${needed.toStringAsFixed(0)} more for FREE Delivery!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isFree ? const Color(0xFF2E7D32) : AppColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
          if (!isFree) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE2EEDF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Order Summary Card matching media_1793884250757_c2c74722.jpg reference
  Widget _buildOrderSummaryCard(CartState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Green Strip with Leaves Icon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFEDF7EB),
            child: const Row(
              children: [
                Icon(Icons.eco, size: 20, color: Color(0xFF4CAF50)),
                SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.forestGreen),
                ),
              ],
            ),
          ),

          // Breakdown Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryLine('Subtotal (${state.totalItemCount} items)', '₹${state.subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 10),
                _buildSummaryLine(
                  'Delivery Charges',
                  state.deliveryCharge == 0 ? 'FREE' : '₹${state.deliveryCharge.toStringAsFixed(0)}',
                  isFree: state.deliveryCharge == 0,
                  showInfo: true,
                ),
                if (state.discountAmount > 0) ...[
                  const SizedBox(height: 10),
                  _buildSummaryLine('Discount', '- ₹${state.discountAmount.toStringAsFixed(0)}', isDiscount: true),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFE5EDE2), height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: AppColors.forestGreen),
                    ),
                    Text(
                      '₹${state.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21, color: AppColors.forestGreen),
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

  Widget _buildSummaryLine(String label, String value, {bool isFree = false, bool isDiscount = false, bool showInfo = false}) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF4A5568), fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showInfo) ...[
                const SizedBox(width: 4),
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF8A9A7A)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: (isFree || isDiscount) ? const Color(0xFF2E7D32) : AppColors.forestGreen,
          ),
        ),
      ],
    );
  }

  // Pinned Bottom Checkout Bar (FittedBox guarantees zero overflow)
  Widget _buildBottomCheckoutBar(CartState cartState, BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7EE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
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
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Empty Cart Content
  Widget _buildEmptyCartContent(CartNotifier cartNotifier, BuildContext context) {
    return Center(
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
                onPressed: widget.onContinueShopping ?? () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
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
    );
  }

  Widget _buildItemImage(ProductModel prod) {
    if (prod.fullImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: prod.fullImageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: const Color(0xFFEDF7EB),
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

    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFEDF7EB),
        child: const Center(
          child: Icon(Icons.shopping_bag_outlined, color: AppColors.forestGreen, size: 28),
        ),
      ),
    );
  }
}
