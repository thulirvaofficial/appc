import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../profile/addresses_screen.dart';
import '../widgets/thulirva_button.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // Delivery Method: 'delivery' or 'pickup'
  String _deliveryMethod = 'delivery';

  // Selected Pickup Slot
  String _selectedPickupSlot = '7:00 AM - 9:00 AM';
  final List<String> _pickupSlots = [
    '7:00 AM - 9:00 AM',
    '9:00 AM - 12:00 PM',
    '12:00 PM - 3:00 PM',
    '3:00 PM - 6:00 PM',
    '6:00 PM - 8:00 PM',
  ];

  final TextEditingController _utrController = TextEditingController();
  File? _paymentProofFile;
  String? _paymentProofBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'png' : 'jpeg';
        final base64Str = 'data:image/$mimeType;base64,${base64Encode(bytes)}';

        setState(() {
          _paymentProofFile = File(picked.path);
          _paymentProofBase64 = base64Str;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Payment screenshot attached successfully!'),
              backgroundColor: AppColors.forestGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick screenshot: $e'),
            backgroundColor: AppColors.cancelled,
          ),
        );
      }
    }
  }

  void _showProofPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Payment Screenshot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Attach the receipt or confirmation screenshot from your UPI app (GPay, PhonePe, Paytm, etc.).',
                  style: TextStyle(fontSize: 12, color: AppColors.textMid),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.forestGreen),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProofImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.forestGreen),
                  title: const Text('Take a Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProofImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final storeSettings = ref.read(settingsProvider);
    final isPickupOnlyAdmin = storeSettings.isPickupOnly;
    final isPickup = isPickupOnlyAdmin || _deliveryMethod == 'pickup';

    final selectedAddr = addressState.selectedAddress ??
        (addressState.addresses.isNotEmpty ? addressState.addresses.first : null);

    if (!isPickup && selectedAddr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a delivery address for home delivery'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    final utrText = _utrController.text.trim();
    if (utrText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter UPI Transaction ID / UTR Number to verify payment'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    if (_paymentProofBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your payment screenshot proof'),
          backgroundColor: AppColors.cancelled,
        ),
      );
      return;
    }

    final contactName = isPickup
        ? (user?.name ?? 'Valued Customer')
        : (selectedAddr?.name ?? user?.name ?? 'Valued Customer');
    final contactPhone = isPickup
        ? (user?.phone ?? storeSettings.storePhone)
        : (selectedAddr?.phone ?? user?.phone ?? storeSettings.storePhone);

    final deliveryFee = isPickup ? 0.0 : cartState.deliveryCharge;
    final calculatedGrandTotal = cartState.subtotal - cartState.discountAmount + deliveryFee;

    final payload = {
      'user_id': user?.id,
      'customer_name': contactName,
      'customer_phone': contactPhone,
      'customer_email': user?.email ?? '',
      'delivery_type': isPickup ? 'pickup' : 'delivery',
      'order_type': isPickup ? 'pickup' : 'delivery',
      'is_pickup': isPickup,
      'pickup_location_id': 1,
      'pickup_location_name': storeSettings.storeName,
      'pickup_slot': isPickup ? _selectedPickupSlot : null,
      'address': isPickup ? storeSettings.storeAddress : selectedAddr!.address,
      'city': isPickup ? 'Kanchipuram' : selectedAddr!.city,
      'state': isPickup ? 'Tamil Nadu' : selectedAddr!.state,
      'pincode': isPickup ? '631601' : selectedAddr!.pincode,
      'items': cartState.items.map((i) => {
        'id': i.product.id,
        'name': i.product.name,
        'price': i.product.price,
        'quantity': i.quantity,
        'weight': i.selectedVariant ?? i.product.weight,
        'total': i.totalPrice,
      }).toList(),
      'subtotal': cartState.subtotal,
      'delivery_charge': deliveryFee,
      'discount_amount': cartState.discountAmount,
      'promo_code': cartState.appliedCouponCode,
      'total': calculatedGrandTotal,
      'total_price': calculatedGrandTotal,
      'payment_method': 'UPI QR (7904880944@superyes)',
      'transaction_id': utrText,
      'payment_proof': _paymentProofBase64,
      'payment_status': 'Verification Pending',
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
    final storeSettings = ref.watch(settingsProvider);
    final isPickupOnlyAdmin = storeSettings.isPickupOnly;
    final isPickup = isPickupOnlyAdmin || _deliveryMethod == 'pickup';

    final selectedAddr = addressState.selectedAddress ??
        (addressState.addresses.isNotEmpty ? addressState.addresses.first : null);

    final deliveryFee = isPickup ? 0.0 : cartState.deliveryCharge;
    final calculatedGrandTotal = cartState.subtotal - cartState.discountAmount + deliveryFee;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.forestGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: AppColors.forestGreen,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DELIVERY METHOD SELECTOR (Home Delivery vs Self Pickup)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5EDE2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.local_shipping_outlined, color: AppColors.forestGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Delivery Method',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (isPickupOnlyAdmin) ...[
                          // Store Pickup Mode Forced by Admin Notice
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF7EB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.forestGreen, width: 1.2),
                            ),
                            child: Row(
                              children: const [
                                Text('🏪', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'STORE PICKUP ONLY: Doorstep delivery is temporarily paused. Orders are packed for Farm Store Self Pickup.',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.forestGreen),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Selectable 2-Option Cards
                          Row(
                            children: [
                              // Home Delivery Card
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _deliveryMethod = 'delivery'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _deliveryMethod == 'delivery' ? const Color(0xFFEDF7EB) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _deliveryMethod == 'delivery' ? AppColors.forestGreen : const Color(0xFFE0E0E0),
                                        width: _deliveryMethod == 'delivery' ? 1.8 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _deliveryMethod == 'delivery' ? Icons.radio_button_checked : Icons.radio_button_off,
                                              size: 18,
                                              color: _deliveryMethod == 'delivery' ? AppColors.forestGreen : Colors.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Home Delivery',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Delivered to saved address',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF6E8072)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Self Pickup Card
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _deliveryMethod = 'pickup'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _deliveryMethod == 'pickup' ? const Color(0xFFEDF7EB) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _deliveryMethod == 'pickup' ? AppColors.forestGreen : const Color(0xFFE0E0E0),
                                        width: _deliveryMethod == 'pickup' ? 1.8 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _deliveryMethod == 'pickup' ? Icons.radio_button_checked : Icons.radio_button_off,
                                              size: 18,
                                              color: _deliveryMethod == 'pickup' ? AppColors.forestGreen : Colors.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Self Pickup',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Collect at farm store (FREE)',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. LOCATION / ADDRESS SECTION
                  if (isPickup) ...[
                    // Farm Store Self-Pickup Information Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD6E6D3), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text('🏪', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text(
                                'Pickup Location & Timings',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            storeSettings.storeName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.forestGreen),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            storeSettings.storeAddress,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF4A5D4E), height: 1.3),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: AppColors.forestGreen),
                              const SizedBox(width: 4),
                              Text('Hours: ${storeSettings.storeTimings}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF4A5D4E))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: AppColors.forestGreen),
                              const SizedBox(width: 4),
                              Text('Phone: ${storeSettings.storePhone}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF4A5D4E))),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Select Pickup Time Slot
                          const Text(
                            'Select Pickup Time Slot *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7EE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedPickupSlot,
                                items: _pickupSlots.map((slot) {
                                  return DropdownMenuItem<String>(
                                    value: slot,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule, size: 16, color: AppColors.forestGreen),
                                        const SizedBox(width: 8),
                                        Text(slot, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedPickupSlot = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Icon(Icons.info_outline, size: 14, color: Color(0xFF55705C)),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Instructions: Show your Order reference ID or phone number at the counter when you arrive.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF55705C)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Doorstep Delivery Address Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5EDE2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.location_on, color: AppColors.forestGreen, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'Delivery Address',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                                  ),
                                ],
                              ),
                              if (addressState.addresses.isNotEmpty)
                                TextButton(
                                  onPressed: () => _showAddressSelectionModal(addressState.addresses),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                  child: const Text('Change', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestGreen)),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AddressesScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Address'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (selectedAddr != null) ...[
                            Text(selectedAddr.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(height: 2),
                            Text(
                              '${selectedAddr.address}, ${selectedAddr.city}, ${selectedAddr.state} - ${selectedAddr.pincode}',
                              style: const TextStyle(color: Color(0xFF5A6D5E), fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text('📞 ${selectedAddr.phone}', style: const TextStyle(color: Color(0xFF8A9A8C), fontSize: 11.5)),
                          ] else ...[
                            const Text(
                              'No address selected. Tap "+ Add Address" to provide doorstep delivery details.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  // 3. PAYMENT METHOD SECTION: ONLY MERCHANT UPI QR GATEWAY
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5EDE2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.qr_code_2, color: AppColors.forestGreen, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Payment: Merchant UPI QR',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Scan and pay directly using any UPI app (Google Pay, PhonePe, Paytm, BHIM, Cred, Bank UPI).',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF6E8072)),
                        ),
                        const SizedBox(height: 12),

                        // Themed QR Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7EE),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5EDE2)),
                          ),
                          child: Column(
                            children: [
                              // Merchant badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'THULIRVA OFFICIAL MERCHANT',
                                  style: TextStyle(color: Color(0xFFF7D97B), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Real Merchant QR Image
                              Container(
                                width: 180,
                                height: 180,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/payment_qr.jpg',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.qr_code, size: 80, color: AppColors.forestGreen),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // UPI ID Box with Copy Button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFD6E6D3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('UPI ID: ', style: TextStyle(fontSize: 12, color: Color(0xFF555555), fontWeight: FontWeight.w600)),
                                    const Text(
                                      '7904880944@superyes',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(const ClipboardData(text: '7904880944@superyes'));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('✓ UPI ID 7904880944@superyes copied!'), duration: Duration(seconds: 1)),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.forestGreen,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Copy', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Amount Payable: ₹${calculatedGrandTotal.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.forestGreen),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Required UTR Input
                        const Text(
                          'UPI Transaction ID / UTR Number *',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _utrController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'e.g. 12-digit UTR from payment receipt',
                            hintStyle: const TextStyle(color: Color(0xFF9EAFA3), fontSize: 12.5),
                            filled: true,
                            fillColor: const Color(0xFFFAF7EE),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Payment Screenshot Upload Section
                        const Text(
                          'Upload Payment Screenshot *',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                        ),
                        const SizedBox(height: 6),

                        if (_paymentProofFile == null) ...[
                          GestureDetector(
                            onTap: _showProofPickerOptions,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7EE),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFC8DBBF), style: BorderStyle.solid),
                              ),
                              child: Column(
                                children: const [
                                  Icon(Icons.cloud_upload_outlined, color: AppColors.forestGreen, size: 30),
                                  SizedBox(height: 6),
                                  Text('Tap to Select Payment Screenshot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.forestGreen)),
                                  SizedBox(height: 2),
                                  Text('JPG or PNG receipt from your UPI app', style: TextStyle(color: Color(0xFF7A8B7E), fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF7EB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.forestGreen),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    _paymentProofFile!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('✓ Screenshot Attached', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.forestGreen)),
                                      Text(
                                        _paymentProofFile!.path.split(Platform.pathSeparator).last,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF55705C)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showProofPickerOptions,
                                  child: const Text('Replace', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _paymentProofFile = null;
                                      _paymentProofBase64 = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. ORDER SUMMARY
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5EDE2)),
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
                            Text(isPickup ? 'Store Pickup Fee' : 'Delivery Charge', style: AppTypography.bodySmall),
                            Text(
                              deliveryFee == 0 ? 'FREE' : '₹${deliveryFee.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: deliveryFee == 0 ? AppColors.naturalGreen : AppColors.textDark,
                                fontWeight: FontWeight.w700,
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
                            Text('₹${calculatedGrandTotal.toStringAsFixed(0)}', style: AppTypography.price.copyWith(fontSize: 20)),
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

          // Bottom Place Order Bar
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
                text: 'Verify & Place Order • ₹${calculatedGrandTotal.toStringAsFixed(0)}',
                isLoading: orderState.isPlacingOrder,
                onPressed: _handlePlaceOrder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
