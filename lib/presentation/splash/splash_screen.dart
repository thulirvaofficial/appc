import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../main_wrapper.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();

    // Clean transparent status bar with dark icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    // Continuous smooth spinning animation for the loading circle
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Show smooth rotating loader for 2.8 seconds
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final onboardingDone = StorageService.isOnboardingCompleted();
    final isAuthenticated = ref.read(authProvider).isAuthenticated;

    if (!onboardingDone) {
      // Rule: Only on first time app opening show the onboarding screens
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else if (isAuthenticated) {
      // Returning logged in customer -> Home
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainWrapper(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      // Returning user not logged in -> Login Screen directly (no onboarding)
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF3),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. High-Resolution User-Uploaded Splash Screen Artwork
              Image.asset(
                'assets/images/splash_bg.jpg',
                fit: BoxFit.cover,
                width: width,
                height: height,
              ),

              // Semantics / Test finder
              const Positioned(
                top: -100,
                child: Text('THULIRVA'),
              ),

              // 2. Real Rotating Circular Loading Animation (User request: "cirle cirle roatte")
              Positioned(
                top: height * 0.825,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth rotating loader placed right over the circle position
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEFBF3).withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF143823).withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: RotationTransition(
                          turns: _spinController,
                          child: const CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF143823)),
                            backgroundColor: Color(0xFFD6E4DB),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Loading...',
                        style: TextStyle(
                          color: Color(0xFF143823),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
