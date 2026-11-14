import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomerSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final String hintText;
  final FocusNode? focusNode;
  final bool autoFocus;

  const CustomerSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onFilterTap,
    this.hintText = 'Search fresh milk, paneer, ghee...',
    this.focusNode,
    this.autoFocus = false,
  });

  @override
  State<CustomerSearchBar> createState() => _CustomerSearchBarState();
}

class _CustomerSearchBarState extends State<CustomerSearchBar> {
  late final FocusNode _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _effectiveFocusNode.hasFocus);
    }
  }

  void _handleTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(CustomerSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChange);
      widget.controller.addListener(_handleTextChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode).removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26), // Perfect smooth capsule curve
        border: Border.all(
          color: _isFocused ? AppColors.forestGreen : const Color(0xFFD0DFCE),
          width: _isFocused ? 2.0 : 1.2,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.forestGreen.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Center(
        child: TextField(
          focusNode: _effectiveFocusNode,
          controller: widget.controller,
          autofocus: widget.autoFocus,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: AppColors.forestGreen,
          cursorWidth: 2.0,
          cursorHeight: 20,
          cursorRadius: const Radius.circular(2),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF173F2D),
          ),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            fillColor: Colors.transparent,
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF7A8E7A),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                Icons.search_rounded,
                size: 22,
                color: _isFocused ? AppColors.forestGreen : const Color(0xFF5D7A68),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 52),
            suffixIcon: hasText
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      widget.controller.clear();
                      widget.onChanged?.call('');
                      widget.onClear?.call();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE5EDE2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.close_rounded, size: 15, color: AppColors.forestGreen),
                        ),
                      ),
                    ),
                  )
                : (widget.onFilterTap != null
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onFilterTap,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7EE),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFDDEBDD)),
                            ),
                            child: const Center(
                              child: Icon(Icons.tune_rounded, size: 16, color: AppColors.forestGreen),
                            ),
                          ),
                        ),
                      )
                    : null),
            suffixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 52),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          ),
        ),
      ),
    );
  }
}
