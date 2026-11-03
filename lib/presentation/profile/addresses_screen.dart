import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/address_model.dart';
import '../../providers/address_provider.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/thulirva_button.dart';
import '../widgets/thulirva_text_field.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  void _showAddEditAddressDialog(BuildContext context, WidgetRef ref, [AddressModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? 'Chennai');
    final pinCtrl = TextEditingController(text: existing?.pincode ?? '600078');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existing == null ? 'Add Delivery Address' : 'Edit Address'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ThulirvaTextField(
                  controller: nameCtrl,
                  label: 'Recipient Name *',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                ThulirvaTextField(
                  controller: phoneCtrl,
                  label: 'Phone Number *',
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                ThulirvaTextField(
                  controller: addrCtrl,
                  label: 'Street / Flat Address *',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                ThulirvaTextField(
                  controller: cityCtrl,
                  label: 'City *',
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                ThulirvaTextField(
                  controller: pinCtrl,
                  label: 'PIN Code *',
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newAddr = AddressModel(
                id: existing?.id ?? DateTime.now().millisecondsSinceEpoch,
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                city: cityCtrl.text.trim(),
                pincode: pinCtrl.text.trim(),
                isDefault: existing?.isDefault ?? false,
              );

              if (existing == null) {
                await ref.read(addressProvider.notifier).addAddress(newAddr);
              } else {
                await ref.read(addressProvider.notifier).updateAddress(newAddr);
              }

              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
            child: const Text('Save Address', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addrState = ref.watch(addressProvider);
    final addresses = addrState.addresses;

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: Text('My Addresses', style: AppTypography.displaySmall.copyWith(fontSize: 18)),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: addrState.isLoading && addresses.isEmpty
            ? const LoadingIndicator(message: 'Loading saved addresses...')
            : addresses.isEmpty
                ? EmptyStateView(
                    title: 'No Addresses Found',
                    message: 'Add your doorstep delivery address for morning milk dispatch.',
                    emoji: '📍',
                    buttonText: '+ Add New Address',
                    onButtonPressed: () => _showAddEditAddressDialog(context, ref),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final addr = addresses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                          border: Border.all(
                            color: addr.isDefault ? AppColors.forestGreen : AppColors.border,
                            width: addr.isDefault ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(addr.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                if (addr.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreenBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('DEFAULT', style: TextStyle(color: AppColors.forestGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(addr.fullAddressString, style: AppTypography.bodySmall.copyWith(color: AppColors.textMid)),
                            Text('📞 ${addr.phone}', style: AppTypography.bodySmall.copyWith(color: AppColors.textLight)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _showAddEditAddressDialog(context, ref, addr),
                                  child: const Text('Edit', style: TextStyle(color: AppColors.forestGreen, fontSize: 12)),
                                ),
                                TextButton(
                                  onPressed: () => ref.read(addressProvider.notifier).deleteAddress(addr.id),
                                  child: const Text('Delete', style: TextStyle(color: AppColors.cancelled, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: ThulirvaButton(
            text: '+ Add New Delivery Address',
            onPressed: () => _showAddEditAddressDialog(context, ref),
          ),
        ),
      ),
    );
  }
}

