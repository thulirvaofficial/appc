import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

class CreateTicketScreen extends StatefulWidget {
  final String? prefillOrderId;

  const CreateTicketScreen({super.key, this.prefillOrderId});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _orderIdController = TextEditingController();

  String _selectedCategory = 'Order Delay';
  String _selectedPriority = 'NORMAL';
  File? _attachment;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Order Delay',
    'Quality Issue',
    'Payment / Refund',
    'Damaged Items',
    'Subscription Query',
    'App Issue',
    'Other Query',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefillOrderId != null && widget.prefillOrderId!.isNotEmpty) {
      _orderIdController.text = widget.prefillOrderId!;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    _orderIdController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _attachment = File(picked.path));
    }
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final mapData = <String, dynamic>{
        'category': _selectedCategory,
        'subject': _subjectController.text.trim(),
        'description': _descController.text.trim(),
        'priority': _selectedPriority,
      };

      if (_orderIdController.text.trim().isNotEmpty) {
        mapData['order_id'] = _orderIdController.text.trim();
      }

      if (_attachment != null) {
        mapData['attachment'] = await MultipartFile.fromFile(
          _attachment!.path,
          filename: _attachment!.path.split(Platform.pathSeparator).last,
        );
      }

      final formData = FormData.fromMap(mapData);
      final res = await _apiClient.dio.post('support/tickets', data: formData);

      if (res.data != null && res.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.forestGreen,
              content: Text('Support ticket submitted successfully! Our team will respond shortly.'),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(res.data?['message'] ?? 'Failed to submit ticket');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
        title: const Text(
          'Raise Support Ticket',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: AppColors.forestGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Our customer care team typically resolves delivery and product issues within 2 to 4 hours.',
                        style: TextStyle(fontSize: 12, color: AppColors.forestGreen, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Category dropdown
              const Text('Issue Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subject field
              const Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'e.g. Milk delivery delayed for morning slot',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Subject is required';
                  if (val.trim().length < 5) return 'Subject should be at least 5 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Order ID (Optional)
              const Text('Related Order ID (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _orderIdController,
                decoration: InputDecoration(
                  hintText: 'e.g. THU-20261118-0042',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Priority Selector
              const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _priorityChip('NORMAL', 'Normal'),
                  const SizedBox(width: 8),
                  _priorityChip('HIGH', 'High'),
                  const SizedBox(width: 8),
                  _priorityChip('URGENT', 'Urgent'),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Describe Your Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Provide complete details to help us resolve quickly...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  contentPadding: const EdgeInsets.all(14),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Description is required';
                  if (val.trim().length < 10) return 'Please describe in at least 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Attachment
              const Text('Attach Photo or Proof (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 6),
              if (_attachment == null)
                InkWell(
                  onTap: _pickAttachment,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.camera_alt_outlined, color: AppColors.forestGreen, size: 28),
                        SizedBox(height: 6),
                        Text('Tap to select photo from gallery', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_attachment!, height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 16, color: Colors.white),
                          onPressed: () => setState(() => _attachment = null),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Submit Support Ticket',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityChip(String value, String label) {
    final isSelected = _selectedPriority == value;
    Color chipColor = Colors.grey;
    if (value == 'URGENT') chipColor = Colors.red;
    if (value == 'HIGH') chipColor = Colors.orange;
    if (value == 'NORMAL') chipColor = AppColors.forestGreen;

    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : chipColor, fontWeight: FontWeight.bold, fontSize: 12)),
      selected: isSelected,
      selectedColor: chipColor,
      backgroundColor: Colors.white,
      side: BorderSide(color: chipColor),
      onSelected: (val) {
        if (val) setState(() => _selectedPriority = value);
      },
    );
  }
}

