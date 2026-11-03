import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/coupon_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_indicator.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponState = ref.watch(couponProvider);
    final coupons = couponState.coupons;

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text('Offers & Promo Codes', style: AppTypography.displaySmall.copyWith(fontSize: 18)),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () => ref.read(couponProvider.notifier).fetchCoupons(),
          child: couponState.isLoading && coupons.isEmpty
              ? const LoadingIndicator(message: 'Loading active offers...')
              : coupons.isEmpty
                  ? EmptyStateView(
                      title: 'No Active Offers',
                      message: 'Check back soon for festive farm discounts and promo codes.',
                      emoji: '🎟️',
                      buttonText: 'Refresh',
                      onButtonPressed: () => ref.read(couponProvider.notifier).fetchCoupons(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: coupons.length,
                      itemBuilder: (context, index) {
                        final coupon = coupons[index];
                        return _buildCouponCard(context, ref, coupon);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, WidgetRef ref, CouponModel coupon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.softGreen, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.paleGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.softGreen),
                ),
                child: Text(
                  coupon.discountBadgeText,
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                coupon.minOrder > 0 ? 'Min Order: ₹${coupon.minOrder.toInt()}' : 'No Min Order',
                style: const TextStyle(color: AppColors.textLight, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            coupon.description,
            style: AppTypography.titleSmall.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Valid till ${coupon.expiryDate}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lightCream,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  coupon.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.forestGreen,
                    letterSpacing: 1,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: coupon.code));
                    ref.read(cartProvider.notifier).applyCoupon(coupon.code);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Code ${coupon.code} copied and applied to cart!'),
                        backgroundColor: AppColors.forestGreen,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '📋 Copy Code',
                      style: TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.w700, fontSize: 11.5),
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

