import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/notification_provider.dart';
import '../cart/cart_screen.dart';
import '../notifications/notifications_screen.dart';

class NoInternetScreen extends ConsumerStatefulWidget {
  final VoidCallback? onRetrySuccess;
  final VoidCallback? onOpenDrawer;
  final bool showBottomNav;
  final int currentTabIndex;
  final ValueChanged<int>? onSelectTab;

  const NoInternetScreen({
    super.key,
    this.onRetrySuccess,
    this.onOpenDrawer,
    this.showBottomNav = false,
    this.currentTabIndex = 0,
    this.onSelectTab,
  });

  @override
  ConsumerState<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends ConsumerState<NoInternetScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleRetry() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(connectivityProvider.notifier).retryConnection();

      if (mounted) {
        if (success) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
          });
          widget.onRetrySuccess?.call();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Still unable to connect. Please check your internet connection and try again.';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Still unable to connect. Please check your internet connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final notifState = ref.watch(notificationProvider);
    final cartCount = cartState.totalItemCount;
    final unreadNotifs = notifState.unreadCount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.forestGreen,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8EF),
        body: Column(
          children: [
            // 1. Dark-Green Branded Top Header (Seamless status bar with 26px bottom curves)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Perfectly Centered Circular Emblem & Brand Logo (Matches Reference Artwork Exactly)
                        Center(
                          child: Image.asset(
                            'assets/images/thulirva_brand_logo_white.png',
                            height: 38,
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

                        // Hamburger Menu on Far Left
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                            onPressed: widget.onOpenDrawer,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),

                        // Notification Bell and Cart Icon with Badge on Far Right
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Badge(
                                  isLabelVisible: unreadNotifs > 0,
                                  backgroundColor: AppColors.cancelled,
                                  label: Text(
                                    '$unreadNotifs',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Badge(
                                  isLabelVisible: cartCount > 0,
                                  backgroundColor: AppColors.cancelled,
                                  label: Text(
                                    '$cartCount',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Scrollable Body: Anime Artwork, Title, Description, and Try Again Button
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Exact Anime Illustration (Girl in pink kurti with phone, calf, milk can, wifi bubble, farm)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: Image.asset(
                        'assets/images/no_internet_anime.png',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => const Padding(
                          padding: EdgeInsets.all(40),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 100,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Heading: "No Internet Connection"
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No Internet Connection',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.forestGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle Description
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                        "We couldn't reach the server. Please check your internet connection and try again.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.cancelled, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.cancelled,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Dark-Green Rounded "Try Again" Button with Refresh Icon
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Connecting...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Try Again',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // 3. Optional Bottom Navigation Bar (matches reference image if shown standalone)
            if (widget.showBottomNav) _buildStandaloneBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildStandaloneBottomNav() {
    return Container(
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
              _buildNavItem(0, 'Home', Icons.home_outlined, Icons.home),
              _buildNavItem(1, 'Categories', Icons.grid_view_outlined, Icons.grid_view),
              _buildNavItem(2, 'Subscriptions', Icons.calendar_month_outlined, Icons.calendar_month),
              _buildNavItem(3, 'Orders', Icons.receipt_long_outlined, Icons.receipt_long),
              _buildNavItem(4, 'Profile', Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, IconData activeIcon) {
    final isSelected = widget.currentTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => widget.onSelectTab?.call(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDDF0D6) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.forestGreen : const Color(0xFF6B7280),
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.forestGreen : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

