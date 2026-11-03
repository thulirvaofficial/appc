import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/cart_provider.dart';
import 'cart/cart_screen.dart';
import 'categories/categories_screen.dart';
import 'home/home_screen.dart';
import 'orders/my_orders_screen.dart';
import 'profile/profile_screen.dart';
import 'subscriptions/subscriptions_screen.dart';
import 'widgets/side_menu_drawer.dart';

class MainWrapper extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainWrapper({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.totalItemCount;

    final screens = [
      HomeScreen(onOpenDrawer: openDrawer, onNavigateToTab: _onTabTapped),
      CategoriesScreen(onNavigateToTab: _onTabTapped),
      SubscriptionsScreen(onNavigateToTab: _onTabTapped),
      CartScreen(onContinueShopping: () => _onTabTapped(0)),
      MyOrdersScreen(onShopNow: () => _onTabTapped(0)),
      ProfileScreen(onSelectTab: _onTabTapped),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.lightCream,
      drawer: SideMenuDrawer(onSelectTab: _onTabTapped),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE5EDE2), width: 1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Categories',
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Subscription',
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Cart',
                  icon: Icons.shopping_cart_outlined,
                  activeIcon: Icons.shopping_cart,
                  badgeCount: cartCount,
                ),
                _buildNavItem(
                  index: 4,
                  label: 'Orders',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                ),
                _buildNavItem(
                  index: 5,
                  label: 'Profile',
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDDF0D6) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              backgroundColor: AppColors.cancelled,
              label: Text(
                '$badgeCount',
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.forestGreen : const Color(0xFF6E8072),
                size: 21,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.forestGreen : const Color(0xFF6E8072),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
