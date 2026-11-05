import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/coupon_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    final activeCode = ref.read(cartProvider).appliedCouponCode;
    if (activeCode != null) {
      _codeCtrl.text = activeCode;
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCustomCode(String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isVerifying = true);
    final ok = await ref.read(cartProvider.notifier).applyCoupon(code);
    if (!mounted) return;
    setState(() => _isVerifying = false);

    final cartState = ref.read(cartProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? '✓ Coupon "$code" applied! Saved ₹${cartState.discountAmount.toStringAsFixed(0)}'
            : (cartState.couponMessage ?? 'Invalid or expired coupon code')),
        backgroundColor: ok ? AppColors.forestGreen : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final couponState = ref.watch(couponProvider);
    final cartState = ref.watch(cartProvider);
    final coupons = couponState.coupons;
    final hasCoupon = cartState.appliedCouponCode != null;

    final defaultCoupons = [
      CouponModel(
        id: 1,
        code: 'THULIRVA10',
        description: 'Get 10% instant discount on all pure farm fresh milk & dairy orders.',
        discountType: 'percent',
        discountValue: 10,
        minOrder: 199,
        expiryDate: '31 Dec 2026',
      ),
      CouponModel(
        id: 2,
        code: 'FARM50',
        description: 'Flat ₹50 OFF on orders above ₹499. Valid on raw bilona ghee and paneer.',
        discountType: 'flat',
        discountValue: 50,
        minOrder: 499,
        expiryDate: '31 Dec 2026',
      ),
      CouponModel(
        id: 3,
        code: 'FREESHIP',
        description: 'Free doorstep early morning delivery across all serviceable PIN codes.',
        discountType: 'flat',
        discountValue: 40,
        minOrder: 150,
        expiryDate: '31 Dec 2026',
      ),
    ];

    final displayCoupons = coupons.isNotEmpty ? coupons : defaultCoupons;

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text('Offers & Promo Codes', style: AppTypography.displaySmall.copyWith(fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () => ref.read(couponProvider.notifier).fetchCoupons(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Top Dedicated Promo Code Input Card
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Have a Promo Code?',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.forestGreen),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: TextField(
                              controller: _codeCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, letterSpacing: 0.8),
                              decoration: InputDecoration(
                                hintText: 'Enter Coupon Code',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA0AFA2)),
                                prefixIcon: const Icon(Icons.discount_outlined, color: AppColors.forestGreen, size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                filled: true,
                                fillColor: const Color(0xFFFAF7EE),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD4E5CF)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD4E5CF)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.5),
                                ),
                              ),
                              onSubmitted: _applyCustomCode,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isVerifying ? null : () => _applyCustomCode(_codeCtrl.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forestGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            child: _isVerifying
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('APPLY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    if (hasCoupon) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF7EB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '✓ "${cartState.appliedCouponCode}" Applied (-₹${cartState.discountAmount.toStringAsFixed(0)})',
                                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                ref.read(cartProvider.notifier).removeCoupon();
                                _codeCtrl.clear();
                              },
                              child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Available Offers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
              ),
              const SizedBox(height: 12),

              ...displayCoupons.map((coupon) => _buildCouponCard(context, ref, coupon, cartState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, WidgetRef ref, CouponModel coupon, CartState cartState) {
    final isApplied = cartState.appliedCouponCode?.toUpperCase() == coupon.code.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isApplied ? const Color(0xFF81C784) : AppColors.softGreen,
          width: isApplied ? 1.8 : 1.2,
        ),
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
                if (isApplied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('✓ APPLIED', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: 11)),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      _codeCtrl.text = coupon.code;
                      _applyCustomCode(coupon.code);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('APPLY', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
