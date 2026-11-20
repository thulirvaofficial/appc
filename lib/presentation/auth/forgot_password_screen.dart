import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_client.dart';
import '../widgets/thulirva_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final ApiClient _apiClient = ApiClient();

  // 4 Standardized Steps:
  // 0 = Email Input
  // 1 = OTP Verification
  // 2 = Create New Password
  // 3 = Success
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 0: Email Input
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _userEmail = '';

  // Step 1: 6-Digit OTP & Timers
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  Timer? _cooldownTimer;
  Timer? _expiryTimer;
  int _cooldownSecondsLeft = 60;
  int _expirySecondsLeft = 300; // 5 minutes
  bool _isExpired = false;
  String? _resetToken;

  // Step 2: Create New Password
  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    _expiryTimer?.cancel();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        backgroundColor: isError ? AppColors.cancelled : AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==========================================
  // STEP 0: Email Input & Generic Dispatch
  // ==========================================
  Future<void> _handleSendResetOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      _userEmail = email;
      final cooldown = (res.data is Map && res.data['cooldownSeconds'] != null)
          ? (res.data['cooldownSeconds'] as num).toInt()
          : 60;

      setState(() {
        _currentStep = 1;
        _isExpired = false;
      });

      _startTimers(cooldownSeconds: cooldown, expirySeconds: 300);

      // Reset and auto-focus first OTP box
      for (final c in _otpControllers) {
        c.clear();
      }
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _otpFocusNodes[0].canRequestFocus) {
          _otpFocusNodes[0].requestFocus();
        }
      });

      _showSnackBar(
        res.data?['message'] ?? 'If an account exists with this email address, a verification code has been sent.',
      );
    } on DioException catch (e) {
      // Even if network returned error or generic message
      final msg = e.response?.data?['message'] ?? 'If an account exists with this email address, a verification code has been sent.';
      _userEmail = email;
      setState(() {
        _currentStep = 1;
        _isExpired = false;
      });
      _startTimers(cooldownSeconds: 60, expirySeconds: 300);
      _showSnackBar(msg);
    } catch (_) {
      _showSnackBar('Network error while requesting verification code. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // STEP 1: OTP Timers & Verification
  // ==========================================
  void _startTimers({int cooldownSeconds = 60, int expirySeconds = 300}) {
    _cooldownTimer?.cancel();
    _expiryTimer?.cancel();

    setState(() {
      _cooldownSecondsLeft = cooldownSeconds;
      _expirySecondsLeft = expirySeconds;
      _isExpired = false;
    });

    // 1. Resend cooldown timer
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSecondsLeft > 1) {
        if (mounted) setState(() => _cooldownSecondsLeft--);
      } else {
        timer.cancel();
        if (mounted) setState(() => _cooldownSecondsLeft = 0);
      }
    });

    // 2. 5-minute expiry countdown timer
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expirySecondsLeft > 1) {
        if (mounted) setState(() => _expirySecondsLeft--);
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _expirySecondsLeft = 0;
            _isExpired = true;
          });
        }
      }
    });
  }

  String _formatExpiryTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handleResendOtp() async {
    if (_cooldownSecondsLeft > 0) return;

    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.resendResetOtp,
        data: {'email': _userEmail},
      );

      final cooldown = (res.data is Map && res.data['cooldownSeconds'] != null)
          ? (res.data['cooldownSeconds'] as num).toInt()
          : 60;

      for (final c in _otpControllers) {
        c.clear();
      }
      _startTimers(cooldownSeconds: cooldown, expirySeconds: 300);
      _showSnackBar('A new 6-digit verification code has been dispatched.');
      if (_otpFocusNodes[0].canRequestFocus) {
        _otpFocusNodes[0].requestFocus();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not resend code. Please wait.';
      _showSnackBar(msg, isError: true);
    } catch (_) {
      _showSnackBar('Network error while resending verification code.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_isExpired) {
      _showSnackBar('Verification code has expired. Please request a new code.', isError: true);
      return;
    }

    final otp = _otpControllers.map((c) => c.text.trim()).join();
    if (otp.length != 6) {
      _showSnackBar('Please enter all 6 digits of your verification code.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.verifyResetOtp,
        data: {
          'email': _userEmail,
          'otp': otp,
        },
      );

      if (res.data != null && res.data['success'] == true && res.data['reset_token'] != null) {
        _cooldownTimer?.cancel();
        _expiryTimer?.cancel();
        setState(() {
          _resetToken = res.data['reset_token'];
          _currentStep = 2;
        });
        _showSnackBar('Code verified! Please create your new password.');
      } else {
        final msg = res.data?['message'] ?? 'Invalid or expired verification code.';
        _showSnackBar(msg, isError: true);
        for (final c in _otpControllers) {
          c.clear();
        }
        if (_otpFocusNodes[0].canRequestFocus) {
          _otpFocusNodes[0].requestFocus();
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Invalid or expired verification code.';
      _showSnackBar(msg, isError: true);
      for (final c in _otpControllers) {
        c.clear();
      }
      if (_otpFocusNodes[0].canRequestFocus) {
        _otpFocusNodes[0].requestFocus();
      }
    } catch (_) {
      _showSnackBar('Network error while verifying code. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // STEP 2: Password Reset & Validation
  // ==========================================
  bool get _hasLength => _newPasswordController.text.length >= 10;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_newPasswordController.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_newPasswordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPasswordController.text);
  bool get _hasSpecial => RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_=+\\\[\]~/`]').hasMatch(_newPasswordController.text);
  bool get _hasMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;

  int get _strengthScore {
    final pwd = _newPasswordController.text;
    if (pwd.isEmpty) return 0;
    int s = 0;
    if (pwd.length >= 8) s++;
    if (_hasLength) s++;
    if (_hasUpper && _hasLower) s++;
    if (_hasNumber && _hasSpecial) s++;
    return s.clamp(0, 4);
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 1:
        return const Color(0xFFEF4444); // Weak
      case 2:
        return const Color(0xFFF59E0B); // Fair
      case 3:
        return const Color(0xFF10B981); // Good
      case 4:
        return AppColors.forestGreen; // Strong
      default:
        return const Color(0xFFEF4444);
    }
  }

  String get _strengthLabel {
    switch (_strengthScore) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Too Weak';
    }
  }

  Future<void> _handleResetPassword() async {
    final p1 = _newPasswordController.text;
    final p2 = _confirmPasswordController.text;

    if (p1.isEmpty || p2.isEmpty) {
      _showSnackBar('Please fill in both password fields.', isError: true);
      return;
    }
    if (!_hasLength) {
      _showSnackBar('Password must be at least 10 characters in length.', isError: true);
      return;
    }
    if (!_hasUpper) {
      _showSnackBar('Password must contain at least one uppercase letter (A-Z).', isError: true);
      return;
    }
    if (!_hasLower) {
      _showSnackBar('Password must contain at least one lowercase letter (a-z).', isError: true);
      return;
    }
    if (!_hasNumber) {
      _showSnackBar('Password must contain at least one number (0-9).', isError: true);
      return;
    }
    if (!_hasSpecial) {
      _showSnackBar('Password must contain at least one special character (!@#\$).', isError: true);
      return;
    }
    if (!_hasMatch) {
      _showSnackBar('Passwords do not match. Please verify.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': _userEmail,
          'reset_token': _resetToken,
          'new_password': p1,
          'confirm_password': p2,
        },
      );

      if (res.data != null && res.data['success'] == true) {
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _currentStep = 3);
        _showSnackBar('Password reset successfully!');
      } else {
        final msg = res.data?['message'] ?? 'Failed to update password.';
        _showSnackBar(msg, isError: true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to update password.';
      _showSnackBar(msg, isError: true);
    } catch (_) {
      _showSnackBar('Network error while updating password.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // BUILD METHOD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          _currentStep == 3 ? 'Success' : 'Reset Password',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.forestGreen,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.forestGreen),
        leading: _currentStep == 3
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_currentStep > 0 && _currentStep < 3) {
                    setState(() => _currentStep--);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentStep < 3) _buildStepProgressIndicator(),
              const SizedBox(height: 24),
              if (_currentStep == 0) _buildEmailStep(),
              if (_currentStep == 1) _buildOtpStep(),
              if (_currentStep == 2) _buildNewPasswordStep(),
              if (_currentStep == 3) _buildSuccessStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        final isCurrent = index == _currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            height: 4.5,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.gold
                  : (isActive ? AppColors.forestGreen : const Color(0xFFDDE8D5)),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  // --- Step 0: Email Input Screen ---
  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forgot your password?',
            style: AppTypography.displayMedium.copyWith(color: AppColors.forestGreen, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Don\'t worry. Enter your registered email address and we\'ll send you a verification code to securely reset your password.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight, height: 1.45),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your registered email address';
              }
              final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
              if (!emailRegex.hasMatch(val.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'e.g. name@example.com',
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.forestGreen, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ThulirvaButton(
              text: 'Send Verification Code',
              isLoading: _isLoading,
              onPressed: _handleSendResetOtp,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '← Back to Sign In',
                style: TextStyle(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 1: 6-Digit OTP Verification Screen ---
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify your email',
          style: AppTypography.displayMedium.copyWith(color: AppColors.forestGreen, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the 6-digit verification code sent to your email address.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(height: 12),

        // Destination Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2E4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email, size: 16, color: AppColors.forestGreen),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _userEmail,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Expiry Timer Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isExpired ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isExpired ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isExpired ? Icons.warning_amber_rounded : Icons.timer_outlined,
                size: 18,
                color: _isExpired ? const Color(0xFFDC2626) : const Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              Text(
                _isExpired
                    ? 'Verification code expired. Please resend a new code.'
                    : 'Code expires in: ${_formatExpiryTime(_expirySecondsLeft)}',
                style: TextStyle(
                  color: _isExpired ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 6 Segmented PIN Boxes with Auto-Advance, Backspace & Paste
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 46,
              height: 54,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                  fontFamily: 'monospace',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
                  ),
                ),
                onChanged: (val) {
                  // Handle single digit auto-advance
                  if (val.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (val.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 18),

        // Resend Cooldown Row
        Center(
          child: _cooldownSecondsLeft == 0
              ? TextButton(
                  onPressed: _isLoading ? null : _handleResendOtp,
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  'Resend code in ${_cooldownSecondsLeft}s',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          child: ThulirvaButton(
            text: 'Verify Code',
            isLoading: _isLoading,
            onPressed: _isExpired ? null : _handleVerifyOtp,
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: const Text(
              '← Use a different email address',
              style: TextStyle(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 2: Create New Password Screen ---
  Widget _buildNewPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create a new password',
            style: AppTypography.displayMedium.copyWith(color: AppColors.forestGreen, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Ensure your new password meets all security criteria below.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 24),

          // New Password Field
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPass,
            decoration: InputDecoration(
              labelText: 'New password',
              hintText: 'Enter new password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.forestGreen, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic Password Strength Meter
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEADBBE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Password Strength:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    Text(
                      _strengthLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _strengthColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 4-Segment Bar
                Row(
                  children: List.generate(4, (i) {
                    final isFilled = i < _strengthScore;
                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: isFilled ? _strengthColor : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // Live 6-Item Checklist
                _buildChecklistItem('At least 10 characters', _hasLength),
                const SizedBox(height: 6),
                _buildChecklistItem('At least 1 uppercase letter (A-Z)', _hasUpper),
                const SizedBox(height: 6),
                _buildChecklistItem('At least 1 lowercase letter (a-z)', _hasLower),
                const SizedBox(height: 6),
                _buildChecklistItem('At least 1 number (0-9)', _hasNumber),
                const SizedBox(height: 6),
                _buildChecklistItem('At least 1 special character (!@#\$)', _hasSpecial),
                const SizedBox(height: 6),
                _buildChecklistItem('Passwords match', _hasMatch),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPass,
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              hintText: 'Confirm new password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.forestGreen, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ThulirvaButton(
              text: 'Reset Password',
              isLoading: _isLoading,
              onPressed: _handleResetPassword,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isPassed) {
    return Row(
      children: [
        Icon(
          isPassed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 15,
          color: isPassed ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isPassed ? FontWeight.w600 : FontWeight.normal,
            color: isPassed ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // --- Step 3: Success Confirmation Screen ---
  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 36),
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF16A34A), width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3316A34A),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 46),
            ),
            const SizedBox(height: 26),
            const Text(
              'Password Reset Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0B3515),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your password has been updated successfully. You can now sign in to your Thulirva account using your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ThulirvaButton(
                text: 'Back to Login',
                onPressed: () {
                  // Return email to pre-fill on login screen
                  Navigator.pop(context, _userEmail);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
