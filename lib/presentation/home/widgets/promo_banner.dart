import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PromoBanner extends StatelessWidget {
  final VoidCallback onShopNow;

  const PromoBanner({super.key, required this.onShopNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12174B36),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: AspectRatio(
          aspectRatio: 1002.0 / 399.0, // Exact 2.511278 ratio matching the official master banner artwork
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onShopNow,
              child: Image.asset(
                'assets/images/thulirva_official_banner.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.forestGreen,
                  child: const Center(
                    child: Text(
                      '🌿 THULIRVA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
