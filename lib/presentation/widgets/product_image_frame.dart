import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/product_model.dart';

/// Standardized, pixel-perfect product image frame.
///
/// Specifications:
/// - Fixed Landscape Aspect Ratio: 3:2 (width / height = 1.5).
/// - Width: 100% of available parent card width.
/// - Height: Dynamically calculated strictly from the 3:2 aspect ratio.
/// - Alignment: Perfectly centered horizontally and vertically.
/// - Clip: Rounded top corners matching the product card border radius.
/// - Image Fitting: BoxFit.contain on a warm natural cream background (#FAF8EF)
///   to ensure complete product packaging, branding, text, logos, and caps
///   are preserved without being cropped, stretched, or distorted.
/// - Unified Error & Loading: Smooth loading indicator and intelligent category fallback.
class ProductImageFrame extends StatelessWidget {
  final ProductModel? product;
  final String? imageUrl;
  final String? fallbackAssetName;
  final String? fallbackEmoji;
  final double aspectRatio;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color backgroundColor;
  final Widget? overlay;
  final EdgeInsetsGeometry padding;

  const ProductImageFrame({
    super.key,
    this.product,
    this.imageUrl,
    this.fallbackAssetName,
    this.fallbackEmoji,
    this.aspectRatio = 3.0 / 2.0, // Strict 3:2 landscape aspect ratio
    this.borderRadius,
    this.fit = BoxFit.contain, // Default: contain to never crop packaging or labels
    this.backgroundColor = const Color(0xFFFAF8EF), // Warm natural cream
    this.overlay,
    this.padding = EdgeInsets.zero,
  });

  /// Factory constructor when using a [ProductModel].
  factory ProductImageFrame.forProduct({
    Key? key,
    required ProductModel product,
    double aspectRatio = 3.0 / 2.0,
    BorderRadius? borderRadius,
    BoxFit fit = BoxFit.contain,
    Color backgroundColor = const Color(0xFFFAF8EF),
    Widget? overlay,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return ProductImageFrame(
      key: key,
      product: product,
      imageUrl: product.fullImageUrl,
      fallbackEmoji: product.emoji,
      aspectRatio: aspectRatio,
      borderRadius: borderRadius,
      fit: fit,
      backgroundColor: backgroundColor,
      overlay: overlay,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ??
        const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        );

    final resolvedImageUrl = imageUrl ?? product?.fullImageUrl ?? '';

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          width: double.infinity,
          color: backgroundColor,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Padding(
                padding: padding,
                child: Center(
                  child: resolvedImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: resolvedImageUrl,
                          fit: fit,
                          alignment: Alignment.center,
                          fadeInDuration: const Duration(milliseconds: 180),
                          fadeOutDuration: const Duration(milliseconds: 180),
                          placeholder: (_, __) => _buildLoadingPlaceholder(),
                          errorWidget: (_, __, ___) => _buildFallbackWidget(),
                        )
                      : _buildFallbackWidget(),
                ),
              ),
              if (overlay != null) overlay!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: backgroundColor,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.forestGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    final assetPath = _resolveFallbackAsset();
    return Image.asset(
      assetPath,
      fit: fit,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => Container(
        color: backgroundColor,
        alignment: Alignment.center,
        child: Text(
          fallbackEmoji ?? product?.emoji ?? '🥛',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  String _resolveFallbackAsset() {
    if (fallbackAssetName != null && fallbackAssetName!.isNotEmpty) {
      return fallbackAssetName!;
    }

    final name = (product?.name ?? '').toLowerCase();
    final cat = (product?.category ?? '').toLowerCase();

    if (name.contains('ghee') || name.contains('butter') || cat.contains('ghee')) {
      return 'assets/images/products/pure_cow_ghee.jpg';
    } else if (name.contains('paneer') || name.contains('tofu') || cat.contains('paneer')) {
      return 'assets/images/products/fresh_paneer.jpg';
    } else if (name.contains('curd') ||
        name.contains('oil') ||
        name.contains('masala') ||
        name.contains('vegan') ||
        cat.contains('oil') ||
        cat.contains('grocery') ||
        cat.contains('spice')) {
      return 'assets/images/products/product_lineup.jpg';
    }

    return 'assets/images/products/fresh_cow_milk.jpg';
  }
}
