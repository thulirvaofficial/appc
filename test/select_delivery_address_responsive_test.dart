import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/core/constants/app_colors.dart';
import 'package:thulirva_app/core/constants/app_typography.dart';

void main() {
  final testWidths = [320.0, 360.0, 375.0, 393.0, 412.0];

  for (final width in testWidths) {
    testWidgets('Select Delivery Address header renders without overflow at ${width}px width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Select Delivery Address',
                        style: AppTypography.titleLarge.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.forestGreen),
                      label: const Text('Add New', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestGreen)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final err = tester.takeException();
      expect(err, isNull, reason: 'Must not overflow at $width px');
      expect(find.text('Select Delivery Address'), findsOneWidget);
      expect(find.text('Add New'), findsOneWidget);
    });
  }
}

