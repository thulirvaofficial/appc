import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/storage_service.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _onboardingImages = [
    'assets/images/onboarding_1.jpg',
    'assets/images/onboarding_2.jpg',
    'assets/images/onboarding_3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    // Save flag so onboarding NEVER shows again on future app opens
    await StorageService.setOnboardingCompleted();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _onboardingImages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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
              // 1. Swipeable Full-Bleed 3 Onboarding Screens
              PageView.builder(
                controller: _pageController,
                itemCount: _onboardingImages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return Image.asset(
                    _onboardingImages[index],
                    fit: BoxFit.cover,
                    width: width,
                    height: height,
                  );
                },
              ),

              // 2. Top Bar: Subtle Skip Button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 16,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0x33143823)),
                    ),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF143823),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              // 3. Interactive Next Button positioned right over the green circle with arrow
              // Screen coordinates: right ~14%, top ~75.5% to 78.5%
              Positioned(
                top: height * 0.74,
                right: width * 0.08,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _onNext,
                    customBorder: const CircleBorder(),
                    splashColor: Colors.white.withValues(alpha: 0.3),
                    highlightColor: Colors.white.withValues(alpha: 0.15),
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF143823),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF143823).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Dot Indicator Tap Navigation (also tap dots to jump directly)
              Positioned(
                top: height * 0.77,
                left: width * 0.40,
                child: GestureDetector(
                  onTap: _onNext,
                  child: Container(
                    height: 24,
                    width: 70,
                    color: Colors.transparent, // transparent touch target over the dots
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
