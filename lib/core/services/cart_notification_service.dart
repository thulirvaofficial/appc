import 'dart:async';
import 'package:flutter/material.dart';
import '../../presentation/cart/cart_screen.dart';
import '../constants/app_colors.dart';
import 'firebase_notification_service.dart';

/// Global Cart Notification Service that displays a sleek floating notification
/// with "VIEW CART" action, automatically dismisses after exactly 3 seconds,
/// resets the timer on subsequent items, and ensures reliable navigation from anywhere.
class CartNotificationService {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;
  static final ValueNotifier<String> _productNameNotifier = ValueNotifier<String>('');
  static bool _isNavigating = false;

  /// Shows the Cart Notification bar above the bottom navigation bar.
  /// If already visible, smoothly updates product name and restarts the 3-second timer.
  static void show({required String productName, BuildContext? context}) {
    _productNameNotifier.value = productName;

    // Reset 3-second auto-dismissal timer
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      hide();
    });

    if (_currentEntry != null) {
      // Overlay is active; ValueListenableBuilder will update product name dynamically
      return;
    }

    final overlayState = rootNavigatorKey.currentState?.overlay ??
        (context != null ? Overlay.of(context) : null);

    if (overlayState == null) return;

    _currentEntry = OverlayEntry(
      builder: (ctx) => _CartNotificationWidget(
        productNameNotifier: _productNameNotifier,
        onViewCart: () => _navigateToCart(ctx),
      ),
    );

    overlayState.insert(_currentEntry!);
  }

  /// Instantly hides and disposes the notification overlay
  static void hide() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      _currentEntry?.remove();
      _currentEntry = null;
    }
  }

  /// Safely navigates to the CartScreen preserving state and preventing duplicates
  static void _navigateToCart(BuildContext context) {
    if (_isNavigating) return;
    _isNavigating = true;

    hide();

    final navState = rootNavigatorKey.currentState;
    if (navState != null) {
      navState.push(
        MaterialPageRoute(
          builder: (_) => const CartScreen(),
          settings: const RouteSettings(name: '/cart'),
        ),
      ).then((_) {
        _isNavigating = false;
      });
    } else {
      _isNavigating = false;
    }
  }
}

class _CartNotificationWidget extends StatefulWidget {
  final ValueNotifier<String> productNameNotifier;
  final VoidCallback onViewCart;

  const _CartNotificationWidget({
    required this.productNameNotifier,
    required this.onViewCart,
  });

  @override
  State<_CartNotificationWidget> createState() => _CartNotificationWidgetState();
}

class _CartNotificationWidgetState extends State<_CartNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 74, // Positioned comfortably above the bottom navigation bar
      child: SlideTransition(
        position: _offsetAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.forestGreen, // #174735 Forest Green
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: widget.productNameNotifier,
                builder: (context, productName, _) {
                  return Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$productName added to cart!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: widget.onViewCart,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'VIEW CART',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.gold,
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
