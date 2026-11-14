import 'package:flutter_test/flutter_test.dart';
import 'package:thulirva_app/core/utils/safe_parse_util.dart';

void main() {
  group('SafeParseUtil Tests', () {
    test('toDouble handles String "999.00" without crashing', () {
      expect(SafeParseUtil.toDouble("999.00"), 999.00);
      expect(SafeParseUtil.toDouble("₹999.50"), 999.50);
      expect(SafeParseUtil.toDouble("1,250.75"), 1250.75);
    });

    test('toDouble handles numeric, int, double and null safely', () {
      expect(SafeParseUtil.toDouble(999), 999.0);
      expect(SafeParseUtil.toDouble(999.5), 999.5);
      expect(SafeParseUtil.toDouble(null, 10.0), 10.0);
      expect(SafeParseUtil.toDouble("", 0.0), 0.0);
      expect(SafeParseUtil.toDouble("invalid", 5.0), 5.0);
    });

    test('toInt handles String, double, and null safely', () {
      expect(SafeParseUtil.toInt("42"), 42);
      expect(SafeParseUtil.toInt(42.8), 43);
      expect(SafeParseUtil.toInt(null, 1), 1);
      expect(SafeParseUtil.toInt(""), 0);
    });

    test('formatCurrency formats accurately', () {
      expect(SafeParseUtil.formatCurrency("999.00"), "₹999");
      expect(SafeParseUtil.formatCurrency(99.5), "₹99.50");
      expect(SafeParseUtil.formatCurrency(null), "₹0");
    });
  });
}

