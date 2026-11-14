class AppValidators {
  /// 3.1 Mobile Number Validation (Indian: 10 digits starting with 6, 7, 8, or 9)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final raw = value.trim();
    if (RegExp(r'[a-zA-Z]').hasMatch(raw)) {
      return 'Mobile number must contain digits only';
    }
    String digits = raw.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }
    return null;
  }

  /// Clean / Normalize phone number to 10 digits
  static String cleanPhone(String raw) {
    String digits = raw.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// 3.2 Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final email = value.trim().toLowerCase();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address (e.g. name@example.com)';
    }
    return null;
  }

  /// 3.3 Strong Normal Password Validation (NOT 6-digit numeric PIN)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    final missing = getMissingPasswordRequirements(value);
    if (missing.isNotEmpty) {
      return missing.first;
    }
    return null;
  }

  /// Detailed missing requirements list for UI feedback
  static List<String> getMissingPasswordRequirements(String password) {
    final missing = <String>[];
    if (password.length < 8) {
      missing.add('At least 8 characters');
    }
    if (password.length > 64) {
      missing.add('Maximum 64 characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      missing.add('At least one uppercase letter (A-Z)');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      missing.add('At least one lowercase letter (a-z)');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      missing.add('At least one number (0-9)');
    }
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};\x27:"\\|,.<>\/?]').hasMatch(password)) {
      missing.add('At least one special character (!@#\$%^&*)');
    }
    if (RegExp(r'\s').hasMatch(password)) {
      missing.add('No spaces allowed');
    }
    return missing;
  }

  /// Password Strength Score: 0.0 (weak) to 1.0 (very strong)
  static double getPasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{};\x27:"\\|,.<>\/?]').hasMatch(password)) score++;
    if (!RegExp(r'\s').hasMatch(password)) score++;
    return (score / 7.0).clamp(0.0, 1.0);
  }

  /// Confirm Password Match
  static String? validateConfirmPassword(String? confirmPassword, String originalPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (confirmPassword != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// 3.4 Name Validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    final clean = value.trim();
    if (clean.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (clean.length > 60) {
      return 'Name cannot exceed 60 characters';
    }
    if (!RegExp(r'[a-zA-Z\u0B80-\u0BFF]').hasMatch(clean)) {
      return 'Name must contain letters';
    }
    return null;
  }

  /// 3.5 Indian PIN Code Validation (6 digits, does not start with 0)
  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN code is required';
    }
    final clean = value.trim();
    if (!RegExp(r'^[1-9]\d{5}$').hasMatch(clean)) {
      return 'Enter a valid 6-digit Indian PIN code (cannot start with 0)';
    }
    return null;
  }

  /// 3.6 Address Validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }
    return null;
  }

  /// 3.7 UTR / Transaction Reference Validation
  static String? validateUtr(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'UTR / Transaction Reference is required';
    }
    final clean = value.trim();
    if (clean.length < 6 || clean.length > 35) {
      return 'UTR must be between 6 and 35 alphanumeric characters';
    }
    return null;
  }

  /// 3.8 Price Validation
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final num = double.tryParse(value.trim());
    if (num == null || num < 0) {
      return 'Price must be a valid non-negative number';
    }
    return null;
  }

  /// 3.8 Quantity Validation
  static String? validateQuantity(String? value, [int? maxStock]) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    final qty = int.tryParse(value.trim());
    if (qty == null || qty <= 0) {
      return 'Quantity must be at least 1';
    }
    if (maxStock != null && qty > maxStock) {
      return 'Quantity cannot exceed available stock ($maxStock)';
    }
    return null;
  }
}

