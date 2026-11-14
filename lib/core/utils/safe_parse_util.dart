/// Reusable JSON Numeric & Data Parsing Utilities for Thulirva Apps
/// Prevents: NoSuchMethodError: Class 'String' has no instance method 'toDouble'.
/// Receiver: "999.00"
class SafeParseUtil {
  /// Safely converts any dynamic value (String, int, double, num, or null) into a double.
  /// Handles "999.00", "₹999.00", 999, 999.0, null, "", etc.
  static double toDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final clean = value.replaceAll(RegExp(r'[^0-9.-]'), '').trim();
      if (clean.isEmpty) return defaultValue;
      return double.tryParse(clean) ?? defaultValue;
    }
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  /// Safely converts any dynamic value into an int.
  static int toInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) {
      final clean = value.replaceAll(RegExp(r'[^0-9-]'), '').trim();
      if (clean.isEmpty) return defaultValue;
      final parsedDouble = double.tryParse(clean);
      if (parsedDouble != null) return parsedDouble.round();
      return int.tryParse(clean) ?? defaultValue;
    }
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  /// Safely converts any dynamic value into a num.
  static num toNum(dynamic value, [num defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value;
    return toDouble(value, defaultValue.toDouble());
  }

  /// Formats currency with guaranteed safety
  static String formatCurrency(dynamic value, {String symbol = '₹'}) {
    final d = toDouble(value);
    if (d == d.roundToDouble()) {
      return '$symbol${d.round()}';
    }
    return '$symbol${d.toStringAsFixed(2)}';
  }
}

