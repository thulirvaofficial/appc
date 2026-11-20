import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/support_ticket_model.dart';

class TicketChatScreen extends StatefulWidget {
  final String ticketId;
  final String subject;
  final String initialStatus;

  const TicketChatScreen({
    super.key,
    required this.ticketId,
    required this.subject,
    required this.initialStatus,
  });

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiClient _apiClient = ApiClient();

  SupportTicketModel? _ticket;
  List<SupportMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    try {
      final response = await _apiClient.dio.get('support/tickets/${widget.ticketId}');
      if (response.data != null && response.data['success'] == true) {
        final ticketData = response.data['ticket'];
        if (mounted && ticketData != null) {
          setState(() {
            _ticket = SupportTicketModel.fromJson(ticketData);
            _messages = _ticket!.messages;
            _isLoading = false;
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);
    try {
      FormData formData;
      if (_selectedImage != null) {
        formData = FormData.fromMap({
          'message': text.isNotEmpty ? text : 'Photo attached',
          'attachment': await MultipartFile.fromFile(
            _selectedImage!.path,
            filename: _selectedImage!.path.split(Platform.pathSeparator).last,
          ),
        });
      } else {
        formData = FormData.fromMap({'message': text});
      }

      final res = await _apiClient.dio.post(
        'support/tickets/${widget.ticketId}/messages',
        data: formData,
      );

      if (res.data != null && res.data['success'] == true) {
        _msgController.clear();
        setState(() => _selectedImage = null);
        await _loadTicketDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _reopenTicket() async {
    final reasonController = TextEditingController();
    final shouldReopen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reopen Support Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please describe why you would like to reopen this ticket:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestGreen),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reopen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldReopen != true) return;

    try {
      final res = await _apiClient.dio.post(
        'support/tickets/${widget.ticketId}/reopen',
        data: {'reason': reasonController.text.trim()},
      );
      if (res.data != null && res.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Support ticket reopened successfully.')),
          );
        }
        await _loadTicketDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reopen ticket: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.purple;
      case 'WAITING_FOR_CUSTOMER':
      case 'WAITING_FOR_PARTNER':
        return Colors.orange;
      case 'RESOLVED':
        return AppColors.forestGreen;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _ticket?.status ?? widget.initialStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticketId,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppColors.gold,
              ),
            ),
            Text(
              widget.subject,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(status), width: 1),
              ),
              child: Text(
                status.replaceAll('_', ' '),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          if (_ticket != null && _ticket!.assignedAgent != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.forestGreen.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, size: 16, color: AppColors.forestGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned to ${_ticket!.assignedAgent}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ),

          // Messages Stream
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.forestGreen),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Send a message to contact support.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = !msg.isAdmin;
                          return _buildChatBubble(msg, isUser);
                        },
                      ),
          ),

          // Selected Image Preview
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(_selectedImage!, width: 48, height: 48, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  const Text('Image attached', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          // Reopen Prompt Banner if resolved/closed
          if (status.toUpperCase() == 'RESOLVED' || status.toUpperCase() == 'CLOSED')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF92400E)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This ticket is closed. Still having issues?',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _reopenTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF92400E),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(60, 30),
                    ),
                    child: const Text('Reopen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),

          // Composer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppColors.forestGreen),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _isSending
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forestGreen),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.forestGreen,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 18),
                            onPressed: _sendMessage,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(SupportMessageModel msg, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                msg.senderName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isUser ? AppColors.forestGreen : Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('hh:mm a').format(msg.createdAt),
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.forestGreen : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isUser ? 14 : 2),
                bottomRight: Radius.circular(isUser ? 2 : 14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
              border: isUser ? null : Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.message,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isUser ? Colors.white : Colors.black87,
                    height: 1.35,
                  ),
                ),
                if (msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ApiEndpoints.resolveImageUrl(msg.attachmentUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

