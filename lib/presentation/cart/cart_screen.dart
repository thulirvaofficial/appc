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
              _buildTopBar(0, cartNotifier, context),
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
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Active Cart View matching media_1793884250757_c2c74722.jpg reference
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            // 1. App Bar with Back Arrow (if can pop), Brand Emblem + "THULIRVA", and Clear
            _buildTopBar(cartState.totalItemCount, cartNotifier, context),

            // 2. Subheader: "My Cart (X)" & "Review your items and proceed to checkout"
            _buildHeaderTitle(cartState.totalItemCount),
            const SizedBox(height: 6),

            // 3. Cart Item Cards
            ...items.map((item) => _buildSafeCartItem(item, cartNotifier)),
            const SizedBox(height: 12),

            // 4. Apply Coupon Section
            _buildCouponCard(cartState, cartNotifier),
            const SizedBox(height: 14),

            // 5. Order Summary Card
            _buildOrderSummaryCard(cartState),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // Pinned Bottom Checkout Bar: "Proceed to Checkout • ₹X →"
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7EE),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
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
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Proceed to Checkout',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Top App Bar with Logo Emblem and Clear Cart (Responsive to any screen width)
  Widget _buildTopBar(int count, CartNotifier notifier, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Back button (or empty space if cannot pop)
          if (Navigator.canPop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.forestGreen, size: 24),
              onPressed: () => Navigator.pop(context),
            )
          else
            const SizedBox(width: 24),

          // Center: Brand Logo + Text (Flexible to guarantee zero overflow)
          Flexible(
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
                Flexible(
                  child: Column(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '— ROOTED IN NATURE —',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A9A7A),
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Trash Can + "Clear" button
          if (count > 0)
            InkWell(
              onTap: () => notifier.clearCart(),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.forestGreen, size: 18),
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
            const SizedBox(width: 24),
        ],
      ),
    );
  }

  // Clean Header Title & Subtitle (Clean layout matching reference)
  Widget _buildHeaderTitle(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
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
      ),
    );
  }

  // Safe wrapper for item card
  Widget _buildSafeCartItem(CartItemModel item, CartNotifier notifier) {
    try {
      return _buildCartItemCard(item, notifier);
    } catch (_) {
      return _buildFallbackCartCard(item, notifier);
    }
  }

  // Cart Item Card matching media_1793884250757_c2c74722.jpg exactly
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
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 2),
                      child: Icon(Icons.favorite_border, color: AppColors.forestGreen, size: 20),
                    ),
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

  // Fallback card that cannot fail
  Widget _buildFallbackCartCard(CartItemModel item, CartNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDE2)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.forestGreen, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.forestGreen),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(item.selectedVariant ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF6E8072))),
                const SizedBox(height: 6),
                Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.forestGreen)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => notifier.removeFromCart(item.product.id, variant: item.selectedVariant),
          ),
        ],
      ),
    );
  }

  // Coupon Card matching reference design with tap-to-open and quick chips
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
          // Header Row (Matches reference design: icon + "Apply Coupon" + pill "Apply >")
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApplyCouponScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7EE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.forestGreen, width: 1.2),
                        ),
                        child: const Center(
                          child: Icon(Icons.percent, color: AppColors.forestGreen, size: 18),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Have a coupon code? Apply it here.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6E8072)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (hasCoupon)
                  TextButton(
                    onPressed: () => notifier.removeCoupon(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 12)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF7EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Apply',
                          style: TextStyle(color: AppColors.forestGreen, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.forestGreen),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // If Coupon is already applied: Show Success Banner
          if (hasCoupon) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coupon "${state.appliedCouponCode}" Applied!',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), fontSize: 13),
                        ),
                        Text(
                          'You saved ₹${state.discountAmount.toStringAsFixed(0)} on this order.',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Direct Inline Input Box Row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
                      decoration: InputDecoration(
                        hintText: 'Enter Coupon Code',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.discount_outlined, color: AppColors.forestGreen, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  height: 44,
                  child: ElevatedButton(
                    onPressed: state.isApplyingCoupon
                        ? null
                        : () async {
                            final code = _couponController.text.trim();
                            if (code.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a coupon code'), backgroundColor: Colors.orange),
                              );
                              return;
                            }
                            final success = await notifier.applyCoupon(code);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? '✓ Coupon "$code" applied! Saved ₹${state.discountAmount.toStringAsFixed(0)}' : 'Invalid or expired coupon code.'),
                                  backgroundColor: success ? AppColors.forestGreen : Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: state.isApplyingCoupon
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Tap Coupon Chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildQuickCouponChip('THULIRVA10', '10% OFF', notifier),
                _buildQuickCouponChip('FARM50', '₹50 OFF', notifier),
                _buildQuickCouponChip('FREESHIP', 'Free Delivery', notifier),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickCouponChip(String code, String desc, CartNotifier notifier) {
    return InkWell(
      onTap: () async {
        _couponController.text = code;
        final success = await notifier.applyCoupon(code);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '✓ Coupon "$code" applied!' : 'Failed to apply coupon.'),
              backgroundColor: success ? AppColors.forestGreen : Colors.red,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7EE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE8D8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_offer, size: 11, color: AppColors.forestGreen),
            const SizedBox(width: 4),
            Text(
              '$code ($desc)',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
            ),
          ],
        ),
      ),
    );
  }

  // Order Summary Card matching media_1793884250757_c2c74722.jpg exactly
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
                Icon(Icons.eco, size: 18, color: Color(0xFF4CAF50)),
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
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.forestGreen),
                    ),
                    Text(
                      '₹${state.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.forestGreen),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
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
