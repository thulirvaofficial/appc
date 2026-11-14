import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/coupon_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';

class ApplyCouponScreen extends ConsumerStatefulWidget {
  const ApplyCouponScreen({super.key});

  @override
  ConsumerState<ApplyCouponScreen> createState() => _ApplyCouponScreenState();
}

class _ApplyCouponScreenState extends ConsumerState<ApplyCouponScreen> {
  final TextEditingController _couponInputController = TextEditingController();
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    final currentCode = ref.read(cartProvider).appliedCouponCode;
    if (currentCode != null) {
      _couponInputController.text = currentCode;
    }
  }

  @override
  void dispose() {
    _couponInputController.dispose();
    super.dispose();
  }

  Future<void> _handleApplyCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coupon code'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final cartNotifier = ref.read(cartProvider.notifier);
    final success = await cartNotifier.applyCoupon(code);
    if (!mounted) return;
    setState(() => _isVerifying = false);

    final cartState = ref.read(cartProvider);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Coupon "$code" applied! Saved ₹${cartState.discountAmount.toStringAsFixed(0)}'),
          backgroundColor: AppColors.forestGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartState.couponMessage ?? 'Invalid or expired coupon code.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final couponState = ref.watch(couponProvider);
    final hasCoupon = cartState.appliedCouponCode != null;
    final coupons = couponState.coupons;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7EE),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.forestGreen),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Apply Coupon',
            style: TextStyle(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          actions: [
            if (hasCoupon)
              TextButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).removeCoupon();
                  _couponInputController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Coupon removed from cart.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. DEDICATED PROMINENT INPUT BOX (Always interactive)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.confirmation_number_outlined, color: AppColors.forestGreen, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Have a Promo or Coupon Code?',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.forestGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Type your coupon code below to unlock instant discounts.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6E8072)),
                      ),
                      const SizedBox(height: 14),

                      // Input Field & Apply Button Row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: TextField(
                                controller: _couponInputController,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.8),
                                decoration: InputDecoration(
                                  hintText: 'ENTER CODE (e.g. THULIRVA10)',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA0AFA2), fontWeight: FontWeight.w500),
                                  prefixIcon: const Icon(Icons.discount_outlined, color: AppColors.forestGreen, size: 20),
                                  suffixIcon: _couponInputController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                          onPressed: () {
                                            _couponInputController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  filled: true,
                                  fillColor: const Color(0xFFFAF7EE),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFD4E5CF)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFD4E5CF)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                                onSubmitted: _handleApplyCode,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isVerifying || cartState.isApplyingCoupon
                                  ? null
                                  : () => _handleApplyCode(_couponInputController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forestGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                              ),
                              child: _isVerifying || cartState.isApplyingCoupon
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('APPLY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                            ),
                          ),
                        ],
                      ),

                      // Applied Coupon Card
                      if (hasCoupon) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF7EB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF81C784)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Coupon "${cartState.appliedCouponCode}" Applied',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), fontSize: 13.5),
                                    ),
                                    Text(
                                      'Saved ₹${cartState.discountAmount.toStringAsFixed(0)} • Payable: ₹${cartState.grandTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.read(cartProvider.notifier).removeCoupon();
                                  _couponInputController.clear();
                                },
                                child: const Text('REMOVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 2. AVAILABLE COUPONS SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Offers & Coupons',
                      style: TextStyle(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (couponState.isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                      )
                    else
                      Text(
                        '${coupons.length} Available',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6E8072)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content State Switcher
                if (couponState.isLoading && coupons.isEmpty)
                  _buildLoadingSkeleton()
                else if (couponState.errorMessage != null && coupons.isEmpty)
                  _buildErrorState(couponState.errorMessage!)
                else if (coupons.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: coupons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = coupons[index];
                      final isApplied = cartState.appliedCouponCode?.toUpperCase() == c.code.toUpperCase();
                      return _buildCouponCard(c, isApplied);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCard(CouponModel c, bool isApplied) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isApplied ? const Color(0xFF81C784) : const Color(0xFFE5EDE2),
          width: isApplied ? 1.8 : 1.2,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF7EB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Text(
                  c.discountBadgeText,
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
              if (c.minOrder > 0)
                Text(
                  'Min Order: ₹${c.minOrder.toInt()}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF6E8072), fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            c.description,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7EE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5EDE2)),
                ),
                child: Text(
                  c.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.forestGreen,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (isApplied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✓ APPLIED',
                    style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    _couponInputController.text = c.code;
                    _handleApplyCode(c.code);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EDE2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 80, height: 18, decoration: BoxDecoration(color: const Color(0xFFECEFEA), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 10),
            Container(width: double.infinity, height: 14, decoration: BoxDecoration(color: const Color(0xFFF1F4EF), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(width: 180, height: 14, decoration: BoxDecoration(color: const Color(0xFFF1F4EF), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 100, height: 28, decoration: BoxDecoration(color: const Color(0xFFECEFEA), borderRadius: BorderRadius.circular(6))),
                Container(width: 70, height: 32, decoration: BoxDecoration(color: const Color(0xFFECEFEA), borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDE2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.orange, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6E8072), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => ref.read(couponProvider.notifier).fetchCoupons(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDE2)),
      ),
      child: Column(
        children: const [
          Icon(Icons.local_offer_outlined, color: Color(0xFFB0C4B5), size: 42),
          SizedBox(height: 10),
          Text(
            'No Public Coupons Available',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.forestGreen),
          ),
          SizedBox(height: 4),
          Text(
            'You can still type any valid promotional or referral code above to claim your discount.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF6E8072)),
          ),
        ],
      ),
    );
  }
}
