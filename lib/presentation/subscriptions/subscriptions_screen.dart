import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_indicator.dart';
import 'subscribe_modal.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  void _openSubscribeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscribeModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);
    final subs = subState.subscriptions;

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text('My Subscriptions', style: AppTypography.displaySmall.copyWith(fontSize: 18)),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () => ref.read(subscriptionProvider.notifier).fetchSubscriptions(),
          child: subState.isLoading && subs.isEmpty
              ? const LoadingIndicator(message: 'Loading active subscriptions...')
              : subs.isEmpty
                  ? EmptyStateView(
                      title: 'No Active Subscriptions',
                      message: 'Subscribe for daily doorstep fresh milk, paneer, and ghee delivery every morning.',
                      emoji: '🥛',
                      buttonText: 'Start Subscription',
                      onButtonPressed: () => _openSubscribeModal(context),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Start new subscription banner button
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white,
                                child: Text('🥛', style: TextStyle(fontSize: 22)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daily Morning Milk',
                                      style: AppTypography.titleMedium.copyWith(color: Colors.white),
                                    ),
                                    const Text(
                                      'Delivered before 7:00 AM every day.',
                                      style: TextStyle(color: AppColors.lightGold, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _openSubscribeModal(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.lightGold,
                                  foregroundColor: AppColors.forestGreen,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('+ Subscribe', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          'Your Subscriptions (${subs.length})',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),

                        ...subs.map((s) => _buildSubscriptionCard(context, ref, s)),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, WidgetRef ref, SubscriptionModel sub) {
    final isActive = sub.status.toLowerCase() == 'active';
    final isPaused = sub.status.toLowerCase() == 'paused';
    final isCancelled = sub.status.toLowerCase() == 'cancelled';

    // Critical Rule 16: Highlight if 0 <= days_remaining <= 5
    final isExpiringSoon = sub.daysRemaining >= 0 && sub.daysRemaining <= 5 && isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isExpiringSoon ? AppColors.processing : AppColors.border,
          width: isExpiringSoon ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header with ID & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${sub.id}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestGreen,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.lightGreenBg
                        : (isPaused ? Colors.amber.shade50 : Colors.red.shade50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sub.status.toUpperCase(),
                    style: TextStyle(
                      color: isActive
                          ? AppColors.naturalGreen
                          : (isPaused ? AppColors.processing : AppColors.cancelled),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.lightCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('🥛', style: TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('${sub.quantity} Packet(s) • ${sub.frequency}', style: AppTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text('⏰ Delivery Slot: ${sub.deliverySlot}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMid, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Critical Rule 16: Expiry Reminder Banner
                if (isExpiringSoon) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.processing, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.daysRemaining == 0
                                ? '⚠️ Subscription expires today! Renew now.'
                                : '⚠️ Subscription expires in ${sub.daysRemaining} days (${sub.expiryDate}).',
                            style: const TextStyle(
                              color: Color(0xFF8A5A00),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Started: ${sub.startDate}', style: AppTypography.bodySmall),
                    Text('₹${sub.totalPrice.toStringAsFixed(0)} / mo', style: AppTypography.price.copyWith(fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          if (!isCancelled) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 18),
                    label: Text(isActive ? 'Pause' : 'Resume'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.forestGreen),
                    onPressed: () {
                      ref.read(subscriptionProvider.notifier).updateStatus(sub.id, isActive ? 'Paused' : 'Active');
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.cancelled),
                    onPressed: () {
                      _showCancelDialog(context, ref, sub.id);
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String subId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text('Are you sure you want to cancel this morning dairy delivery subscription?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Active')),
          TextButton(
            onPressed: () {
              ref.read(subscriptionProvider.notifier).updateStatus(subId, 'Cancelled');
              Navigator.pop(context);
            },
            child: const Text('Cancel Subscription', style: TextStyle(color: AppColors.cancelled)),
          ),
        ],
      ),
    );
  }
}

