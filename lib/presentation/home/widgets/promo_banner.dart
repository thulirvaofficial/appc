import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';

class PromoBanner extends StatelessWidget {
  final VoidCallback onShopNow;

  const PromoBanner({super.key, required this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 145,
      decoration: BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background visual accent
          Positioned(
            right: -10,
            bottom: -15,
            width: 140,
            height: 160,
            child: Opacity(
              opacity: 0.85,
              child: Image.asset(
                'assets/images/products/fresh_cow_milk.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🥛', style: TextStyle(fontSize: 64)),
                ),
              ),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.forestGreen,
                    AppColors.forestGreen.withValues(alpha: 0.95),
                    AppColors.forestGreen.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mediumGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '100% PURE & FRESH',
                    style: TextStyle(
                      color: AppColors.lightGold,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pure Goodness\nfrom Our Farms',
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onShopNow,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Shop Now →',
                      style: TextStyle(
                        color: AppColors.forestGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

