import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../widgets/thulirva_button.dart';
import '../widgets/thulirva_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgot() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).forgotPassword(_emailController.text);
    if (!mounted) return;

    if (success) {
      setState(() => _submitted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send reset instructions. Please try again.'),
          backgroundColor: AppColors.cancelled,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.lightCream,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: _submitted
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.lightGreenBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.naturalGreen, width: 2),
                        ),
                        child: const Icon(Icons.check, color: AppColors.naturalGreen, size: 36),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Email Sent!',
                        style: AppTypography.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We have sent password reset instructions to ${_emailController.text}. Please check your inbox.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 200,
                        child: ThulirvaButton(
                          text: 'Back to Login',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forgot Your Password?',
                        style: AppTypography.displayMedium.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your registered email address and we will send you instructions to reset your password.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 28),

                      ThulirvaTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.forestGreen, size: 20),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter your email';
                          if (!val.contains('@')) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      ThulirvaButton(
                        text: 'Send Reset Link',
                        isLoading: authState.isLoading,
                        onPressed: _handleForgot,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

