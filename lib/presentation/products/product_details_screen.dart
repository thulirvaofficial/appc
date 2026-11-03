import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/thulirva_button.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _quantity = 1;
  late String _selectedVariant;
  bool _isFavorite = false;

  final List<String> _variants = ['200 g', '500 g', '1 kg'];

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.product.weight.isNotEmpty ? widget.product.weight : '500 ml';
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

                        // Price
                        Text(
                          '₹${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Available Variants Chips (Mockup: [200 g] [500 g] [1 kg])
                        Row(
                          children: _variants.map((v) {
                            final isSel = _selectedVariant == v;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: Text(v),
                                selected: isSel,
                                onSelected: (_) => setState(() => _selectedVariant = v),
                                selectedColor: AppColors.forestGreen,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.white : AppColors.textDark,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: isSel ? AppColors.forestGreen : AppColors.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            );
                          }).toList(),
                        ),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Add to Cart Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(cartProvider.notifier).addToCart(
                          p,
                          quantity: _quantity,
                          variant: _selectedVariant,
                        );
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ ${p.name} added to cart!'),
                        backgroundColor: AppColors.forestGreen,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'VIEW CART',
                          textColor: AppColors.lightGold,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          },
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
