import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_permission_service.dart';
import '../../core/utils/delivery_tracking_util.dart';
import '../../core/utils/id_formatter.dart';
import '../../data/models/order_model.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import '../cart/cart_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/customer_live_tracking_screen.dart';
import '../products/product_details_screen.dart';
import '../products/products_list_screen.dart';
import '../location/location_picker_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../widgets/customer_search_bar.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/notification_permission_modal.dart';
import '../widgets/product_card.dart';
import 'widgets/home_category_card.dart';
import 'widgets/promo_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenDrawer;
  final void Function(int tabIndex)? onNavigateToTab;

  const HomeScreen({super.key, this.onOpenDrawer, this.onNavigateToTab});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _notifGranted = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final granted = await NotificationPermissionService.isPermissionGranted();
    if (mounted) {
      setState(() => _notifGranted = granted);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationPermissionModal.showIfEligible(context).then((_) {
          if (mounted) {
            NotificationPermissionService.isPermissionGranted().then((g) {
              if (mounted) setState(() => _notifGranted = g);
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(productProvider.notifier).fetchProducts(),
      ref.read(categoryProvider.notifier).fetchCategories(),
      ref.read(notificationProvider.notifier).fetchNotifications(),
      ref.read(settingsProvider.notifier).fetchSettings(),
      ref.read(subscriptionProvider.notifier).fetchSubscriptions(),
      ref.read(couponProvider.notifier).fetchCoupons(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final addressState = ref.watch(addressProvider);
    final categoryState = ref.watch(categoryProvider);
    final productState = ref.watch(productProvider);
    final notifState = ref.watch(notificationProvider);
    final cartState = ref.watch(cartProvider);
    final settingsState = ref.watch(settingsProvider);
    final subState = ref.watch(subscriptionProvider);
    final couponState = ref.watch(couponProvider);
    final cartCount = cartState.totalItemCount;

    final selectedAddr = addressState.selectedAddress;
    final isUnserviceable = selectedAddr != null && !selectedAddr.isServiceable;

    final displayLocation = (selectedAddr != null && selectedAddr.area.isNotEmpty)
        ? '${selectedAddr.area}, ${selectedAddr.city}'
        : selectedAddr?.city != null
            ? '${selectedAddr!.city}, Tamil Nadu'
            : (user?.address != null && user!.address!.isNotEmpty)
                ? user.address!
                : 'Chennai, Tamil Nadu';

    final pincode = selectedAddr?.pincode.isNotEmpty == true ? selectedAddr!.pincode : '600000';
    final allProducts = productState.allProducts;
    final products = productState.featuredProducts;
    final activeSubs = subState.activeSubscriptions;
    final coupons = couponState.coupons;
    final orderState = ref.watch(orderProvider);

    OrderModel? activeTrackingOrder;
    for (final o in orderState.orders) {
      final s = o.orderStatus.toLowerCase();
      if (!o.isPickup && s != 'delivered' && s != 'cancelled' && s != 'failed') {
        activeTrackingOrder = o;
        break;
      }
    }
    if (activeTrackingOrder == null && activeSubs.isNotEmpty) {
      activeTrackingOrder = activeSubs.first.toOrderModel();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Forest Green Header Container
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(26),
                      bottomRight: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top Row: Menu Button, Thulirva Brand Logo & Title, Notifications Bell, Cart Icon
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                            onPressed: widget.onOpenDrawer,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          // Thulirva Brand Logo (Crisp White & Gold on Forest Green)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/thulirva_brand_logo_white.png',
                              height: 36,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '🌿 THULIRVA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Notification Bell
                          IconButton(
                            icon: Badge(
                              isLabelVisible: notifState.unreadCount > 0,
                              backgroundColor: AppColors.cancelled,
                              label: Text(
                                '${notifState.unreadCount}',
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              child: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 22),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              );
                            },
                          ),
                          // Cart Icon
                          IconButton(
                            icon: Badge(
                              isLabelVisible: cartCount > 0,
                              backgroundColor: AppColors.cancelled,
                              label: Text(
                                '$cartCount',
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Location & PIN Code Selector Bar (Opens Interactive Google Maps Picker)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFE5C97A), size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$displayLocation (PIN: $pincode)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Search Bar: Premium Pill Shape with Focus Halo Animation
                      CustomerSearchBar(
                        controller: _searchController,
                        hintText: 'Search fresh milk, paneer, ghee...',
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                        onClear: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          ref.read(productProvider.notifier).setSearchQuery('');
                        },
                        onFilterTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProductsListScreen()),
                          );
                        },
                        onSubmitted: (query) {
                          if (query.trim().isNotEmpty) {
                            ref.read(productProvider.notifier).setSearchQuery(query.trim());
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductsListScreen(initialSearchQuery: query.trim()),
                              ),
                            );
                          }
                        },
                      ),

                      // Live Search Suggestions Overlay (22px pill radius)
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildLiveSearchSuggestions(allProducts),
                      ],
                    ],
                  ),
                ),

                // Coming Soon / Unserviceable Area Banner
                if (isUnserviceable)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coming Soon to ${selectedAddr.area.isNotEmpty ? selectedAddr.area : 'Your Area'}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Doorstep delivery is not yet available here. You are in browsing mode.',
                                style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Change',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),

                // 2. Body Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notification Reminder Banner if turned off
                      if (!_notifGranted) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0D68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_off_outlined, color: Color(0xFF856404), size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Delivery alerts are off. Turn on to track your fresh farm order in real-time.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF856404), fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => NotificationPermissionModal.showForcePrompt(context).then((_) => _checkNotificationPermission()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.forestGreen,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Enable', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 🛵 LIVE 3D DELIVERY TRACKING BANNER (Direct Access from Home)
                      if (activeTrackingOrder != null) ...[
                        _buildLiveTrackingBanner(context, activeTrackingOrder),
                        const SizedBox(height: 14),
                      ],

                      // Promotional Hero Banner (Auto-sliding)
                      PromoBanner(
                        onShopNow: () {
                          widget.onNavigateToTab?.call(1);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Store Pickup Mode Alert (if active)
                      if (settingsState.isPickupOnly) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF7EB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.forestGreen, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Text('🏪', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'STORE PICKUP MODE ACTIVE',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.forestGreen),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Orders are available for Farm Store Pickup (Free). Doorstep delivery is temporarily paused.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF4A5D4E)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 3. Shop by Category (Placed IMMEDIATELY below Promotional Banner)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shop by Category',
                            style: TextStyle(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: -0.2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => widget.onNavigateToTab?.call(1),
                            child: const Text(
                              'View All →',
                              style: TextStyle(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (categoryState.isLoading && categoryState.categories.isEmpty)
                        const SizedBox(
                          height: 104,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                            ),
                          ),
                        )
                      else if (categoryState.categories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'Loading farm categories...',
                              style: TextStyle(color: Color(0xFF6E8072), fontSize: 13),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 104,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categoryState.categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final cat = categoryState.categories[index];
                              return HomeCategoryCard(category: cat);
                            },
                          ),
                        ),
                      const SizedBox(height: 20),

                      // 4. Dynamic Active Subscription Summary
                      if (activeSubs.isNotEmpty)
                        _buildActiveSubscriptionCard(activeSubs.first)
                      else
                        _buildNoSubscriptionPrompt(),

                      const SizedBox(height: 20),

                      // 5. Offers for You Section (from backend coupons)
                      if (coupons.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Offers for You',
                              style: TextStyle(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: coupons.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              return _buildCouponCard(coupons[index]);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 6. Featured Products Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Featured Products',
                            style: TextStyle(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: -0.2,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProductsListScreen()),
                              );
                            },
                            child: const Text(
                              'View All →',
                              style: TextStyle(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (productState.isLoading && products.isEmpty)
                        const SizedBox(
                          height: 120,
                          child: Center(child: LoadingIndicator(message: 'Loading farm products...')),
                        )
                      else if (productState.errorMessage != null && products.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFF6E8072)),
                                const SizedBox(height: 8),
                                Text(
                                  productState.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF6E8072), fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => ref.read(productProvider.notifier).fetchProducts(),
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
                          ),
                        )
                      else if (products.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Text(
                              'No products available right now.',
                              style: TextStyle(color: Color(0xFF6E8072), fontSize: 13),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                          itemBuilder: (context, index) {
                            return ProductCard(product: products[index]);
                          },
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Active Subscription Summary Card
  Widget _buildActiveSubscriptionCard(SubscriptionModel sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D6B45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDF7EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.repeat, color: AppColors.forestGreen, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'ACTIVE SUBSCRIPTION',
                style: TextStyle(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sub.productName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily Quantity: ${sub.quantity} unit(s) • ${sub.deliverySlot}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF4A5D4E), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 13, color: Color(0xFFE5A93C)),
              const SizedBox(width: 4),
              Text(
                'Next Delivery: ${sub.nextRenewalDate ?? 'Tomorrow 6:00 AM'} • ${sub.daysRemaining > 0 ? '${sub.daysRemaining} days left' : 'Active'}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF6E8072), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(2);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.forestGreen, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'View Subscription Details →',
                style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Milk Subscription Prompt (when customer has no active subscription)
  Widget _buildNoSubscriptionPrompt() {
    return GestureDetector(
      onTap: () {
        if (widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(2);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF174B36), Color(0xFF204D3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.calendar_month, color: Color(0xFFE5C97A), size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Daily Milk Subscription',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Fresh milk delivered daily to your doorstep',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A93C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Subscribe →',
                style: TextStyle(
                  color: AppColors.forestGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Offer / Coupon Card
  Widget _buildCouponCard(dynamic coupon) {
    final code = coupon.code?.toString() ?? 'THULIRVA';
    final badge = coupon.discountBadgeText?.toString() ?? 'OFFER';
    final desc = coupon.description?.toString() ?? 'Special discount';
    final expiry = coupon.expiryDate?.toString() ?? 'Limited time';

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EDE2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9B43B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFF174B36),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              InkWell(
                onTap: () => IdFormatter.copyToClipboard(context, code, label: 'Coupon Code'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF7EB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.forestGreen, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy, size: 11, color: AppColors.forestGreen),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B5B44),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Valid till $expiry',
            style: const TextStyle(fontSize: 10, color: Color(0xFF8A9A7A)),
          ),
        ],
      ),
    );
  }

  // Live Search Suggestions Overlay (22px pill radius)
  Widget _buildLiveSearchSuggestions(List<dynamic> products) {
    final q = _searchQuery.toLowerCase();
    final matches = products.where((p) {
      final name = p.name.toString().toLowerCase();
      final cat = (p.categoryName ?? p.category ?? '').toString().toLowerCase();
      final desc = (p.description ?? '').toString().toLowerCase();
      return name.contains(q) || cat.contains(q) || desc.contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDEBDD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.search_off_rounded, color: Color(0xFF8A9A7A), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No products matching "$_searchQuery". Try "milk", "ghee", "paneer", or "curd".',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6E8072), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...matches.take(5).map((p) {
              return InkWell(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: p)),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7EE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE5EDE2)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (p.fullImageUrl ?? '').toString().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: p.fullImageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.eco, color: AppColors.forestGreen, size: 20),
                              )
                            : const Icon(Icons.eco, color: AppColors.forestGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.forestGreen),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.category} • ${(p.weight ?? "").toString().isNotEmpty ? p.weight : "Pure Farm"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6E8072), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.forestGreen),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8A9A7A)),
                    ],
                  ),
                ),
              );
            }),
            Container(
              width: double.infinity,
              color: const Color(0xFFFAF8EF),
              child: InkWell(
                onTap: () {
                  final query = _searchQuery;
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  ref.read(productProvider.notifier).setSearchQuery(query);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductsListScreen(initialSearchQuery: query),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See all ${matches.length} results for "$_searchQuery"',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.forestGreen),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.forestGreen),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveTrackingBanner(BuildContext context, OrderModel order) {
    final partnerName = (order.partnerName != null && order.partnerName!.trim().isNotEmpty)
        ? order.partnerName!
        : 'Assigned Partner';
    final destination = (order.city.isNotEmpty ? order.city : (order.address.isNotEmpty ? order.address.split(',').first : 'Thiruverkadu')).trim();

    // Centralized dynamic ETA calculation from GPS coordinates
    final etaText = DeliveryTrackingUtil.formatEta(
      order.partnerLatitude,
      order.partnerLongitude,
      order.latitude,
      order.longitude,
    );

    final rawPhoto = order.partnerPhoto;
    final photoUrl = (rawPhoto != null && rawPhoto.trim().isNotEmpty)
        ? ApiEndpoints.resolveImageUrl(rawPhoto)
        : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerLiveTrackingScreen(initialOrder: order),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B4D3E), Color(0xFF0F362A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Partner Avatar or Scooty Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00A859).withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00A859), width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.two_wheeler_rounded,
                        color: Color(0xFF00E676),
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.two_wheeler_rounded,
                      color: Color(0xFF00E676),
                      size: 24,
                    ),
            ),
            const SizedBox(width: 10),
            // Middle Content: Fully Flexible to eliminate any horizontal overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Flexible(
                        child: Text(
                          'LIVE DELIVERY IN PROGRESS',
                          style: TextStyle(
                            color: Color(0xFF86EFAC),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Partner: $partnerName • On the way',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Delivering to $destination • $etaText',
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Track 3D Action Pill with FittedBox
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A859),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A859).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Track 3D',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
