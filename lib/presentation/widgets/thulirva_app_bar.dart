import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final bool roundedBottom;

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
    this.roundedBottom = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.totalItemCount;
    final notifState = ref.watch(notificationProvider);
    final unreadNotifs = notifState.unreadCount;

    final isDarkHeader = backgroundColor == AppColors.forestGreen ||
        backgroundColor == AppColors.darkGreen ||
        backgroundColor == AppColors.deepGreen;

    final iconColor = isDarkHeader ? Colors.white : AppColors.forestGreen;
    final logoAsset = isDarkHeader
        ? 'assets/images/thulirva_brand_logo_white.png'
        : 'assets/images/thulirva_brand_logo.png';

    Widget? leadingWidget = leading;
    if (leadingWidget == null) {
      if (showBack || Navigator.canPop(context)) {
        leadingWidget = IconButton(
          icon: Icon(Icons.arrow_back, color: iconColor, size: 24),
          onPressed: onBack ?? () => Navigator.pop(context),
        );
      } else if (onOpenDrawer != null) {
        leadingWidget = IconButton(
          icon: Icon(Icons.menu, color: iconColor, size: 24),
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
            icon: Icon(Icons.search, color: iconColor, size: 22),
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
              child: Icon(Icons.notifications_none_outlined, color: iconColor, size: 22),
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
              child: Icon(Icons.shopping_cart_outlined, color: iconColor, size: 22),
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
            icon: Icon(Icons.settings_outlined, color: iconColor, size: 22),
            onPressed: onSettingsTap,
          ),
        );
      }
    }

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: isDarkHeader
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      shape: roundedBottom
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
            )
          : null,
      leading: leadingWidget,
      centerTitle: true,
      title: SizedBox(
        height: 38,
        child: Image.asset(
          logoAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, color: iconColor, size: 22),
              const SizedBox(width: 6),
              Text(
                'THULIRVA',
                style: TextStyle(
                  color: iconColor,
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
