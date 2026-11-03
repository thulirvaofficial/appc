import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../main_wrapper.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.cancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          phone: _phoneController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Welcome to THULIRVA! Account created successfully.'),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
        (route) => false,
      );
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Registration failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.cancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Top Pastoral Farm Artwork Banner
            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                color: AppColors.forestGreen,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/login_hero.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.forestGreen),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: 40,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Smooth curve transition
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF7EE),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Form Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: AppColors.forestGreen,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Join Thulirva for fresh daily farm dairy & products',
                      style: TextStyle(
                        color: Color(0xFF6E8072),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    _buildInputLabel('Full Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                      decoration: _inputDecoration('Enter your full name', Icons.person_outline),
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    _buildInputLabel('Phone Number'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your phone number' : null,
                      decoration: _inputDecoration('Enter 10-digit phone number', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 14),

                    // Email Address
                    _buildInputLabel('Email Address'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val == null || !val.contains('@') ? 'Please enter a valid email' : null,
                      decoration: _inputDecoration('Enter your email address', Icons.alternate_email),
                    ),
                    const SizedBox(height: 14),

                    // Password
                    _buildInputLabel('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                      decoration: _inputDecoration(
                        'Create password (min 6 chars)',
                        Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF6E8072),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password
                    _buildInputLabel('Confirm Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      validator: (val) => val == null || val.isEmpty ? 'Please confirm your password' : null,
                      decoration: _inputDecoration(
                        'Re-enter your password',
                        Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF6E8072),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Create Account',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Already have an account? Sign In
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: TextStyle(color: Color(0xFF6E8072), fontSize: 13.5),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.forestGreen,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData prefixIcon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF6E8072), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5EDE2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5EDE2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.8),
      ),
    );
  }
}
