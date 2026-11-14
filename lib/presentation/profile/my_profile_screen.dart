import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/id_formatter.dart';
import '../../providers/auth_provider.dart';
import '../widgets/thulirva_app_bar.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).fetchProfile();
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.forestGreen),
                title: const Text('Take Photo with Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.forestGreen),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final photoFile = File(picked.path);
      final bytes = await photoFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final res = await ref.read(authProvider.notifier).uploadProfilePhoto(
        base64Image,
        photoFile: photoFile,
      );

      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        if (res != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Profile photo updated successfully!'),
              backgroundColor: AppColors.forestGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditProfileModal() {
    final user = ref.read(authProvider).user;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final altPhoneCtrl = TextEditingController(text: user?.alternatePhone ?? '');
    final addrCtrl = TextEditingController(text: user?.address ?? '');
    final cityCtrl = TextEditingController(text: user?.city ?? 'Kanchipuram');
    final pinCtrl = TextEditingController(text: user?.pincode ?? '631601');

    final originalPhone = user?.phone ?? '';
    bool phoneChanged = false;
    bool phoneVerified = true;
    bool isSendingOtp = false;
    bool isVerifyingOtp = false;
    String? otpSentMessage;
    final otpCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isPhoneDifferent = phoneCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim() != originalPhone.trim();
          phoneChanged = isPhoneDifferent;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Customer Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // Name
                  _buildEditField(controller: nameCtrl, label: 'Full Name *', icon: Icons.person_outline),
                  const SizedBox(height: 12),
                  // Email
                  _buildEditField(
                    controller: emailCtrl,
                    label: 'Email Address *',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  // Phone
                  _buildEditField(
                    controller: phoneCtrl,
                    label: 'Registered Mobile Number *',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    onChanged: (val) {
                      setModalState(() {
                        if (val.trim() == originalPhone.trim()) {
                          phoneVerified = true;
                        } else {
                          phoneVerified = false;
                        }
                      });
                    },
                  ),

                  // OTP Verification UI if phone changed
                  if (phoneChanged && !phoneVerified) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: Color(0xFFF57F17)),
                              SizedBox(width: 6),
                              Text(
                                'Phone Number OTP Verification Required',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF57F17),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: otpCtrl,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter 6-digit OTP',
                                    counterText: '',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: isSendingOtp
                                    ? null
                                    : () async {
                                        setModalState(() => isSendingOtp = true);
                                        final res = await ref.read(authProvider.notifier).sendPhoneOtp(phoneCtrl.text.trim());
                                        setModalState(() {
                                          isSendingOtp = false;
                                          otpSentMessage = res['otp'] != null ? 'Demo OTP: ${res['otp']}' : res['message'];
                                        });
                                      },
                                child: Text(isSendingOtp ? 'Sending...' : 'Send OTP'),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: isVerifyingOtp
                                    ? null
                                    : () async {
                                        setModalState(() => isVerifyingOtp = true);
                                        final ok = await ref.read(authProvider.notifier).verifyPhoneOtp(
                                              phoneCtrl.text.trim(),
                                              otpCtrl.text.trim(),
                                            );
                                        setModalState(() {
                                          isVerifyingOtp = false;
                                          phoneVerified = ok;
                                        });
                                        if (!ok && mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Invalid OTP. Please check and try again.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
                                child: Text(isVerifyingOtp ? '...' : 'Verify'),
                              ),
                            ],
                          ),
                          if (otpSentMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              otpSentMessage!,
                              style: const TextStyle(fontSize: 11, color: AppColors.forestGreen, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  if (phoneChanged && phoneVerified) ...[
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          'Phone verified with OTP',
                          style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Alternate Phone
                  _buildEditField(
                    controller: altPhoneCtrl,
                    label: 'Alternate Mobile Number (Optional)',
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  // Delivery Address
                  _buildEditField(
                    controller: addrCtrl,
                    label: 'Delivery Address *',
                    icon: Icons.home_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // City & Pincode
                  Row(
                    children: [
                      Expanded(
                        child: _buildEditField(
                          controller: cityCtrl,
                          label: 'City / District',
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildEditField(
                          controller: pinCtrl,
                          label: 'Pincode',
                          icon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6E8072)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF6E8072), fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final phone = phoneCtrl.text.trim();
                            final altPhone = altPhoneCtrl.text.trim();
                            final addr = addrCtrl.text.trim();
                            final city = cityCtrl.text.trim();
                            final pin = pinCtrl.text.trim();

                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter your full name')),
                              );
                              return;
                            }
                            if (email.isEmpty || !email.contains('@')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid email address')),
                              );
                              return;
                            }
                            if (phone.isEmpty || phone.length < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
                              );
                              return;
                            }
                            if (phoneChanged && !phoneVerified) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please complete OTP verification for the new phone number')),
                              );
                              return;
                            }

                            Navigator.pop(ctx);

                            final success = await ref.read(authProvider.notifier).updateProfile(
                                  name: name,
                                  email: email,
                                  phone: phone,
                                  alternatePhone: altPhone.isNotEmpty ? altPhone : null,
                                  address: addr.isNotEmpty ? addr : null,
                                  city: city.isNotEmpty ? city : null,
                                  pincode: pin.isNotEmpty ? pin : null,
                                );

                            if (mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Profile updated successfully! Changes synced to account.'),
                                    backgroundColor: AppColors.forestGreen,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update profile. Please try again.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forestGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.forestGreen, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5EDE2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFFBFBF8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'T';
    final photoUrl = user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
        ? ApiEndpoints.resolveImageUrl(user.profilePhoto!)
        : null;

    final memberSinceText = user?.createdAt != null && user!.createdAt!.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.tryParse(user.createdAt!) ?? DateTime.now())
        : 'Registered Customer';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: ThulirvaAppBar(
        showBack: true,
        onBack: () => Navigator.pop(context),
        showNotifications: false,
        showCart: false,
        customActions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.forestGreen),
            tooltip: 'Edit Profile',
            onPressed: _showEditProfileModal,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: () async {
            await ref.read(authProvider.notifier).fetchProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Header with Photo & Name
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: AppColors.forestGreen, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.forestGreen.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? const Center(
                                      child: CircularProgressIndicator(color: AppColors.forestGreen),
                                    )
                                  : photoUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: photoUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                                          ),
                                          errorWidget: (_, __, ___) => Center(
                                            child: Text(
                                              initial,
                                              style: const TextStyle(
                                                fontSize: 42,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.forestGreen,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              fontSize: 42,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.forestGreen,
                                            ),
                                          ),
                                        ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadPhoto,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: AppColors.forestGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'THULIRVA Customer',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'customer@thulirva.com',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6E8072),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => IdFormatter.copyToClipboard(context, IdFormatter.formatCustomerId(user?.id), label: 'Customer ID'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEFD7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                IdFormatter.formatCustomerId(user?.id),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forestGreen,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy, size: 12, color: AppColors.forestGreen),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Personal Information Card
                _buildSectionCard(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  items: [
                    _buildInfoTile('Full Name', user?.name ?? '—', Icons.badge_outlined),
                    _buildInfoTile('Email Address', user?.email ?? '—', Icons.email_outlined),
                    _buildInfoTile('Registered Mobile', user?.phone?.isNotEmpty == true ? user!.phone! : 'Not provided', Icons.phone_outlined),
                    _buildInfoTile('Alternate Mobile', user?.alternatePhone?.isNotEmpty == true ? user!.alternatePhone! : 'Not set', Icons.phone_android_outlined),
                  ],
                ),
                const SizedBox(height: 14),

                // 3. Delivery Address Card
                _buildSectionCard(
                  title: 'Default Delivery Address',
                  icon: Icons.location_on_outlined,
                  items: [
                    _buildInfoTile('Address', user?.address?.isNotEmpty == true ? user!.address! : 'No address saved', Icons.home_outlined),
                    _buildInfoTile('City / District', user?.city ?? 'Kanchipuram', Icons.location_city_outlined),
                    _buildInfoTile('Pincode', user?.pincode ?? '631601', Icons.pin_drop_outlined),
                  ],
                ),
                const SizedBox(height: 14),

                // 4. Account Details Card
                _buildSectionCard(
                  title: 'Account Summary',
                  icon: Icons.info_outline,
                  items: [
                    _buildInfoTile('Account ID', '#${user?.id ?? 1}', Icons.tag),
                    _buildInfoTile('Account Role', user?.role.toUpperCase() ?? 'CUSTOMER', Icons.verified_user_outlined),
                    _buildInfoTile('Member Since', memberSinceText, Icons.calendar_today_outlined),
                  ],
                ),
                const SizedBox(height: 24),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _showEditProfileModal,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EDE2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: AppColors.forestGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F4EE)),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF8A9A7A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6E8072),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263228),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

