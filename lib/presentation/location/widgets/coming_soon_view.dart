import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ComingSoonModal extends StatelessWidget {
  final String areaName;
  final VoidCallback onSavePreferred;
  final VoidCallback onChangeLocation;

  const ComingSoonModal({
    super.key,
    required this.areaName,
    required this.onSavePreferred,
    required this.onChangeLocation,
  });

  static Future<void> show(
    BuildContext context, {
    required String areaName,
    required VoidCallback onSavePreferred,
    required VoidCallback onChangeLocation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComingSoonModal(
        areaName: areaName,
        onSavePreferred: onSavePreferred,
        onChangeLocation: onChangeLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8EF), // Cream background
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Milk Bottle Illustration Graphic
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD6A928), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.local_drink_rounded,
                size: 46,
                color: AppColors.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Coming Soon Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFC107)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_top_rounded, size: 14, color: Color(0xFFB78103)),
                SizedBox(width: 6),
                Text(
                  'COMING SOON',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Color(0xFFB78103),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Area Name Headline
          Text(
            areaName.isNotEmpty ? areaName : 'Your Location',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),

          // Message
          const Text(
            "Sorry! Thulirva is not available in your area yet. We're working hard to bring fresh dairy products to your doorstep.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          // Primary Button: Change Location
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit_location_alt_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Change Location',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                onChangeLocation();
              },
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Button: Save as Preferred Location
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.forestGreen, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                onSavePreferred();
              },
              child: const Text(
                'Save as Preferred Location (Browsing Only)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.forestGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

