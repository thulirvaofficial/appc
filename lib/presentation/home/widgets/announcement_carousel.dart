import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/business_config_provider.dart';

/// THULIRVA Dynamic Customer Announcement Carousel
/// Features:
/// - Exact 5-second automatic rotation interval
/// - Smooth horizontal sliding animation with manual swipe (PageView)
/// - Page indicator dots with active dot highlight
/// - Resets rotation interval timer on manual user interaction
/// - Gracefully handles single announcement (static card, no animation/dots)
/// - Gracefully handles zero announcements (returns SizedBox.shrink)
/// - Zero whole-page reload on rotation ticks
class AnnouncementCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> announcements;
  final BusinessConfigState? fallbackBanner;
  final VoidCallback? onCtaTap;

  const AnnouncementCarousel({
    super.key,
    required this.announcements,
    this.fallbackBanner,
    this.onCtaTap,
  });

  @override
  State<AnnouncementCarousel> createState() => _AnnouncementCarouselState();
}

class _AnnouncementCarouselState extends State<AnnouncementCarousel> {
  late final PageController _pageController;
  Timer? _rotationTimer;
  int _currentPage = 0;

  List<Map<String, dynamic>> get _items {
    if (widget.announcements.isNotEmpty) {
      return widget.announcements;
    }
    final fb = widget.fallbackBanner;
    if (fb != null && fb.bannerEnabled && fb.bannerHeadline.trim().isNotEmpty) {
      return [
        {
          'id': 'fallback-launch-banner',
          'title': fb.bannerHeadline,
          'description': fb.bannerSubtitle,
          'bg_color': fb.bannerBgColor,
          'image_url': fb.bannerImageUrl,
          'badge_text': 'DELIVERY LAUNCH',
          'cta_text': 'Shop Farm Fresh',
        }
      ];
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AnnouncementCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.announcements.length != widget.announcements.length) {
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    _rotationTimer?.cancel();
    if (_items.length > 1) {
      _rotationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final nextPage = (_currentPage + 1) % _items.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    // User interacted manually: reset the 5-second countdown timer
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Color _parseColor(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      final hex = hexString.replaceAll('#', '').trim();
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Single Announcement: render cleanly without carousel controls
    if (items.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _buildBannerCard(items[0]),
      );
    }

    // Multiple Announcements: Horizontal Sliding PageView with Indicators
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 148,
            child: PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: _handlePageChanged,
              itemBuilder: (context, index) {
                return _buildBannerCard(items[index]);
              },
            ),
          ),
          const SizedBox(height: 8),
          // Elegant Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.forestGreen
                      : AppColors.forestGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> item) {
    final title = item['title'] ?? item['headline'] ?? '';
    final subtitle = item['description'] ?? item['subtitle'] ?? '';
    final badge = item['badge_text'] ?? 'SPECIAL OFFER';
    final ctaText = item['cta_text'] ?? 'Shop Now';
    final rawBg = item['bg_color'] ?? item['background_color'] ?? '#1B4332';
    final rawAccent = item['accent_color'] ?? '#E5C97A';
    final rawText = item['text_color'] ?? '#FFFFFF';
    final imageUrl = item['image_url'] ?? '';

    final bgColor = _parseColor(rawBg, const Color(0xFF1B4332));
    final accentColor = _parseColor(rawAccent, const Color(0xFFE5C97A));
    final textColor = _parseColor(rawText, Colors.white);

    final hasImage = imageUrl.toString().trim().isNotEmpty;
    final resolvedImageUrl =
        hasImage ? ApiEndpoints.resolveImageUrl(imageUrl.toString()) : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative background organic shape
            Positioned(
              right: -25,
              top: -35,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            badge.toString().toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Title / Headline
                        Text(
                          title.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),

                        // Subtitle
                        if (subtitle.toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle.toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.88),
                              fontSize: 11,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Image or CTA Button Column
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (resolvedImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            resolvedImageUrl,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: widget.onCtaTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: const Color(0xFF1B4332),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ctaText.toString(),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 13),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
