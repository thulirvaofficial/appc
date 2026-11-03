import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../cart/cart_screen.dart';
import '../notifications/notifications_screen.dart';

class ThulirvaAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onOpenDrawer;
  final bool showSearch;
  final VoidCallback? onSearchTap;
  final bool showCart;
  final bool showNotifications;
  final bool showSettings;
  final VoidCallback? onSettingsTap;
  final List<Widget>? customActions;
  final Color backgroundColor;

  const ThulirvaAppBar({
    super.key,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.onOpenDrawer,
    this.showSearch = false,
    this.onSearchTap,
    this.showCart = true,
    this.showNotifications = false,
    this.showSettings = false,
    this.onSettingsTap,
    this.customActions,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.totalItemCount;
    final notifState = ref.watch(notificationProvider);
    final unreadNotifs = notifState.unreadCount;

    Widget? leadingWidget = leading;
    if (leadingWidget == null) {
      if (showBack || Navigator.canPop(context)) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.forestGreen, size: 24),
          onPressed: onBack ?? () => Navigator.pop(context),
        );
      } else if (onOpenDrawer != null) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.menu, color: AppColors.forestGreen, size: 24),
          onPressed: onOpenDrawer,
        );
      }
    }

    final actions = <Widget>[];

    if (customActions != null) {
      actions.addAll(customActions!);
    } else {
      if (showSearch) {
        actions.add(
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.forestGreen, size: 22),
            onPressed: onSearchTap,
          ),
        );
      }

      if (showNotifications) {
        actions.add(
          IconButton(
            icon: Badge(
              isLabelVisible: unreadNotifs > 0,
              backgroundColor: AppColors.cancelled,
              label: Text(
                '$unreadNotifs',
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
              ),
              child: const Icon(Icons.notifications_none_outlined, color: AppColors.forestGreen, size: 22),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
        );
      }

      if (showCart) {
        actions.add(
          IconButton(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              backgroundColor: AppColors.cancelled,
              label: Text(
                '$cartCount',
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
              ),
              child: const Icon(Icons.shopping_cart_outlined, color: AppColors.forestGreen, size: 22),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        );
      }

      if (showSettings) {
        actions.add(
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.forestGreen, size: 22),
            onPressed: onSettingsTap,
          ),
        );
      }
    }

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leadingWidget,
      centerTitle: true,
      title: SizedBox(
        height: 38,
        child: Image.asset(
          'assets/images/thulirva_brand_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.eco, color: AppColors.forestGreen, size: 22),
              SizedBox(width: 6),
              Text(
                'THULIRVA',
                style: TextStyle(
                  color: AppColors.forestGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: actions,
    );
  }
}

