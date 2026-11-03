import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../profile/addresses_screen.dart';
import '../widgets/thulirva_button.dart';
import '../widgets/thulirva_text_field.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final int _currentStep = 1; // 1: Address, 2: Payment, 3: Confirm
  String _selectedPaymentMethod = 'UPI'; // 'Razorpay', 'UPI', 'Card', 'COD'
  final TextEditingController _utrController = TextEditingController();

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  void _showAddressSelectionModal(List<AddressModel> addresses) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Delivery Address', style: AppTypography.titleLarge),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddressesScreen()),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...addresses.map((a) {
                final isSelected = ref.watch(addressProvider).selectedAddress?.id == a.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.paleGreen : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.forestGreen : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${a.address}, ${a.city} - ${a.pincode} • 📞 ${a.phone}'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.forestGreen)
                        : null,
                    onTap: () {
                      ref.read(addressProvider.notifier).selectAddress(a);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePlaceOrder() async {
    final cartState = ref.read(cartProvider);
    final user = ref.read(authProvider).user;
    final addressState = ref.read(addressProvider);
    final isPickupOnly = ref.read(settingsProvider).isPickupOnly;
    final storeSettings = ref.read(settingsProvider);

    final selectedAddr = addressState.selectedAddress ??
        (addressState.addresses.isNotEmpty ? addressState.addresses.first : null);

    if (!isPickupOnly && selectedAddr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a delivery address'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 'UPI' && _utrController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter UPI Transaction ID / UTR number'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    final contactName = selectedAddr?.name ?? user?.name ?? 'Valued Customer';
    final contactPhone = selectedAddr?.phone ?? user?.phone ?? '+91 93606 71533';

    final payload = {
      'user_id': user?.id,
      'customer_name': contactName,
      'customer_phone': contactPhone,
      'customer_email': user?.email ?? '',
      'order_type': isPickupOnly ? 'pickup' : 'delivery',
      'is_pickup': isPickupOnly,
      'address': isPickupOnly ? storeSettings.storeAddress : selectedAddr!.address,
      'city': isPickupOnly ? 'Kanchipuram' : selectedAddr!.city,
      'state': isPickupOnly ? 'Tamil Nadu' : selectedAddr!.state,
      'pincode': isPickupOnly ? '631601' : selectedAddr!.pincode,
      'items': cartState.items.map((i) => {
        'id': i.product.id,
        'name': i.product.name,
        'price': i.product.price,
        'quantity': i.quantity,
        'weight': i.selectedVariant ?? i.product.weight,
        'total': i.totalPrice,
      }).toList(),
      'subtotal': cartState.subtotal,
      'delivery_charge': isPickupOnly ? 0.0 : cartState.deliveryCharge,
      'discount_amount': cartState.discountAmount,
      'promo_code': cartState.appliedCouponCode,
      'total': cartState.grandTotal,
      'total_price': cartState.grandTotal,
      'payment_method': _selectedPaymentMethod == 'UPI'
          ? 'UPI QR (7904880944@superyes)'
          : (_selectedPaymentMethod == 'Razorpay'
              ? 'Razorpay Gateway'
              : (_selectedPaymentMethod == 'Card' ? 'Credit/Debit Card' : 'Cash on Delivery')),
      'transaction_id': _selectedPaymentMethod == 'UPI' ? _utrController.text.trim() : 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      'payment_status': _selectedPaymentMethod == 'COD' ? 'pending' : 'paid',
      'order_status': 'pending',
    };

    final order = await ref.read(orderProvider.notifier).placeOrder(payload);

    if (!mounted) return;

    if (order != null) {
      ref.read(cartProvider.notifier).clearCart();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: order),
        ),
      );
    } else {
      final error = ref.read(orderProvider).errorMessage ?? 'Order creation failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.cancelled,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final addressState = ref.watch(addressProvider);
    final orderState = ref.watch(orderProvider);
    final settingsState = ref.watch(settingsProvider);
    final isPickupOnly = settingsState.isPickupOnly;
    final selectedAddr = addressState.selectedAddress ??
        (addressState.addresses.isNotEmpty ? addressState.addresses.first : null);

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Step Progress Indicator: Address -> Payment -> Confirm (Mockup Screen 9)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStepPill(1, 'Address', Icons.location_on, _currentStep >= 1),
                Container(width: 30, height: 1.5, color: AppColors.softGreen),
                _buildStepPill(2, 'Payment', Icons.payment, _currentStep >= 2),
                Container(width: 30, height: 1.5, color: AppColors.softGreen),
                _buildStepPill(3, 'Confirm', Icons.check_circle_outline, _currentStep >= 3),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Delivery Address / Store Pickup Card
                  if (isPickupOnly) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(color: AppColors.forestGreen, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.forestGreen.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.storefront, color: AppColors.forestGreen, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Store Pickup Location (FREE)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            settingsState.storeAddress,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark, height: 1.4),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '⏰ Hours: ${settingsState.storeTimings} • 📞 ${settingsState.storePhone}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMid),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              '✓ No delivery charge. Show your order ID or phone number when collecting at counter.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.forestGreen, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Delivery Address',
                                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (addressState.addresses.isEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AddressesScreen()),
                                    );
                                  } else {
                                    _showAddressSelectionModal(addressState.addresses);
                                  }
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                                child: Text(
                                  selectedAddr != null ? 'Change' : '+ Add Address',
                                  style: const TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (selectedAddr != null) ...[
                            Text(selectedAddr.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              '${selectedAddr.address}, ${selectedAddr.city}, ${selectedAddr.state} - ${selectedAddr.pincode}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMid),
                            ),
                            const SizedBox(height: 2),
                            Text('📞 ${selectedAddr.phone}', style: AppTypography.bodySmall.copyWith(color: AppColors.textLight)),
                          ] else ...[
                            const Text(
                              'No address selected. Tap "+ Add Address" to provide doorstep delivery details.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 2. Payment Method Section (Mockup Screen 9)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Method',
                          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),

                        _buildPaymentRadioTile('Razorpay', 'Razorpay (UPI, Cards, Net Banking)', Icons.account_balance),
                        _buildPaymentRadioTile('UPI', 'UPI (7904880944@superyes / GPay, PhonePe)', Icons.qr_code_2),
                        _buildPaymentRadioTile('Card', 'Credit / Debit Card', Icons.credit_card),
                        _buildPaymentRadioTile('COD', 'Cash on Delivery (COD)', Icons.money),

                        // If UPI selected, show the Farm Themed QR & UTR input
                        if (_selectedPaymentMethod == 'UPI') ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.paleGreen,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.softGreen),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('UPI ID: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                    const Text('7904880944@superyes', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forestGreen, fontSize: 12)),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(const ClipboardData(text: '7904880944@superyes'));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('✓ UPI ID copied!'), duration: Duration(seconds: 1)),
                                        );
                                      },
                                      child: const Text('📋 Copy', style: TextStyle(color: AppColors.forestGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ThulirvaTextField(
                                  controller: _utrController,
                                  label: 'UPI Transaction ID / UTR Number *',
                                  hint: 'Enter 12-digit UTR from payment receipt',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Summary', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Items (${cartState.totalItemCount})', style: AppTypography.bodySmall),
                            Text('₹${cartState.subtotal.toStringAsFixed(0)}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isPickupOnly ? 'Farm Store Pickup' : 'Delivery Charge', style: AppTypography.bodySmall),
                            Text(
                              isPickupOnly || cartState.deliveryCharge == 0 ? 'FREE' : '₹${cartState.deliveryCharge.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: cartState.deliveryCharge == 0 ? AppColors.naturalGreen : AppColors.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (cartState.discountAmount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Promo Discount (${cartState.appliedCouponCode})', style: const TextStyle(color: AppColors.naturalGreen, fontSize: 12)),
                              Text('-₹${cartState.discountAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.naturalGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                            ],
                          ),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Grand Total', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                            Text('₹${cartState.grandTotal.toStringAsFixed(0)}', style: AppTypography.price.copyWith(fontSize: 20)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Place Order Bar (Mockup Screen 9: "Pay ₹398")
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forestGreen.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: ThulirvaButton(
                text: 'Pay ₹${cartState.grandTotal.toStringAsFixed(0)}',
                isLoading: orderState.isPlacingOrder,
                onPressed: _handlePlaceOrder,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill(int step, String title, IconData icon, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.forestGreen : AppColors.lightCream,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? AppColors.forestGreen : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.forestGreen : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRadioTile(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.forestGreen : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: AppColors.forestGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textDark : AppColors.textMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
