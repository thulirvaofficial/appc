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

  // Current Step: 0 = Identifier, 1 = Choose Method, 2 = Verify OTP, 3 = Reset Password, 4 = Success
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 0: Identifier
  final _identifierFormKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  // Account & Methods details
  String _maskedEmail = '';
  String _maskedPhone = '';
  List<String> _availableMethods = [];
  String _selectedMethod = 'email'; // 'email' or 'sms'
  String _destinationText = '';

  // Step 2: 6-Digit OTP Inputs
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  Timer? _countdownTimer;
  int _remainingSeconds = 60;
  bool _canResend = false;
  String? _resetToken;

  // Step 3: Password Reset
  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void dispose() {
    _identifierController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.cancelled : AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Step 0: Find Account ---
  Future<void> _handleFindAccount() async {
    if (!_identifierFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final identifier = _identifierController.text.trim();

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'identifier': identifier},
      );

      if (res.data != null && res.data['success'] == true) {
        final methods = (res.data['methods'] as List? ?? ['email']).map((e) => e.toString()).toList();
        setState(() {
          _maskedEmail = res.data['masked_email'] ?? '';
          _maskedPhone = res.data['masked_phone'] ?? '';
          _availableMethods = methods;
          _selectedMethod = methods.contains('email') ? 'email' : (methods.isNotEmpty ? methods.first : 'email');
          _currentStep = 1;
        });
      } else {
        final msg = res.data?['message'] ?? 'No account found matching this identifier.';
        _showSnackBar(msg, isError: true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'No account found matching this email or mobile number.';
      _showSnackBar(msg, isError: true);
    } catch (_) {
      _showSnackBar('Network error while looking up account. Please check your connection.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Step 1: Send OTP ---
  Future<void> _handleSendOtp() async {
    setState(() => _isLoading = true);
    final identifier = _identifierController.text.trim();

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.sendResetOtp,
        data: {
          'identifier': identifier,
          'method': _selectedMethod,
        },
      );

      if (res.data != null && res.data['success'] == true) {
        setState(() {
          _destinationText = res.data['destination'] ?? (_selectedMethod == 'email' ? _maskedEmail : _maskedPhone);
          _currentStep = 2;
          for (final c in _otpControllers) {
            c.clear();
          }
        });
        _startCountdown(res.data['cooldownSeconds'] ?? 60);
        _showSnackBar('Verification code sent to $_destinationText');
        // Auto focus first OTP field
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _otpFocusNodes[0].requestFocus();
        });
      } else {
        _showSnackBar(res.data?['message'] ?? 'Failed to send verification code.', isError: true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to send verification code.';
      _showSnackBar(msg, isError: true);
    } catch (_) {
      _showSnackBar('Network error. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Countdown timer for resend
  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = seconds;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        if (mounted) setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _remainingSeconds = 0;
            _canResend = true;
          });
        }
      }
    });
  }

  // Resend OTP
  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    final identifier = _identifierController.text.trim();

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.resendResetOtp,
        data: {
          'identifier': identifier,
          'method': _selectedMethod,
        },
      );

      if (res.data != null && res.data['success'] == true) {
        for (final c in _otpControllers) {
          c.clear();
        }
        _startCountdown(res.data['cooldownSeconds'] ?? 60);
        _showSnackBar('A new 6-digit code has been dispatched.');
        _otpFocusNodes[0].requestFocus();
      } else {
        _showSnackBar(res.data?['message'] ?? 'Could not resend code. Please wait.', isError: true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Could not resend code. Please wait.';
      _showSnackBar(msg, isError: true);
    } catch (_) {
      _showSnackBar('Network error while resending code.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Step 2: Verify OTP ---
  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    if (otp.length != 6) {
      _showSnackBar('Please enter all 6 digits of the verification code.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final identifier = _identifierController.text.trim();

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.verifyResetOtp,
        data: {
          'identifier': identifier,
          'otp': otp,
        },
      );

      if (res.data != null && res.data['success'] == true && res.data['reset_token'] != null) {
        setState(() {
          _resetToken = res.data['reset_token'];
          _currentStep = 3;
        });
        _countdownTimer?.cancel();
        _showSnackBar('Code verified! Please create your new password.');
      } else {
        _showSnackBar(res.data?['message'] ?? 'Invalid or expired code.', isError: true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Invalid or expired code.';
      _showSnackBar(msg, isError: true);
    } catch (_) {
      _showSnackBar('Network error while verifying code. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Step 3: Reset Password ---
  Future<void> _handleResetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final p1 = _newPasswordController.text;
    final p2 = _confirmPasswordController.text;

    if (p1 != p2) {
      _showSnackBar('Passwords do not match. Please verify.', isError: true);
      return;
    }
    if (p1.length < 6) {
      _showSnackBar('Password must be at least 6 characters.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'reset_token': _resetToken,
          'new_password': p1,
          'confirm_password': p2,
        },
      );

      if (res.data != null && res.data['success'] == true) {
        setState(() => _currentStep = 4);
      } else {
        _showSnackBar(res.data?['message'] ?? 'Failed to update password.', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          _currentStep == 4 ? 'Success' : 'Reset Password',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.forestGreen),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.forestGreen),
        leading: _currentStep == 4
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_currentStep > 0 && _currentStep < 4) {
                    setState(() => _currentStep--);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentStep < 4) _buildStepProgressIndicator(),
              const SizedBox(height: 24),
              if (_currentStep == 0) _buildIdentifierStep(),
              if (_currentStep == 1) _buildChooseMethodStep(),
              if (_currentStep == 2) _buildOtpStep(),
              if (_currentStep == 3) _buildNewPasswordStep(),
              if (_currentStep == 4) _buildSuccessStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressIndicator() {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index <= _currentStep;
        final isCurrent = index == _currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.gold
                  : (isActive ? AppColors.forestGreen : AppColors.softGreen.withAlpha(100)),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  // --- Step 0 Widget: Enter Email or Phone ---
  Widget _buildIdentifierStep() {
    return Form(
      key: _identifierFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find Your Account', style: AppTypography.displayMedium.copyWith(color: AppColors.forestGreen)),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address or mobile number to receive a verification code.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your registered email or phone number';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Email or Mobile Number',
              hintText: 'e.g. 9876543210 or name@example.com',
              prefixIcon: const Icon(Icons.person_search_outlined, color: AppColors.forestGreen, size: 20),
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
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ThulirvaButton(
              text: 'Find Account',
              isLoading: _isLoading,
              onPressed: _handleFindAccount,
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 1 Widget: Choose Verification Channel ---
  Widget _buildChooseMethodStep() {
    final hasEmail = _availableMethods.contains('email') && _maskedEmail.isNotEmpty;
    final hasSms = _availableMethods.contains('sms') && _maskedPhone.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Method', style: AppTypography.displayMedium.copyWith(color: AppColors.forestGreen)),
        const SizedBox(height: 8),
        Text(
          'Select where you want to receive your 6-digit password reset code:',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
        ),
        const SizedBox(height: 24),

        if (hasEmail)
          _buildMethodTile(
            method: 'email',
            icon: Icons.email_outlined,
            title: 'Send code via Email',
            subtitle: _maskedEmail,
          ),

        if (hasSms)
          _buildMethodTile(
            method: 'sms',
            icon: Icons.phone_android_outlined,
            title: 'Send code via SMS',
            subtitle: _maskedPhone,
          ),

        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ThulirvaButton(
            text: 'Send Verification Code',
            isLoading: _isLoading,
            onPressed: _handleSendOtp,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTile({
    required String method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFFBF8F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.forestGreen : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.forestGreen.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.lightGreenBg : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.forestGreen, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            // ignore: deprecated_member_use
            Radio<String>(
              value: method,
              // ignore: deprecated_member_use
              groupValue: _selectedMethod,
              activeColor: AppColors.forestGreen,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) setState(() => _selectedMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2 Widget: 6-Digit OTP Entry ---
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter 6-Digit Code', style: AppTypography.displayMedium.copyWith(color: AppColors.forestGreen)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
            children: [
              const TextSpan(text: 'We sent a verification code to '),
              TextSpan(
                text: _destinationText,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forestGreen),
              ),
              const TextSpan(text: '. Code expires in 5 minutes.'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 6 Segmented PIN Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 46,
              height: 52,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.forestGreen),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
                  ),
                ),
                onChanged: (val) {
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
        const SizedBox(height: 20),

        // Countdown & Resend
        Center(
          child: _canResend
              ? TextButton(
                  onPressed: _isLoading ? null : _handleResendOtp,
                  child: const Text(
                    'Resend Verification Code',
                    style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )
              : Text(
                  '⏱️ Resend code in ${_remainingSeconds}s',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ThulirvaButton(
            text: 'Verify Code',
            isLoading: _isLoading,
            onPressed: _handleVerifyOtp,
          ),
        ),
      ],
    );
  }

  // --- Step 3 Widget: Set New Password ---
  Widget _buildNewPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create New Password', style: AppTypography.displayMedium.copyWith(color: AppColors.forestGreen)),
          const SizedBox(height: 8),
          Text(
            'Create a strong password of at least 6 characters for your THULIRVA account.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPass,
            validator: (val) {
              if (val == null || val.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.forestGreen, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.8)),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPass,
            validator: (val) {
              if (val != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.forestGreen, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.8)),
            ),
          ),
          const SizedBox(height: 32),

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

  // --- Step 4 Widget: Success Confirmation ---
  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lightGreenBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.naturalGreen, width: 2.5),
            ),
            child: const Icon(Icons.check, color: AppColors.naturalGreen, size: 44),
          ),
          const SizedBox(height: 24),
          Text('Password Reset Complete!', style: AppTypography.displaySmall.copyWith(color: AppColors.forestGreen)),
          const SizedBox(height: 10),
          Text(
            'Your password has been successfully updated. You can now log in using your new credentials.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 220,
            child: ThulirvaButton(
              text: 'Back to Sign In',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
