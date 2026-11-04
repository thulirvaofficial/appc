import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
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
import '../products/product_details_screen.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/notification_permission_modal.dart';
import '../../core/services/notification_permission_service.dart';
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
        ? '${addressState.selectedAddress!.city}, Tamil Nadu'
        : (user?.address != null && user!.address!.isNotEmpty)
            ? user.address!
            : 'Chennai, Tamil Nadu';

    final pincode = addressState.selectedAddress?.pincode ?? '600119';
    final products = productState.featuredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
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
                      // Header Row: Menu, Location Dropdown, Notifications, Cart
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                            onPressed: widget.onOpenDrawer,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on, color: Color(0xFFE5C97A), size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayLocation,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                                  ],
                                ),
                                Text(
                                  'PIN: $pincode',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

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
                              if (widget.onNavigateToTab != null) {
                                widget.onNavigateToTab!(3); // Cart is index 3
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

                      // Pill Search Bar with Live Suggestions
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
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
                          decoration: InputDecoration(
                            hintText: 'Search fresh milk, paneer, ghee...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF8A9A7A),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF8A9A7A), size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                      ref.read(productProvider.notifier).setSearchQuery('');
                                    },
                                  )
                                : const Icon(Icons.tune, color: Color(0xFF8A9A7A), size: 18),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),

                      // Live Search Suggestions Overlay (Swiggy / Flipkart style)
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildLiveSearchSuggestions(products),
                      ],
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

                      // Promo Hero Banner
                      PromoBanner(
                        onShopNow: () {
                          widget.onNavigateToTab?.call(1);
                        },
                      ),
                      const SizedBox(height: 14),

                      // 4-Feature Chips Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFeatureItem(Icons.schedule, 'Daily\nDelivery'),
                          _buildFeatureItem(Icons.calendar_month, 'Flexible\nSubscription'),
                          _buildFeatureItem(Icons.verified_outlined, 'Quality\nAssured'),
                          _buildFeatureItem(Icons.nature_outlined, 'Farm\nto Home'),
                        ],
                      ),

                      // Pickup Only Notice (if active)
                      if (settingsState.isPickupOnly) ...[
                        const SizedBox(height: 14),
                        Container(
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
                      const SizedBox(height: 18),

                      // Categories Section (Grid)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Categories',
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
                              'Loading farm categories...',
                              style: TextStyle(color: Color(0xFF6E8072), fontSize: 13),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categoryState.categories.length > 8 ? 8 : categoryState.categories.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.76,
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

                      // Subscription Promo Card
                      GestureDetector(
                        onTap: () => widget.onNavigateToTab?.call(2), // Switch to Subscription tab
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B4332), Color(0xFF2D6B45)],
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
                      ),
                      const SizedBox(height: 20),

                      // Featured Products Section
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EDE2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.forestGreen, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF3B5B44),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  // Live Search Suggestions Overlay (Swiggy / Flipkart style)
  Widget _buildLiveSearchSuggestions(List<dynamic> products) {
    final q = _searchQuery.toLowerCase();
    final matches = products.where((p) {
      final name = p.name.toString().toLowerCase();
      final cat = (p.categoryName ?? '').toString().toLowerCase();
      final desc = (p.description ?? '').toString().toLowerCase();
      return name.contains(q) || cat.contains(q) || desc.contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  const Icon(Icons.search_off, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No products matching "$_searchQuery". Try "milk", "ghee", or "paneer".',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6E8072)),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ...matches.take(4).map((p) {
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF7EB),
                          borderRadius: BorderRadius.circular(8),
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
                            Text(
                              (p.weight ?? '').toString().isNotEmpty ? p.weight : 'Fresh produce',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF6E8072)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.forestGreen),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              );
            }),
            Container(
              width: double.infinity,
              color: const Color(0xFFFAF7EE),
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
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See all ${matches.length} results for "$_searchQuery"',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.forestGreen),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 14, color: AppColors.forestGreen),
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
}
