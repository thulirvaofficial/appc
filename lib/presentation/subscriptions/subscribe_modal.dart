import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/thulirva_button.dart';
import '../widgets/thulirva_text_field.dart';

class SubscribeModal extends ConsumerStatefulWidget {
  const SubscribeModal({super.key});

  @override
  ConsumerState<SubscribeModal> createState() => _SubscribeModalState();
}

class _SubscribeModalState extends ConsumerState<SubscribeModal> {
  int _currentStep = 1; // 1: Select Plan & Details, 2: UPI Payment & UTR
  SubscriptionPlanModel? _selectedPlan;
  int _quantity = 1;
  String _selectedSlot = '6:00 AM - 7:00 AM';
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _utrController = TextEditingController();

  final List<String> _slots = [
    '5:30 AM - 6:30 AM',
    '6:00 AM - 7:00 AM',
    '7:00 AM - 8:00 AM',
  ];

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmSubscription() async {
    if (_utrController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the UPI Transaction ID / UTR number'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    final addressState = ref.read(addressProvider);
    final selectedAddr = addressState.selectedAddress ??
        (addressState.addresses.isNotEmpty ? addressState.addresses.first : null);

    final plan = _selectedPlan!;
    final totalPrice = plan.price * _quantity;

    final payload = {
      'user_id': user?.id,
      'customer_name': selectedAddr?.name ?? user?.name ?? 'Valued Customer',
      'customer_phone': selectedAddr?.phone ?? user?.phone ?? '9876543210',
      'customer_email': user?.email ?? '',
      'plan_id': plan.id,
      'product_id': plan.productId,
      'product_name': plan.productName,
      'product_image': plan.productImage,
      'time_period': plan.timePeriod,
      'frequency': plan.frequency,
      'quantity': _quantity,
      'delivery_slot': _selectedSlot,
      'price_per_delivery': 44,
      'total_price': totalPrice,
      'start_date': _startDate.toString().split(' ')[0],
      'address': selectedAddr?.address ?? 'Doorstep Address, Chennai',
      'city': selectedAddr?.city ?? 'Chennai',
      'pincode': selectedAddr?.pincode ?? '600078',
      'payment_method': 'UPI Direct Payment (7904880944@superyes)',
      'transaction_id': _utrController.text.trim(),
    };

    final ok = await ref.read(subscriptionProvider.notifier).createSubscription(payload);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Subscription activated! Fresh morning delivery scheduled.'),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = ref.read(subscriptionProvider).errorMessage ?? 'Subscription failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.cancelled),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final plans = subState.plans;

    if (_selectedPlan == null && plans.isNotEmpty) {
      _selectedPlan = plans.first;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentStep == 1 ? 'Start Farm Subscription' : 'Step 2: UPI Payment',
                style: AppTypography.titleLarge.copyWith(color: AppColors.forestGreen),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              child: _currentStep == 1
                  ? _buildStep1Plans(plans)
                  : _buildStep2Payment(),
            ),
          ),

          // Bottom Action Button
          SafeArea(
            child: ThulirvaButton(
              text: _currentStep == 1
                  ? 'Proceed to UPI Payment →'
                  : 'Confirm & Activate Subscription',
              isLoading: subState.isSubmitting,
              onPressed: () {
                if (_currentStep == 1) {
                  setState(() => _currentStep = 2);
                } else {
                  _handleConfirmSubscription();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Plans(List<SubscriptionPlanModel> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Select Subscription Plan *', style: AppTypography.titleSmall),
        const SizedBox(height: 8),
        ...plans.map((p) {
          final isSel = _selectedPlan?.id == p.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSel ? AppColors.paleGreen : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? AppColors.forestGreen : AppColors.border,
                width: isSel ? 1.8 : 1,
              ),
            ),
            child: ListTile(
              title: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text('${p.timePeriod} • ${p.frequency}\n${p.description}', style: const TextStyle(fontSize: 12)),
              trailing: Text('₹${p.price.toStringAsFixed(0)}', style: AppTypography.price.copyWith(fontSize: 16)),
              onTap: () => setState(() => _selectedPlan = p),
            ),
          );
        }),

        const SizedBox(height: 14),
        Text('Daily Quantity (Packets) *', style: AppTypography.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [1, 2, 3, 4].map((q) {
            final isSel = _quantity == q;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text('$q Packet${q > 1 ? 's' : ''}'),
                selected: isSel,
                onSelected: (_) => setState(() => _quantity = q),
                selectedColor: AppColors.forestGreen,
                labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),
        Text('Morning Delivery Slot *', style: AppTypography.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _slots.map((s) {
            final isSel = _selectedSlot == s;
            return ChoiceChip(
              label: Text('⏰ $s'),
              selected: isSel,
              onSelected: (_) => setState(() => _selectedSlot = s),
              selectedColor: AppColors.forestGreen,
              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 12),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (picked != null) {
              setState(() => _startDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start Date: ${_startDate.toString().split(' ')[0]}', style: AppTypography.titleSmall),
                const Icon(Icons.calendar_today, size: 18, color: AppColors.forestGreen),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep2Payment() {
    final plan = _selectedPlan!;
    final total = plan.price * _quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paleGreen,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.softGreen),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${plan.productName} ($_quantity x)', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('₹${total.toStringAsFixed(0)}/mo', style: AppTypography.price),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Themed QR Container
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.forestGreen, width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.forestGreen.withValues(alpha: 0.1), blurRadius: 10),
                  ],
                ),
                child: Image.asset(
                  'assets/images/payment_qr.jpg',
                  width: 170,
                  height: 170,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 120, color: AppColors.forestGreen),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('UPI ID: 7904880944@superyes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.forestGreen)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: '7904880944@superyes'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ UPI ID copied!'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: const Text('📋 Copy', style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ThulirvaTextField(
          controller: _utrController,
          label: 'UPI Transaction ID / UTR Number *',
          hint: 'Enter 12-digit UTR from payment receipt',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        const Text(
          '✓ Free doorstep morning delivery guaranteed. Pause or cancel anytime.',
          style: TextStyle(color: AppColors.naturalGreen, fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
