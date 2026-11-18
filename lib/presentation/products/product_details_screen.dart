import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/cart_notification_service.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../widgets/quantity_selector.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  ProductVariantModel? _selectedVariant;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _selectedVariant = p.defaultVariant ?? (p.variants.isNotEmpty ? p.variants.first : null);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(p.name, style: AppTypography.displaySmall.copyWith(fontSize: 18)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.cancelled : AppColors.forestGreen,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite ? '❤️ Added to wishlist' : 'Removed from wishlist'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.forestGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing THULIRVA farm fresh product...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final cartCount = ref.watch(cartProvider).totalItemCount;
              return IconButton(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  backgroundColor: AppColors.cancelled,
                  label: Text(
                    '$cartCount',
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined, color: AppColors.forestGreen),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large Product Image Showcase
                  Container(
                    height: 280,
                    width: double.infinity,
                    color: AppColors.lightCream,
                    child: _buildImage(p),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.paleGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.forestGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Title & Subtitle (Mockup Screen 7)
                        Text(
                          p.name,
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Soft, Fresh & Pure',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dynamic Price & Compare Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${(_selectedVariant?.price ?? p.price).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            if ((_selectedVariant?.comparePrice ?? p.comparePrice) != null &&
                                (_selectedVariant?.comparePrice ?? p.comparePrice)! > (_selectedVariant?.price ?? p.price)) ...[
                              const SizedBox(width: 10),
                              Text(
                                '₹${(_selectedVariant?.comparePrice ?? p.comparePrice)!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF8A9A8C),
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Dynamic Available Variants Chips (Configured in Backend)
                        if (p.variants.isNotEmpty) ...[
                          const Text(
                            'Select Weight / Size:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6E8072)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: p.variants.map((v) {
                              final isSel = _selectedVariant?.id == v.id;
                              final inStock = v.stock > 0;
                              return ChoiceChip(
                                label: Text('${v.name} • ₹${v.price.toStringAsFixed(0)}'),
                                selected: isSel,
                                onSelected: inStock ? (_) => setState(() => _selectedVariant = v) : null,
                                selectedColor: AppColors.forestGreen,
                                backgroundColor: inStock ? Colors.white : const Color(0xFFF3F3F3),
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : (inStock ? AppColors.textDark : Colors.grey),
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                                side: BorderSide(
                                  color: isSel ? AppColors.forestGreen : AppColors.border,
                                  width: isSel ? 1.5 : 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 18),

                        // Description
                        Text(
                          p.description != null && p.description!.isNotEmpty
                              ? p.description!
                              : 'Made from fresh, high-quality cow milk. No preservatives. Soft, fresh and healthy for your family.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textMid,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Purity Badges (Mockup Screen 7: 100% Natural, No Preservatives, Rich in Protein)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFeatureBadge('🌿', '100% Natural'),
                            _buildFeatureBadge('🛡️', 'No Preservatives'),
                            _buildFeatureBadge('💪', 'Rich in Protein'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Key Highlights
                        if (p.highlights.isNotEmpty) ...[
                          const Text(
                            'Key Highlights',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...p.highlights.map((h) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('🌱 ', style: TextStyle(fontSize: 13)),
                                    Expanded(
                                      child: Text(
                                        h,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMid,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 20),
                        ],

                        // Ingredients
                        if (p.ingredients.isNotEmpty) ...[
                          const Text(
                            'Pure Ingredients',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightCream,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              p.ingredients.join(', '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Storage & Usage Instructions
                        if (p.storageInstructions.isNotEmpty || p.usageInstructions.isNotEmpty) ...[
                          const Text(
                            'Storage & Usage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (p.storageInstructions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '❄️ Storage: ${p.storageInstructions}',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textMid, height: 1.4),
                              ),
                            ),
                          if (p.usageInstructions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '💡 Usage: ${p.usageInstructions}',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textMid, height: 1.4),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],

                        // Product-Specific Refund & Quality Policy Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_user_outlined, color: AppColors.forestGreen, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    p.refundPolicy != null
                                        ? '${p.refundPolicy!['type'] ?? 'Quality Assurance'}'
                                        : 'THULIRVA Farm Purity Guarantee',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.refundPolicy != null
                                    ? '${p.refundPolicy!['condition'] ?? '100% refund or replacement if not satisfied upon delivery.'}'
                                    : 'Instant replacement or 100% wallet refund if milk or produce arrives damaged or compromised upon delivery inspection.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF166534),
                                  height: 1.4,
                                ),
                              ),
                              if (p.refundPolicy != null && p.refundPolicy!['window_hours'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '⏱ Claim window: within ${p.refundPolicy!['window_hours']} hours of delivery',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Add to Cart Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forestGreen.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  QuantitySelector(
                    quantity: _quantity,
                    onQuantityChanged: (val) => setState(() => _quantity = val),
                    minQuantity: 1,
                    maxQuantity: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).addToCart(
                                p,
                                quantity: _quantity,
                                variantModel: _selectedVariant,
                              );
                          CartNotificationService.show(productName: p.name);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String icon, String title) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.paleGreen,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.softGreen, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildImage(ProductModel product) {
    final imgUrl = product.fullImageUrl;
    if (imgUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imgUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildFallbackAsset(product),
      );
    }
    return _buildFallbackAsset(product);
  }

  Widget _buildFallbackAsset(ProductModel product) {
    String assetPath = 'assets/images/products/fresh_cow_milk.jpg';
    final nameLower = product.name.toLowerCase();
    if (nameLower.contains('ghee') || nameLower.contains('butter')) {
      assetPath = 'assets/images/products/pure_cow_ghee.jpg';
    } else if (nameLower.contains('paneer') || nameLower.contains('tofu')) {
      assetPath = 'assets/images/products/fresh_paneer.jpg';
    } else if (nameLower.contains('curd') || nameLower.contains('oil') || nameLower.contains('masala')) {
      assetPath = 'assets/images/products/product_lineup.jpg';
    }

    return Image.asset(assetPath, fit: BoxFit.cover);
  }
}
