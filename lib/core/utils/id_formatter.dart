import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IdFormatter {
  /// Format an Order ID into standard THU-000001 format.
  /// Handles numeric IDs (1 -> THU-000001, 14 -> THU-000014, 125 -> THU-000125),
  /// raw strings, and existing prefixed values.
  static String formatOrderId(dynamic id) {
    if (id == null) return 'THU-000001';
    final str = id.toString().trim();
    if (str.isEmpty) return 'THU-000001';

    // If already in full THU-XXXXXX format with digits
    final matchThu = RegExp(r'^THU[-_]?(\d+)$', caseSensitive: false).firstMatch(str);
    if (matchThu != null) {
      final numStr = matchThu.group(1)!;
      final parsed = int.tryParse(numStr);
      if (parsed != null) {
        return 'THU-${parsed.toString().padLeft(6, '0')}';
      }
      return 'THU-${numStr.padLeft(6, '0')}';
    }

    // If pure number (e.g. 1, 14, 125)
    final numVal = int.tryParse(str);
    if (numVal != null) {
      return 'THU-${numVal.toString().padLeft(6, '0')}';
    }

    // If contains order date prefix e.g. THU-20261107-1234
    if (str.toUpperCase().startsWith('THU-')) {
      return str.toUpperCase();
    }

    return 'THU-$str';
  }

  /// Format a Customer ID into standard CUS-000001 format.
  /// Handles numeric IDs (1 -> CUS-000001, 125 -> CUS-000125),
  /// raw strings, and prefixed values.
  static String formatCustomerId(dynamic id) {
    if (id == null) return 'CUS-000001';
    final str = id.toString().trim();
    if (str.isEmpty) return 'CUS-000001';

    // Check if starts with CUS, ORD, or SUB prefix
    final match = RegExp(r'^(CUS|ORD|SUB)[-_]?(\d+)$', caseSensitive: false).firstMatch(str);
    if (match != null) {
      final numStr = match.group(2)!;
      final parsed = int.tryParse(numStr);
      if (parsed != null) {
        return 'CUS-${parsed.toString().padLeft(6, '0')}';
      }
      return 'CUS-${numStr.padLeft(6, '0')}';
    }

    // Pure number
    final numVal = int.tryParse(str);
    if (numVal != null) {
      return 'CUS-${numVal.toString().padLeft(6, '0')}';
    }

    if (str.toUpperCase().startsWith('CUS-')) {
      return str.toUpperCase();
    }

    return 'CUS-$str';
  }

  /// Format a Subscription ID into standard SUB-000001 format.
  static String formatSubscriptionId(dynamic id) {
    if (id == null) return 'SUB-000001';
    final str = id.toString().trim();
    if (str.isEmpty) return 'SUB-000001';

    final match = RegExp(r'^SUB[-_]?(\d+)$', caseSensitive: false).firstMatch(str);
    if (match != null) {
      final numStr = match.group(1)!;
      final parsed = int.tryParse(numStr);
      if (parsed != null) {
        return 'SUB-${parsed.toString().padLeft(6, '0')}';
      }
      return 'SUB-${numStr.padLeft(6, '0')}';
    }

    final numVal = int.tryParse(str);
    if (numVal != null) {
      return 'SUB-${numVal.toString().padLeft(6, '0')}';
    }

    if (str.toUpperCase().startsWith('SUB-')) {
      return str.toUpperCase();
    }

    return 'SUB-$str';
  }

  /// Copy text to clipboard and display user feedback snackbar
  static Future<void> copyToClipboard(BuildContext context, String text, {String label = 'ID'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('$label copied: $text', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: const Color(0xFF174B36),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

