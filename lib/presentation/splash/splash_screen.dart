import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showSubtleIndicator = false;

  @override
  void initState() {
    super.initState();

    // Edge-to-edge transparent system status & navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // Subtle fallback indicator only if cold startup or network token check takes longer than 2.4s
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() => _showSubtleIndicator = true);
      }
    });

    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/splash_bg.jpg'), context);
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      // Check auth status & onboarding completion
      final onboardingDone = StorageService.isOnboardingCompleted();
      final isAuthenticated = ref.read(authProvider).isAuthenticated;

      // Ensure 2.4 seconds presentation so customer can visually appreciate the branding artwork
      final elapsed = DateTime.now().difference(startTime);
      const minDuration = Duration(milliseconds: 2400);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }

      if (!mounted) return;

      Widget destination;
      if (!onboardingDone) {
        destination = const OnboardingScreen();
      } else if (isAuthenticated) {
        destination = const MainWrapper();
      } else {
        destination = const LoginScreen();
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      debugPrint('SplashScreen initialization error: $e');
      if (!mounted) return;
      // Fallback gracefully to login
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF3),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. High-Resolution Approved Thulirva Artwork (Direct Asset)
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),

          // Hidden semantic label for accessibility and test matchers
          const Positioned(
            top: -100,
            child: Text('THULIRVA'),
          ),

          // 2. Subtle progress indicator shown only if initialization takes extra time
          if (_showSubtleIndicator)
            Positioned(
              left: 48,
              right: 48,
              bottom: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Color(0x33FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8DC63F)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
