import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../cart/cart_screen.dart';
import '../notifications/notifications_screen.dart';
import '../products/products_list_screen.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/product_card.dart';
import 'widgets/category_bubble.dart';
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
    final cartCount = cartState.totalItemCount;

    final displayLocation = addressState.selectedAddress?.city != null
        ? '${addressState.selectedAddress!.city}, Tamil Nadu ${addressState.selectedAddress!.pincode}'
        : (user?.address != null && user!.address!.isNotEmpty)
            ? user.address!
            : 'Chennai, Tamil Nadu 600119';

    final products = productState.featuredProducts;

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Mockup Screen 4: Solid Forest Green Header Container
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Location Pin & Icons Row
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                            onPressed: widget.onOpenDrawer,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chennai, Tamil Nadu',
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  '600119',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Notification Action Icon
                          IconButton(
                            icon: Badge(
                              isLabelVisible: notifState.unreadCount > 0,
                              backgroundColor: AppColors.cancelled,
                              label: Text(
                                '${notifState.unreadCount}',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
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
                          // Direct Cart Action Icon
                          IconButton(
                            icon: Badge(
                              isLabelVisible: cartCount > 0,
                              backgroundColor: AppColors.cancelled,
                              label: Text(
                                '$cartCount',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 22),
                            ),
                            onPressed: () {
                              if (widget.onNavigateToTab != null) {
                                widget.onNavigateToTab!(2);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Rounded White Search Bar Pill
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (query) {
                            ref.read(productProvider.notifier).setSearchQuery(query);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductsListScreen(initialSearchQuery: query),
                              ),
                            );
                          },
                          decoration: InputDecoration(
                            hintText: 'Search for milk, paneer, ghee...',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(productProvider.notifier).setSearchQuery('');
                                    },
                                  )
                                : const Icon(Icons.tune, color: AppColors.textMuted, size: 18),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Body Content on Light Cream Background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Promotional Banner
                      PromoBanner(
                        onShopNow: () {
                          widget.onNavigateToTab?.call(1);
                        },
                      ),

                      if (settingsState.isPickupOnly) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.forestGreen, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Text('🏪', style: TextStyle(fontSize: 24)),
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
                                      style: TextStyle(fontSize: 11.5, color: AppColors.textMid),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Categories Section (Mockup 4x2 Grid)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categories',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => widget.onNavigateToTab?.call(1),
                            child: Text(
                              'View All',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (categoryState.isLoading && categoryState.categories.isEmpty)
                        const SizedBox(
                          height: 80,
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
                              'Categories loading from farm server...',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categoryState.categories.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (context, index) {
                            final cat = categoryState.categories[index];
                            return CategoryBubble(
                              category: cat,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductsListScreen(categoryName: cat.name),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 18),

                      // Featured Products Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured Products',
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProductsListScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (productState.isLoading && products.isEmpty)
                        const SizedBox(height: 200, child: LoadingIndicator(message: 'Loading fresh farm products...'))
                      else if (products.isEmpty)
                        const EmptyStateView(
                          title: 'No Products Found',
                          message: 'Fresh products are being updated from the farm.',
                          emoji: '🥛',
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            return ProductCard(
                              product: products[index],
                              showAddText: true,
                            );
                          },
                        ),
                      const SizedBox(height: 24),
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
}

