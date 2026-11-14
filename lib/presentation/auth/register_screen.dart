import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
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
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {});
    });
  }

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

    final passError = AppValidators.validatePassword(_passwordController.text);
    if (passError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passError),
          backgroundColor: AppColors.cancelled,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
          phone: AppValidators.cleanPhone(_phoneController.text),
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
    final passwordText = _passwordController.text;
    final strength = AppValidators.getPasswordStrength(passwordText);
    final missingReqs = AppValidators.getMissingPasswordRequirements(passwordText);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Official THULIRVA Artwork Banner (Smooth, Clean, Perfectly Proportioned)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back, color: AppColors.forestGreen, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x14174B36),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: AspectRatio(
                    aspectRatio: 1024.0 / 409.0, // Exact native banner aspect ratio
                    child: Image.asset(
                      'assets/images/thulirva_official_banner.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.forestGreen,
                        child: const Center(
                          child: Text(
                            '🌿 THULIRVA',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
                      'Join Thulirva for fresh daily farm dairy & agro products',
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
                      validator: AppValidators.validateName,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration('Enter your full name (min 2 chars)', Icons.person_outline),
                    ),
                    const SizedBox(height: 14),

                    // Phone Number (Numeric keyboard, 10-digit Indian standard)
                    _buildInputLabel('Mobile Number'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.validatePhone,
                      decoration: _inputDecoration('10-digit mobile (e.g. 9876543210)', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 14),

                    // Email Address
                    _buildInputLabel('Email Address'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: AppValidators.validateEmail,
                      decoration: _inputDecoration('Enter your email address', Icons.alternate_email),
                    ),
                    const SizedBox(height: 14),

                    // Strong Normal Password (NOT 6-digit PIN)
                    _buildInputLabel('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: AppValidators.validatePassword,
                      decoration: _inputDecoration(
                        'Strong password (min 8 chars)',
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

                    // Live Password Strength & Requirements Checklist
                    if (passwordText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: strength,
                                minHeight: 5,
                                backgroundColor: const Color(0xFFE5EDE2),
                                color: strength < 0.4
                                    ? Colors.red
                                    : (strength < 0.7 ? Colors.orange : AppColors.forestGreen),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            strength < 0.4
                                ? 'Weak'
                                : (strength < 0.7 ? 'Moderate' : 'Strong'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: strength < 0.4
                                  ? Colors.red
                                  : (strength < 0.7 ? Colors.orange : AppColors.forestGreen),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordChecklist(passwordText, missingReqs),
                    ],
                    const SizedBox(height: 14),

                    // Confirm Password
                    _buildInputLabel('Confirm Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      validator: (val) => AppValidators.validateConfirmPassword(val, _passwordController.text),
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

  Widget _buildPasswordChecklist(String pass, List<String> missing) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EDE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _checkItem('8+ characters', pass.length >= 8 && pass.length <= 64),
          _checkItem('At least 1 uppercase letter (A-Z)', RegExp(r'[A-Z]').hasMatch(pass)),
          _checkItem('At least 1 lowercase letter (a-z)', RegExp(r'[a-z]').hasMatch(pass)),
          _checkItem('At least 1 number (0-9)', RegExp(r'[0-9]').hasMatch(pass)),
          _checkItem('At least 1 special char (!@#\$%^&*)', RegExp(r'[!@#$%^&*()_+\-=\[\]{};\x27:"\\|,.<>\/?]').hasMatch(pass)),
          _checkItem('No spaces', !RegExp(r'\s').hasMatch(pass)),
        ],
      ),
    );
  }

  Widget _checkItem(String title, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: met ? AppColors.forestGreen : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: met ? FontWeight.w700 : FontWeight.w400,
              color: met ? AppColors.forestGreen : const Color(0xFF6E8072),
            ),
          ),
        ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
