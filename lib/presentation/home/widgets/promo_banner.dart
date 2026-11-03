import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PromoBanner extends StatelessWidget {
  final VoidCallback onShopNow;

  const PromoBanner({super.key, required this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 165,
      decoration: BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Clean Farm Background (cows, bottle, ghee on right; green gradient on left - NO text)
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_clean_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.forestGreen),
            ),
          ),

          // Banner Content (Rendered EXACTLY ONCE via Flutter Widgets)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // "100% PURE & FRESH" Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '100% PURE & FRESH',
                    style: TextStyle(
                      color: Color(0xFFF7D97B),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Headline
                const Text(
                  'Pure Goodness\nfrom Our Farms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 10),

                // Shop Now Button
                InkWell(
                  onTap: onShopNow,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A93C),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Shop Now',
                          style: TextStyle(
                            color: AppColors.forestGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 13, color: AppColors.forestGreen),
                      ],
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
