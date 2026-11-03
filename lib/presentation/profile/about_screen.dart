import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About THULIRVA',
          style: AppTypography.displaySmall.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Crisp, High-Resolution Logo Card
            Container(
              width: 130,
              height: 130,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.25), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF143823).withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo/logo.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('🌿', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'THULIRVA',
              style: AppTypography.displayMedium.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ROOTED IN NATURE',
              style: TextStyle(
                letterSpacing: 3,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.naturalGreen,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pure by Nature, Made for You!',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.textMid,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Farm Heritage Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, color: AppColors.forestGreen, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Our Farm Heritage',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'At THULIRVA, we believe pure milk and wholesome dairy products should be accessible to every family without shortcuts, artificial hormones, or chemical additives.\n\nOur healthy pasture-grazing cows feed on fresh green pastures in Tamil Nadu. Every morning, fresh milk is bottled within hours and delivered straight to your doorstep before 7:00 AM.',
                    style: AppTypography.bodyMedium.copyWith(
                      height: 1.6,
                      fontSize: 13,
                      color: AppColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 14),

                  // Store & Farm Details
                  _buildInfoRow(Icons.storefront_outlined, 'Farm Store & Pickup:',
                      'No 1, Mayana Salai, Thimmarajampettai, Kanchipuram - 631601, Tamil Nadu'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time_outlined, 'Store Timings:', '7:00 AM – 8:00 PM (All 7 Days)'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone_outlined, 'Customer Care:', '+91 93606 71533'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.email_outlined, 'Email Support:', 'support@thulirva.com'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.forestGreen, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMid, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
