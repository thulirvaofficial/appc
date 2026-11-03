import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../cart/cart_screen.dart';
import '../products/product_details_screen.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final bool isHorizontal;
  final bool showAddText;

  const ProductCard({
    super.key,
    required this.product,
    this.isHorizontal = false,
    this.showAddText = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPickupOnly = ref.watch(settingsProvider).isPickupOnly;
    final inCartQty = ref.watch(cartProvider.notifier).getProductQuantity(product.id);
    final effectiveBadge = isPickupOnly ? '🏪 Pickup Only' : product.badge;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Badge
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.lightCream,
                    child: _buildProductImage(),
                  ),
                  if (effectiveBadge != null && effectiveBadge.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPickupOnly ? const Color(0xFF1B4332) : AppColors.forestGreen,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          effectiveBadge,
                          style: TextStyle(
                            color: isPickupOnly ? Colors.white : AppColors.lightGold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Details & Add Button
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.weight.isNotEmpty ? product.weight : product.category,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textLight,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: AppTypography.price.copyWith(fontSize: 16),
                      ),
                      inCartQty > 0
                          ? Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.paleGreen,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: AppColors.forestGreen, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      ref.read(cartProvider.notifier).updateQuantity(product.id, inCartQty - 1);
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                      child: Icon(Icons.remove, size: 14, color: AppColors.forestGreen),
                                    ),
                                  ),
                                  Text(
                                    '$inCartQty',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.forestGreen),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      ref.read(cartProvider.notifier).addToCart(product);
                                    },
                                    borderRadius: BorderRadius.circular(15),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                      child: Icon(Icons.add, size: 14, color: AppColors.forestGreen),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : InkWell(
                              onTap: () {
                                ref.read(cartProvider.notifier).addToCart(product);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✓ ${product.name} added to cart!'),
                                    backgroundColor: AppColors.forestGreen,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(showAddText ? 16 : 6),
                              child: showAddText
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.forestGreen,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.forestGreen,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imgUrl = product.fullImageUrl;
    if (imgUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imgUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
          ),
        ),
        errorWidget: (_, __, ___) => _buildFallbackAsset(),
      );
    }
    return _buildFallbackAsset();
  }

  Widget _buildFallbackAsset() {
    String assetPath = 'assets/images/products/fresh_cow_milk.jpg';
    final nameLower = product.name.toLowerCase();
    if (nameLower.contains('ghee') || nameLower.contains('butter')) {
      assetPath = 'assets/images/products/pure_cow_ghee.jpg';
    } else if (nameLower.contains('paneer') || nameLower.contains('tofu')) {
      assetPath = 'assets/images/products/fresh_paneer.jpg';
    } else if (nameLower.contains('curd') || nameLower.contains('oil') || nameLower.contains('masala')) {
      assetPath = 'assets/images/products/product_lineup.jpg';
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Text(
          product.emoji ?? '🥛',
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }
}
