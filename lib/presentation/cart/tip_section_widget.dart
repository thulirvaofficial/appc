import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';

class TipSectionWidget extends ConsumerStatefulWidget {
  const TipSectionWidget({super.key});

  @override
  ConsumerState<TipSectionWidget> createState() => _TipSectionWidgetState();
}

class _TipSectionWidgetState extends ConsumerState<TipSectionWidget> {
  static const List<int> _presetAmounts = [10, 20, 30, 50];
  final TextEditingController _customController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _selectPreset(int amount, CartNotifier notifier) {
    setState(() {
      _showCustomInput = false;
      _customController.clear();
    });
    notifier.setTip(amount.toDouble());
  }

  void _selectNoTip(CartNotifier notifier) {
    setState(() {
      _showCustomInput = false;
      _customController.clear();
    });
    notifier.removeTip();
  }

  void _openCustomInput(CartNotifier notifier, double currentTip, bool isCustom) {
    setState(() {
      _showCustomInput = true;
      if (isCustom && currentTip > 0) {
        _customController.text = currentTip.toStringAsFixed(0);
      } else {
        _customController.clear();
      }
    });
  }

  void _applyCustomTip(CartNotifier notifier) {
    final val = double.tryParse(_customController.text.trim()) ?? 0;
    if (val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid tip amount'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (val > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom tip cannot exceed ₹500'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _showCustomInput = false);
    notifier.setCustomTip(val);
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final currentTip = cartState.tipAmount;
    final isCustom = cartState.isCustomTip;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: currentTip > 0 ? const Color(0xFFC8E6C9) : const Color(0xFFE5EDE2),
          width: 1.2,
        ),
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
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7EE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.forestGreen, width: 1.2),
                ),
                child: const Center(
                  child: Text('🌱', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tip Your Delivery Partner',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.forestGreen),
                    ),
                    Text(
                      'Appreciate your delivery partner for bringing your order.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF6E8072)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Preset chips + No Tip + Custom
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // No Tip
              _buildTipChip(
                label: 'No Tip',
                isSelected: currentTip == 0 && !_showCustomInput,
                onTap: () => _selectNoTip(notifier),
              ),
              // Preset amounts
              ..._presetAmounts.map((amt) => _buildTipChip(
                label: '₹$amt',
                isSelected: !isCustom && currentTip == amt.toDouble() && !_showCustomInput,
                onTap: () => _selectPreset(amt, notifier),
              )),
              // Custom
              _buildTipChip(
                label: isCustom && currentTip > 0 && !_showCustomInput
                    ? 'Custom ₹${currentTip.toStringAsFixed(0)}'
                    : 'Custom',
                isSelected: _showCustomInput || (isCustom && currentTip > 0),
                onTap: () => _openCustomInput(notifier, currentTip, isCustom),
              ),
            ],
          ),

          // Custom input field
          if (_showCustomInput) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _customController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}(\.\d{0,2})?')),
                      ],
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter amount (max ₹500)',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFA0AFA2)),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.forestGreen),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFFAF7EE),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFD4E5CF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFD4E5CF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _applyCustomTip(notifier),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _applyCustomTip(notifier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],

          // Applied tip confirmation
          if (currentTip > 0 && !_showCustomInput) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Color(0xFF2E7D32), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '₹${currentTip.toStringAsFixed(0)} tip added — Thank you for your kindness! 💚',
                      style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forestGreen : const Color(0xFFEDF7EB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.forestGreen : const Color(0xFFD2E8CB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.forestGreen,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
