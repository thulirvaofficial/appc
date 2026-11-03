import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/order_model.dart';
import '../main_wrapper.dart';
import '../orders/order_details_screen.dart';
import '../widgets/thulirva_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainWrapper()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Top Right Close "✕" Button (Mockup Screen 10)
              Positioned(
                top: 10,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDark, size: 24),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainWrapper()),
                      (route) => false,
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Confetti and Big Solid Green Checkmark
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Confetti stars/sparkles
                        Positioned(top: 0, left: 10, child: Text('✨', style: TextStyle(fontSize: 18))),
                        Positioned(top: 10, right: 15, child: Text('🎉', style: TextStyle(fontSize: 16))),
                        Positioned(bottom: 0, left: 20, child: Text('🌾', style: TextStyle(fontSize: 16))),
                        Positioned(bottom: 5, right: 10, child: Text('✨', style: TextStyle(fontSize: 18))),

                        Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(
                            color: AppColors.naturalGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Headline
                    const Text(
                      'Order Placed\nSuccessfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Order ID Subtitle (Mockup Screen 10)
                    Text(
                      'Order ID: #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    const Text(
                      'Your order has been confirmed.\nWe will notify you once it\'s shipped.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),

                    const Spacer(),

                    // View Order Details Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsScreen(order: order),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'View Order Details',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Continue Shopping Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const MainWrapper()),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Continue Shopping',
                          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
