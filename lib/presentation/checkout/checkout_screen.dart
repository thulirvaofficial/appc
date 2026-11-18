import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/business_config_provider.dart';
import '../profile/addresses_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../widgets/thulirva_button.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // Submission Guard to completely prevent double-click / duplicate orders
  bool _isSubmitting = false;

  // Delivery Method: 'delivery' or 'pickup'
  String _deliveryMethod = 'delivery';

  // Dynamic Pickup Locations & Settings
  List<dynamic> _pickupLocations = [];
  dynamic _selectedPickupLocation;
  bool _pickupEnabled = false;
  List<dynamic> _serviceableLocations = [];
  dynamic _selectedDeliveryZone;

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
  String _paymentMode = 'UPI';

  @override
  void initState() {
    super.initState();
    _fetchDynamicStoresAndLocations();
  }

  Future<void> _fetchDynamicStoresAndLocations() async {
    try {
      final api = ref.read(apiClientProvider);
      final locRes = await api.get(ApiEndpoints.pickupLocations);
      final setRes = await api.get('/pickup/settings');
      final delRes = await api.get(ApiEndpoints.deliveryLocations);

      if (mounted) {
        setState(() {
          if (locRes.data is Map && locRes.data['locations'] is List) {
            _pickupLocations = locRes.data['locations'] as List;
            if (_pickupLocations.isNotEmpty) {
              _selectedPickupLocation = _pickupLocations.first;
            }
          }
          if (setRes.data is Map && setRes.data['settings'] is Map) {
            _pickupEnabled = setRes.data['settings']['pickup_enabled'] == true || _pickupLocations.isNotEmpty;
          } else {
            _pickupEnabled = _pickupLocations.isNotEmpty;
          }
          if (delRes.data is Map && delRes.data['locations'] is List) {
            _serviceableLocations = delRes.data['locations'] as List;
            if (_serviceableLocations.isNotEmpty && _selectedDeliveryZone == null) {
              _selectedDeliveryZone = _serviceableLocations.first;
            }
          }
        });
      }
    } catch (_) {}
  }

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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddressesScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add, size: 16, color: AppColors.forestGreen),
                        label: const Text('Add New', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestGreen)),
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
                        title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
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
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePlaceOrder() async {
    if (_isSubmitting) return;

    final cartState = ref.read(cartProvider);
    final user = ref.read(authProvider).user;
    final addressState = ref.read(addressProvider);
    final storeSettings = ref.read(settingsProvider);
    final bizConfig = ref.read(businessConfigProvider);
    final isPickupOnlyAdmin = storeSettings.isPickupOnly;
    final isPickup = isPickupOnlyAdmin || _deliveryMethod == 'pickup';

    final hasSubscriptions = cartState.items.any((i) =>
        i.product.category.toLowerCase() == 'subscription' ||
        i.product.id.toString().startsWith('SUB_') ||
        i.product.name.toLowerCase().contains('(30 days plan)') ||
        i.product.name.toLowerCase().contains('subscription plan'));

    if ((hasSubscriptions || !bizConfig.codEnabled) && _paymentMode == 'COD') {
      _paymentMode = 'UPI';
    }

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

    if (!isPickup && selectedAddr != null && !selectedAddr.isServiceable) {
      // Live re-verify serviceability against central backend before blocking
      bool liveVerified = false;
      String? backendMessage;
      try {
        final api = ref.read(apiClientProvider);
        final checkRes = await api.post(
          ApiEndpoints.checkServiceability,
          data: {
            'latitude': selectedAddr.latitude,
            'longitude': selectedAddr.longitude,
            'pincode': selectedAddr.pincode,
            'area_name': selectedAddr.area,
            'address': selectedAddr.address,
          },
        );
        if (checkRes.data != null && checkRes.data['serviceable'] == true) {
          liveVerified = true;
          ref.read(addressProvider.notifier).selectAddress(selectedAddr.copyWith(isServiceable: true));
        } else {
          backendMessage = checkRes.data?['message'];
        }
      } catch (_) {}

      if (!mounted) return;
      if (!liveVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(backendMessage ?? 'Sorry! Thulirva is not available in ${selectedAddr.area.isNotEmpty ? selectedAddr.area : "your area"} yet. Please select an active delivery location or choose Store Pickup.'),
            backgroundColor: AppColors.cancelled,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    if (!isPickup && !bizConfig.isDeliveryAvailable && !bizConfig.canOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bizConfig.availabilityMessage.isNotEmpty
                ? bizConfig.availabilityMessage
                : 'Delivery is currently unavailable. Please check our next available delivery time.',
          ),
          backgroundColor: AppColors.cancelled,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final isCod = _paymentMode == 'COD' && !hasSubscriptions && bizConfig.codEnabled;
    final utrText = _utrController.text.trim();

    if (!isCod) {
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
    }

    setState(() => _isSubmitting = true);
    try {
      final contactName = isPickup
        ? (user?.name ?? 'Valued Customer')
        : (selectedAddr?.name ?? user?.name ?? 'Valued Customer');
    final contactPhone = isPickup
        ? (user?.phone ?? storeSettings.storePhone)
        : (selectedAddr?.phone ?? user?.phone ?? storeSettings.storePhone);

    // SEPARATE SUBSCRIPTION ITEMS FROM NORMAL PRODUCT ITEMS
    final subItems = cartState.items.where((i) =>
        i.product.category.toLowerCase() == 'subscription' ||
        i.product.id.toString().startsWith('SUB_') ||
        i.product.name.toLowerCase().contains('(30 days plan)') ||
        i.product.name.toLowerCase().contains('subscription plan')).toList();

    final normalItems = cartState.items.where((i) =>
        i.product.category.toLowerCase() != 'subscription' &&
        !i.product.id.toString().startsWith('SUB_') &&
        !i.product.name.toLowerCase().contains('(30 days plan)') &&
        !i.product.name.toLowerCase().contains('subscription plan')).toList();

    bool subscriptionSuccess = false;

    // Handle Subscriptions via dedicated subscription records
    if (subItems.isNotEmpty) {
      for (final subIt in subItems) {
        final planIdStr = subIt.product.id.toString().replaceFirst('SUB_', '');
        final planId = int.tryParse(planIdStr);
        final subPayload = {
          'user_id': user?.id,
          'customer_name': contactName,
          'customer_phone': contactPhone,
          'customer_email': user?.email ?? '',
          'plan_id': planId,
          'product_id': planId,
          'product_name': subIt.product.name,
          'product_image': subIt.product.fullImageUrl.isNotEmpty ? subIt.product.fullImageUrl : subIt.product.image,
          'time_period': subIt.product.weight.isNotEmpty ? subIt.product.weight : 'Daily Morning (30 Days)',
          'frequency': 'Daily',
          'quantity': subIt.quantity,
          'delivery_slot': isPickup ? _selectedPickupSlot : '6:00 AM - 7:00 AM',
          'price_per_delivery': 44,
          'total_price': subIt.totalPrice,
          'start_date': DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0],
          'address': isPickup ? (_selectedPickupLocation?['address'] ?? storeSettings.storeAddress) : selectedAddr!.address,
          'city': isPickup ? (_selectedPickupLocation?['city'] ?? 'Kanchipuram') : selectedAddr!.city,
          'pincode': isPickup ? (_selectedPickupLocation?['pincode'] ?? '631601') : selectedAddr!.pincode,
          'latitude': !isPickup ? selectedAddr?.latitude : null,
          'longitude': !isPickup ? selectedAddr?.longitude : null,
          'landmark': !isPickup ? selectedAddr?.landmark : null,
          'delivery_instructions': !isPickup ? selectedAddr?.deliveryInstructions : null,
          'payment_method': 'UPI Direct Payment (7904880944@superyes)',
          'transaction_id': utrText,
          'payment_proof': _paymentProofBase64,
          'payment_status': 'Verification Pending',
          'status': 'Pending Approval',
        };
        final ok = await ref.read(subscriptionProvider.notifier).createSubscription(subPayload);
        if (ok) subscriptionSuccess = true;
      }
      await ref.read(subscriptionProvider.notifier).fetchSubscriptions();
    }

    // If there were only subscription items in the cart:
    if (normalItems.isEmpty) {
      if (!mounted) return;
      if (subscriptionSuccess) {
        SystemSound.play(SystemSoundType.alert);
        ref.read(cartProvider.notifier).clearCart();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            backgroundColor: Colors.white,
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: AppColors.forestGreen, size: 26),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Subscription Placed!',
                    style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.w800, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Your milk subscription purchase has been submitted successfully.\n\nOur team is verifying your payment reference. Once verified, your doorstep morning deliveries will be active!',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF333333), height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionsScreen(initialTabIndex: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                child: const Text('View My Subscriptions', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      } else {
        final error = ref.read(subscriptionProvider).errorMessage ?? 'Subscription purchase failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.cancelled),
        );
      }
      return;
    }

    // Normal product order checkout
    final normalSubtotal = normalItems.fold<double>(0.0, (sum, i) => sum + i.totalPrice);
    final deliveryFee = isPickup ? 0.0 : (normalSubtotal >= 299 ? 0.0 : cartState.deliveryCharge);
    final calculatedGrandTotal = normalSubtotal - cartState.discountAmount + deliveryFee;

    final bizConfig = ref.read(businessConfigProvider);
    final activeUpiId = bizConfig.upiId.isNotEmpty ? bizConfig.upiId : '7904880944@superyes';

    final payload = {
      'user_id': user?.id,
      'customer_name': contactName,
      'customer_phone': contactPhone,
      'customer_email': user?.email ?? '',
      'delivery_type': isPickup ? 'pickup' : 'delivery',
      'order_type': isPickup ? 'pickup' : 'delivery',
      'is_pickup': isPickup,
      'delivery_zone': isPickup ? null : (_selectedDeliveryZone is Map ? _selectedDeliveryZone['name'] : _selectedDeliveryZone?.toString()),
      'pickup_location_id': _selectedPickupLocation?['id'] ?? 1,
      'pickup_location_name': _selectedPickupLocation?['name'] ?? storeSettings.storeName,
      'pickup_slot': isPickup ? _selectedPickupSlot : null,
      'address': isPickup ? (_selectedPickupLocation?['address'] ?? storeSettings.storeAddress) : selectedAddr!.address,
      'city': isPickup ? (_selectedPickupLocation?['city'] ?? 'Kanchipuram') : selectedAddr!.city,
      'state': isPickup ? 'Tamil Nadu' : selectedAddr!.state,
      'pincode': isPickup ? (_selectedPickupLocation?['pincode'] ?? '631601') : selectedAddr!.pincode,
      'latitude': !isPickup ? selectedAddr?.latitude : null,
      'longitude': !isPickup ? selectedAddr?.longitude : null,
      'landmark': !isPickup ? selectedAddr?.landmark : null,
      'delivery_instructions': !isPickup ? selectedAddr?.deliveryInstructions : null,
      'items': normalItems.map((i) => {
        'id': i.product.id,
        'name': i.product.name,
        'price': i.product.price,
        'quantity': i.quantity,
        'weight': i.selectedVariant ?? i.product.weight,
        'total': i.totalPrice,
      }).toList(),
      'subtotal': normalSubtotal,
      'delivery_charge': deliveryFee,
      'discount_amount': cartState.discountAmount,
      'promo_code': cartState.appliedCouponCode,
      'total': calculatedGrandTotal,
      'total_price': calculatedGrandTotal,
      'payment_method': isCod ? 'Cash on Delivery (COD)' : 'UPI QR ($activeUpiId)',
      'transaction_id': isCod ? 'COD' : utrText,
      'payment_proof': isCod ? null : _paymentProofBase64,
      'payment_status': isCod ? 'PENDING' : 'Verification Pending',
      'order_status': 'pending',
    };

    final order = await ref.read(orderProvider.notifier).placeOrder(payload);

    if (!mounted) return;

    if (order != null) {
      SystemSound.play(SystemSoundType.alert);
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
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final addressState = ref.watch(addressProvider);
    final orderState = ref.watch(orderProvider);
    final subState = ref.watch(subscriptionProvider);
    final storeSettings = ref.watch(settingsProvider);
    final bizConfig = ref.watch(businessConfigProvider);
    final isPickupOnlyAdmin = storeSettings.isPickupOnly;
    final isPickup = isPickupOnlyAdmin || _deliveryMethod == 'pickup';

    final hasSubscriptions = cartState.items.any((i) =>
        i.product.category.toLowerCase() == 'subscription' ||
        i.product.id.toString().startsWith('SUB_') ||
        i.product.name.toLowerCase().contains('(30 days plan)') ||
        i.product.name.toLowerCase().contains('subscription plan'));

    if ((hasSubscriptions || !bizConfig.codEnabled) && _paymentMode == 'COD') {
      _paymentMode = 'UPI';
    }

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
                  // Delivery Availability / Advance Ordering Alert Banner
                  if (!isPickup && (!bizConfig.isDeliveryAvailable || bizConfig.isAdvanceOrder)) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bizConfig.canOrder ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: bizConfig.canOrder ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            bizConfig.canOrder ? Icons.schedule_rounded : Icons.info_outline_rounded,
                            color: bizConfig.canOrder ? const Color(0xFF1D4ED8) : const Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bizConfig.availabilityMessage.isNotEmpty
                                  ? bizConfig.availabilityMessage
                                  : (bizConfig.canOrder
                                      ? 'Advance orders active! Check your scheduled delivery slot.'
                                      : 'Delivery is currently unavailable. Please check our next available delivery time.'),
                              style: TextStyle(
                                color: bizConfig.canOrder ? const Color(0xFF1E40AF) : const Color(0xFFB91C1C),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                        ] else if (_pickupEnabled && _pickupLocations.isNotEmpty) ...[
                          // Selectable 2-Option Cards (Home Delivery & Self Pickup)
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
                        ] else ...[
                          // When Pickup is disabled by admin, only Doorstep Delivery is shown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF7EB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFD6E6D3)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.local_shipping_outlined, color: AppColors.forestGreen, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Doorstep Delivery Available across Chennai & Kanchipuram zones.',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.forestGreen),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. LOCATION / ADDRESS SECTION
                  if (isPickup) ...[
                    // Dynamic Store Self-Pickup Information Card
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
                                'Select Pickup Store & Timings',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Dynamic Store Selector Dropdown
                          if (_pickupLocations.isNotEmpty) ...[
                            const Text(
                              'Choose Pickup Location *',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7EE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<dynamic>(
                                  isExpanded: true,
                                  value: _selectedPickupLocation ?? _pickupLocations.first,
                                  items: _pickupLocations.map((loc) {
                                    final name = loc['name'] ?? 'Store';
                                    final city = loc['city'] ?? '';
                                    return DropdownMenuItem<dynamic>(
                                      value: loc,
                                      child: Text(
                                        city.isNotEmpty ? '$name ($city)' : name,
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedPickupLocation = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Selected Store Details Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAF8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5EDE2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPickupLocation?['name'] ?? storeSettings.storeName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.forestGreen),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedPickupLocation?['address'] ?? storeSettings.storeAddress}, ${_selectedPickupLocation?['city'] ?? 'Kanchipuram'} - ${_selectedPickupLocation?['pincode'] ?? '631601'}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF4A5D4E), height: 1.3),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: AppColors.forestGreen),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Hours: ${_selectedPickupLocation?['timings'] ?? storeSettings.storeTimings}',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF4A5D4E)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.forestGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Contact: ${_selectedPickupLocation?['phone'] ?? storeSettings.storePhone}',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF4A5D4E)),
                                    ),
                                  ],
                                ),
                                if ((_selectedPickupLocation?['instructions'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.info_outline, size: 14, color: Color(0xFF55705C)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${_selectedPickupLocation['instructions']}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF55705C), fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
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
                    // Doorstep Delivery Address Card + Serviceable Locations
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
                              Expanded(
                                child: Row(
                                  children: const [
                                    Icon(Icons.location_on, color: AppColors.forestGreen, size: 20),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Delivery Address',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (addressState.addresses.isNotEmpty)
                                TextButton(
                                  onPressed: () => _showAddressSelectionModal(addressState.addresses),
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), visualDensity: VisualDensity.compact),
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
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    visualDensity: VisualDensity.compact,
                                  ),
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

                          // Serviceable Delivery Locations & Zone Selection Dropdown
                          if (_serviceableLocations.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF7EE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5EDE2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.location_city, size: 15, color: AppColors.forestGreen),
                                      SizedBox(width: 6),
                                      Text(
                                        'Select Delivery Zone *',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<dynamic>(
                                    initialValue: _selectedDeliveryZone ?? _serviceableLocations.first,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5EDE2))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5EDE2))),
                                    ),
                                    isExpanded: true,
                                    items: _serviceableLocations.map((loc) {
                                      final name = loc is Map ? (loc['name'] ?? 'Zone') : loc.toString();
                                      final city = loc is Map ? (loc['city'] ?? '') : '';
                                      final label = city.toString().isNotEmpty ? '$name, $city' : name;
                                      return DropdownMenuItem<dynamic>(
                                        value: loc,
                                        child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.forestGreen)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedDeliveryZone = val);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: const [
                                      Icon(Icons.verified, size: 14, color: AppColors.forestGreen),
                                      SizedBox(width: 6),
                                      Text(
                                        'Delivering Daily Across Key Zones:',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: _serviceableLocations.take(8).map((l) {
                                      final name = l is Map ? (l['name'] ?? '') : l.toString();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFD6E6D3)),
                                        ),
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.forestGreen),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
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
                            Icon(Icons.payment_rounded, color: AppColors.forestGreen, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Payment Method',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Payment Mode Selector (UPI vs COD)
                        RadioGroup<String>(
                          groupValue: _paymentMode,
                          onChanged: (val) {
                            if (val != null) {
                              if (val == 'COD' && (hasSubscriptions || !bizConfig.codEnabled)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      hasSubscriptions
                                          ? 'Milk Subscriptions require 100% online advance payment via UPI.'
                                          : 'Cash on Delivery is temporarily disabled storewide. Please pay online via UPI.',
                                    ),
                                    backgroundColor: const Color(0xFFB45309),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                              setState(() => _paymentMode = val);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Option 1: Instant Online Payment via UPI
                              InkWell(
                                onTap: () => setState(() => _paymentMode = 'UPI'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _paymentMode == 'UPI' ? const Color(0xFFF0FDF4) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _paymentMode == 'UPI' ? AppColors.forestGreen : const Color(0xFFE5EDE2),
                                      width: _paymentMode == 'UPI' ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Radio<String>(
                                        value: 'UPI',
                                        activeColor: AppColors.forestGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Instant Online Payment (UPI / QR)',
                                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.forestGreen),
                                            ),
                                            Text(
                                              'Google Pay, PhonePe, Paytm, BHIM, Cred or any UPI app',
                                              style: TextStyle(fontSize: 11, color: Color(0xFF6E8072)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Option 2: Cash on Delivery (COD)
                              InkWell(
                                onTap: (hasSubscriptions || !bizConfig.codEnabled)
                                    ? () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              hasSubscriptions
                                                  ? 'Milk Subscriptions require 100% online advance payment via UPI.'
                                                  : 'Cash on Delivery is temporarily disabled storewide. Please pay online via UPI.',
                                            ),
                                            backgroundColor: const Color(0xFFB45309),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    : () => setState(() => _paymentMode = 'COD'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _paymentMode == 'COD' ? const Color(0xFFFFFBEB) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _paymentMode == 'COD'
                                          ? const Color(0xFFD97706)
                                          : (hasSubscriptions || !bizConfig.codEnabled ? Colors.grey.shade200 : const Color(0xFFE5EDE2)),
                                      width: _paymentMode == 'COD' ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Radio<String>(
                                        value: 'COD',
                                        activeColor: const Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Cash on Delivery (COD)',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                    color: (hasSubscriptions || !bizConfig.codEnabled)
                                                        ? Colors.grey
                                                        : const Color(0xFF92400E),
                                                  ),
                                                ),
                                                if (hasSubscriptions || !bizConfig.codEnabled) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text(
                                                      'Unavailable',
                                                      style: TextStyle(fontSize: 9.5, color: Colors.grey, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              hasSubscriptions
                                                  ? 'Milk subscriptions require online payment'
                                                  : (!bizConfig.codEnabled
                                                      ? 'Disabled storewide by admin'
                                                      : 'Pay cash to delivery executive at doorstep'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: (hasSubscriptions || !bizConfig.codEnabled) ? Colors.grey : const Color(0xFFB45309),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        if (_paymentMode == 'COD') ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEF3C7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.payments_rounded, color: Color(0xFFB45309), size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cash on Delivery Selected',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Please keep ₹${calculatedGrandTotal.toStringAsFixed(0)} in cash ready for handover at your doorstep upon delivery.',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
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
                                child: Text(
                                  bizConfig.merchantName.isNotEmpty
                                      ? bizConfig.merchantName.toUpperCase()
                                      : 'THULIRVA OFFICIAL MERCHANT',
                                  style: const TextStyle(color: Color(0xFFF7D97B), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Real Merchant QR Image (Dynamic network or fallback)
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
                                child: bizConfig.qrImageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: ApiEndpoints.resolveImageUrl(bizConfig.qrImageUrl),
                                        fit: BoxFit.contain,
                                        placeholder: (_, __) => const Center(
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: CircularProgressIndicator(color: AppColors.forestGreen, strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Image.asset(
                                          'assets/images/payment_qr.jpg',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Icon(Icons.qr_code, size: 80, color: AppColors.forestGreen),
                                          ),
                                        ),
                                      )
                                    : Image.asset(
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
                                    Text(
                                      bizConfig.upiId.isNotEmpty ? bizConfig.upiId : '7904880944@superyes',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.forestGreen),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        final upi = bizConfig.upiId.isNotEmpty ? bizConfig.upiId : '7904880944@superyes';
                                        Clipboard.setData(ClipboardData(text: upi));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('✓ UPI ID $upi copied!'), duration: const Duration(seconds: 1)),
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
                text: _paymentMode == 'COD'
                    ? 'Confirm COD Order • ₹${calculatedGrandTotal.toStringAsFixed(0)}'
                    : 'Verify & Place Order • ₹${calculatedGrandTotal.toStringAsFixed(0)}',
                isLoading: _isSubmitting || orderState.isPlacingOrder || subState.isSubmitting,
                onPressed: (_isSubmitting || orderState.isPlacingOrder || subState.isSubmitting)
                    ? null
                    : _handlePlaceOrder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
