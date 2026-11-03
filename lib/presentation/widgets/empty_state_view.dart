import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import 'thulirva_button.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final String emoji;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.emoji = '🌿',
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.paleGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.softGreen, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 38),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.displaySmall.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ThulirvaButton(
                  text: buttonText!,
                  onPressed: onButtonPressed,
                  height: 46,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

