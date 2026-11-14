import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/cart_notification_service.dart';
import '../../data/models/product_model.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/thulirva_app_bar.dart';
import 'customer_subscription_details_screen.dart';
import 'subscribe_modal.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  final int initialTabIndex;

  const SubscriptionsScreen({
    super.key,
    this.onNavigateToTab,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  late int _selectedTabIndex;
  String _selectedCategory = 'All';
  String _mySubFilter = 'All';

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).fetchPlans();
      ref.read(subscriptionProvider.notifier).fetchSubscriptions();
    });
  }

  void _openSubscribeModalWithPlan(SubscriptionPlanModel plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscribeModal(initialPlan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final subs = subState.subscriptions;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: ThulirvaAppBar(
        showBack: Navigator.canPop(context),
        showSearch: false,
        showNotifications: true,
        showCart: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () async {
            await Future.wait([
              ref.read(subscriptionProvider.notifier).fetchPlans(),
              ref.read(subscriptionProvider.notifier).fetchSubscriptions(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Subscription Hero Banner Card (Clean background without duplicate text)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    width: double.infinity,
                    height: 175,
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forestGreen.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Clean Background (milk bottle, glass on wooden table on right, green gradient on left)
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/subscription_clean_bg.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AppColors.forestGreen),
                          ),
                        ),

                        // Banner Content (Rendered EXACTLY ONCE via Flutter Widgets)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.calendar_month, color: Color(0xFFE5C97A), size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Milk\nSubscription',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const SizedBox(
                                width: 200,
                                child: Text(
                                  'Get fresh milk & dairy, delivered daily at your doorstep',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildFeaturePill(Icons.eco, 'Daily Delivery'),
                                  const SizedBox(width: 6),
                                  _buildFeaturePill(Icons.calendar_today, 'Flexible Plans'),
                                  const SizedBox(width: 6),
                                  _buildFeaturePill(Icons.percent, 'Save More'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Segmented Pill Control: [ Subscriptions ] vs [ My Subscriptions ]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE5EDE2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTabIndex = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 0 ? AppColors.forestGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 15,
                                    color: _selectedTabIndex == 0 ? Colors.white : AppColors.forestGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Subscriptions',
                                    style: TextStyle(
                                      color: _selectedTabIndex == 0 ? Colors.white : AppColors.forestGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTabIndex = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 1 ? AppColors.forestGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.list_alt,
                                    size: 15,
                                    color: _selectedTabIndex == 1 ? Colors.white : AppColors.forestGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'My Subscriptions',
                                    style: TextStyle(
                                      color: _selectedTabIndex == 1 ? Colors.white : AppColors.forestGreen,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
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
                ),
                const SizedBox(height: 16),

                // 3. Tab Body
                if (_selectedTabIndex == 0)
                  _buildPlansView()
                else
                  _buildMySubscriptionsView(subs, subState.isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFFE5C97A)),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Browse Subscription Plans
  Widget _buildPlansView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.eco, color: AppColors.forestGreen, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Choose a Subscription Plan',
                    style: TextStyle(
                      color: AppColors.forestGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Direct from farm • Daily pure milk & dairy deliveries',
                style: TextStyle(
                  color: Color(0xFF6E8072),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Category Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All', 'All Plans'),
                const SizedBox(width: 8),
                _buildCategoryChip('Milk', 'Fresh Cow Milk'),
                const SizedBox(width: 8),
                _buildCategoryChip('Paneer', 'Paneer & Ghee'),
                const SizedBox(width: 8),
                _buildCategoryChip('Curd', 'Thick Curd'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Dynamic Horizontal Scrollable List of Plan Cards (Fetched from Backend API)
        Consumer(
          builder: (context, ref, _) {
            final subState = ref.watch(subscriptionProvider);
            final plans = subState.plans;

            if (subState.isLoading && plans.isEmpty) {
              return const SizedBox(
                height: 395,
                child: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
              );
            }

            final filteredPlans = plans.where((p) {
              if (_selectedCategory == 'All') return true;
              final name = p.productName.toLowerCase();
              if (_selectedCategory == 'Milk') return name.contains('milk');
              if (_selectedCategory == 'Paneer') return name.contains('paneer') || name.contains('ghee');
              if (_selectedCategory == 'Curd') return name.contains('curd');
              return true;
            }).toList();

            if (filteredPlans.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: AppColors.forestGreen, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        plans.isEmpty ? 'Loading fresh subscription plans...' : 'No plans in this category',
                        style: const TextStyle(color: Color(0xFF6E8072), fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedCategory = 'All');
                          ref.read(subscriptionProvider.notifier).fetchPlans();
                        },
                        child: const Text('View All Plans', style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 395,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredPlans.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, idx) {
                  final plan = filteredPlans[idx];
                  final isPopular = plan.badge.toLowerCase().contains('popular') || idx == 0;
                  final asset = plan.productName.toLowerCase().contains('1')
                      ? 'assets/images/sub_weekly_bottles.png'
                      : (idx % 2 == 0 ? 'assets/images/sub_daily_glass.png' : 'assets/images/sub_monthly_can.png');

                  return _buildDynamicPlanCard(
                    plan: plan,
                    isMostPopular: isPopular,
                    asset: asset,
                    onSubscribe: () => _openSubscribeModalWithPlan(plan),
                    onAddToCart: () {
                      final prod = ProductModel(
                        id: 'SUB_${plan.id}',
                        name: '${plan.productName} (${plan.durationDays} Days Plan)',
                        category: 'Subscription',
                        price: plan.price,
                        weight: plan.frequency,
                        image: plan.productImage,
                        description: plan.description,
                      );
                      ref.read(cartProvider.notifier).addToCart(prod);
                      CartNotificationService.show(productName: plan.productName, context: context);
                    },
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 18),

        // Why Subscribe? Benefits Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7EB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.savings_outlined, color: AppColors.forestGreen, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Why Subscribe?',
                        style: TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: const [
                          Text('✓ Fresh & hygienic', style: TextStyle(fontSize: 11, color: Color(0xFF3B5B44))),
                          Text('✓ Delivered on time', style: TextStyle(fontSize: 11, color: Color(0xFF3B5B44))),
                          Text('✓ Cancel or modify anytime', style: TextStyle(fontSize: 11, color: Color(0xFF3B5B44))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSel = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? AppColors.forestGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? AppColors.forestGreen : const Color(0xFFD6E2D5),
            width: isSel ? 1.5 : 1,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : AppColors.forestGreen,
            fontSize: 12.5,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicPlanCard({
    required SubscriptionPlanModel plan,
    required bool isMostPopular,
    required String asset,
    required VoidCallback onSubscribe,
    required VoidCallback onAddToCart,
  }) {
    final hasDiscount = plan.discountPercent > 0;
    final hasOriginalPrice = plan.originalPrice != null && plan.originalPrice! > plan.price;
    final networkUrl = ApiEndpoints.resolveImageUrl(plan.productImage ?? '');

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isMostPopular ? AppColors.forestGreen : const Color(0xFFE5EDE2),
          width: isMostPopular ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 135,
            width: double.infinity,
            color: const Color(0xFFFAF7EE),
            child: Stack(
              children: [
                Positioned.fill(
                  child: networkUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: networkUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFFFAF7EE),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Image.asset(
                            asset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.local_drink, color: AppColors.forestGreen, size: 40),
                            ),
                          ),
                        )
                      : Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.local_drink, color: AppColors.forestGreen, size: 40),
                          ),
                        ),
                ),
                // Gradient scrim on top for badge contrast
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Badge (Most Popular / Family Pack / etc)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      plan.badge.isNotEmpty ? plan.badge : 'Popular',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Discount Badge on Right
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5C97A),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${plan.discountPercent}% OFF',
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.productName,
                  style: const TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${plan.timePeriod} • ${plan.frequency}',
                  style: const TextStyle(color: Color(0xFF6E8072), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${plan.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.forestGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hasOriginalPrice) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹${plan.originalPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      ' / ${plan.durationDays}d',
                      style: const TextStyle(
                        color: Color(0xFF6E8072),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          onPressed: onAddToCart,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.forestGreen, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('+ Cart', style: TextStyle(color: AppColors.forestGreen, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: onSubscribe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forestGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Subscribe →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
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
    );
  }

  // Active User Subscriptions View
  Widget _buildMySubscriptionsView(List<SubscriptionModel> subs, bool isLoading) {
    if (isLoading && subs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: LoadingIndicator(message: 'Loading your subscriptions...'),
      );
    }

    if (subs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDF7EB),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.calendar_month_outlined, size: 44, color: AppColors.forestGreen),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Active Subscriptions Yet',
                style: TextStyle(
                  color: AppColors.forestGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Subscribe to daily fresh milk and have farm goodness delivered to your doorstep every morning.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6E8072), fontSize: 13),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedTabIndex = 0),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Explore Subscription Plans'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredSubs = subs.where((s) {
      if (_mySubFilter == 'All') return true;
      final st = s.status.toLowerCase();
      final pst = s.paymentStatus.toLowerCase();
      if (_mySubFilter == 'Pending Approval') {
        return st.contains('pending') || pst.contains('pending') || pst.contains('verification');
      }
      if (_mySubFilter == 'Active') {
        return s.isActive;
      }
      if (_mySubFilter == 'Expired') {
        return s.isExpired;
      }
      if (_mySubFilter == 'Rejected') {
        return s.isRejected;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Chips for Status Classification
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubStatusChip('All', subs.length),
                const SizedBox(width: 8),
                _buildSubStatusChip(
                  'Pending Approval',
                  subs.where((s) => s.status.toLowerCase().contains('pending') || s.paymentStatus.toLowerCase().contains('pending') || s.paymentStatus.toLowerCase().contains('verification')).length,
                ),
                const SizedBox(width: 8),
                _buildSubStatusChip('Active', subs.where((s) => s.isActive).length),
                const SizedBox(width: 8),
                _buildSubStatusChip('Expired', subs.where((s) => s.isExpired).length),
                const SizedBox(width: 8),
                _buildSubStatusChip('Rejected', subs.where((s) => s.isRejected).length),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (filteredSubs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Center(
              child: Text(
                'No subscriptions matching "$_mySubFilter"',
                style: const TextStyle(color: Color(0xFF6E8072), fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredSubs.length,
            itemBuilder: (context, index) {
              final sub = filteredSubs[index];
              final isActive = sub.isActive;
              final isRejected = sub.isRejected;
              final isPending = sub.isPendingApproval;
              final subImg = ApiEndpoints.resolveImageUrl(sub.productImage ?? '');

              Color statusBg = const Color(0xFFE8F5E9);
              Color statusColor = AppColors.forestGreen;
              String statusLabel = sub.status.toUpperCase();

              if (isRejected) {
                statusBg = const Color(0xFFFFEBEE);
                statusColor = AppColors.cancelled;
                statusLabel = 'REJECTED';
              } else if (isPending) {
                statusBg = const Color(0xFFFFF3E0);
                statusColor = AppColors.pending;
                statusLabel = 'PENDING APPROVAL';
              } else if (sub.isExpired) {
                statusBg = const Color(0xFFEEEEEE);
                statusColor = const Color(0xFF757575);
                statusLabel = 'EXPIRED';
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerSubscriptionDetailsScreen(subscription: sub),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRejected
                          ? const Color(0xFFFFCDD2)
                          : (isPending ? const Color(0xFFFFE0B2) : const Color(0xFFE5EDE2)),
                      width: isRejected || isPending ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: const Color(0xFFFAF7EE),
                              child: subImg.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: subImg,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(Icons.local_drink, color: AppColors.forestGreen, size: 28),
                                    )
                                  : const Icon(Icons.local_drink, color: AppColors.forestGreen, size: 28),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.productName.isNotEmpty ? sub.productName : 'Fresh Cow Milk',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${sub.frequency} • Qty: ${sub.quantity} • Sub ID: ${sub.id}',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF6E8072), fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Rejection Alert Box (if rejected by Admin)
                      if (isRejected && (sub.rejectionReason != null && sub.rejectionReason!.isNotEmpty)) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, size: 15, color: AppColors.cancelled),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Rejected: ${sub.rejectionReason}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.cancelled, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Schedule, Slot & Address Box
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBF8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5EDE2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: AppColors.forestGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Slot: ${sub.deliverySlot}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF4A5D4E)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: sub.paymentStatus.toLowerCase().contains('verif') || sub.paymentStatus.toLowerCase() == 'paid'
                                        ? const Color(0xFFE8F5E9)
                                        : const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sub.paymentStatus.toLowerCase().contains('verif') ? 'Verified' : 'Payment: ${sub.paymentStatus}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: sub.paymentStatus.toLowerCase().contains('verif') ? AppColors.forestGreen : AppColors.pending,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: AppColors.forestGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Started: ${sub.startDate} • ${sub.daysRemaining > 0 ? '${sub.daysRemaining} days left' : 'Expired'}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF4A5D4E)),
                                  ),
                                ),
                              ],
                            ),
                            if (sub.address.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.forestGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      sub.address,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6E8072)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Plan Price', style: TextStyle(fontSize: 10.5, color: Color(0xFF6E8072))),
                              Text(
                                '₹${sub.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CustomerSubscriptionDetailsScreen(subscription: sub),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined, size: 14),
                                label: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.forestGreen,
                                  side: const BorderSide(color: Color(0xFFC8E6C9)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isActive)
                                OutlinedButton(
                                  onPressed: () async {
                                    await ref.read(subscriptionProvider.notifier).pauseSubscription(sub.id);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.pending,
                                    side: const BorderSide(color: AppColors.pending),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  child: const Text('Pause', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                )
                              else if (!isRejected && !sub.isExpired)
                                ElevatedButton(
                                  onPressed: () async {
                                    await ref.read(subscriptionProvider.notifier).resumeSubscription(sub.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.forestGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  child: const Text('Resume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSubStatusChip(String label, int count) {
    final isSel = _mySubFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _mySubFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? AppColors.forestGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? AppColors.forestGreen : const Color(0xFFD6E2D5),
            width: isSel ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSel ? Colors.white : AppColors.forestGreen,
            fontSize: 11.5,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
