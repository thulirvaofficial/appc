import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../../../core/constants/api_endpoints.dart';

class InAppChatSheet extends StatefulWidget {
  final String orderId;
  final String partnerName;
  final String? partnerPhone;
  final VoidCallback? onCall;
  final socket_io.Socket? socket;

  const InAppChatSheet({
    super.key,
    required this.orderId,
    required this.partnerName,
    this.partnerPhone,
    this.onCall,
    this.socket,
  });

  @override
  State<InAppChatSheet> createState() => _InAppChatSheetState();
}

class _InAppChatSheetState extends State<InAppChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  final List<String> _quickChips = const [
    'Where are you now?',
    'Please call when you reach',
    'Leave packet at doorstep',
    'Ring the doorbell please',
    'I am waiting outside',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _setupSocketListener();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupSocketListener() {
    if (widget.socket != null) {
      widget.socket!.on('chat:message', (data) {
        if (!mounted || data is! Map) return;
        final msgOrderId = data['order_id']?.toString() ?? data['orderId']?.toString();
        if (msgOrderId == widget.orderId.toString()) {
          final msgId = data['id']?.toString() ?? '';
          final alreadyExists = _messages.any((m) => m['id']?.toString() == msgId);
          if (!alreadyExists) {
            setState(() {
              _messages.add(Map<String, dynamic>.from(data));
            });
            _scrollToBottom();
          }
        }
      });
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final url = '${ApiEndpoints.baseUrl}/orders/${widget.orderId}/chat';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['messages'] is List) {
          final list = (data['messages'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (mounted) {
            setState(() {
              _messages = list;
              _isLoading = false;
            });
            _scrollToBottom();
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('[InAppChat] Error loading messages: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (_messages.isEmpty) {
          _messages = [
            {
              'id': 'welcome-1',
              'sender': 'system',
              'sender_name': 'Thulirva Support',
              'text': 'Chat directly with ${widget.partnerName} for delivery updates and instructions.',
              'timestamp': DateTime.now().toIso8601String(),
            }
          ];
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _isSending) return;

    _textController.clear();
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = {
      'id': tempId,
      'order_id': widget.orderId,
      'sender': 'customer',
      'sender_name': 'You',
      'text': cleanText,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(optimisticMsg);
      _isSending = true;
    });
    _scrollToBottom();

    // Broadcast via Socket.IO if connected
    if (widget.socket != null && widget.socket!.connected) {
      widget.socket!.emit('chat:message', {
        'orderId': widget.orderId,
        'order_id': widget.orderId,
        'sender': 'customer',
        'sender_name': 'Customer',
        'text': cleanText,
      });
    }

    // Persist via REST API
    try {
      final url = '${ApiEndpoints.baseUrl}/orders/${widget.orderId}/chat';
      final response = await _dio.post(
        url,
        data: {
          'sender': 'customer',
          'sender_name': 'Customer',
          'text': cleanText,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final savedMsg = response.data['message'];
        if (savedMsg is Map && mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m['id'] == tempId);
            if (idx != -1) {
              _messages[idx] = Map<String, dynamic>.from(savedMsg);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[InAppChat] Error sending message via REST: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Chat Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A859),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.partnerName.isNotEmpty
                            ? widget.partnerName.substring(0, 1).toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.partnerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Icon(Icons.two_wheeler_rounded, size: 12, color: Color(0xFF00A859)),
                          SizedBox(width: 4),
                          Text(
                            'Delivery Partner • Online',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF00A859),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.onCall != null) ...[
                  IconButton(
                    onPressed: widget.onCall,
                    icon: const Icon(Icons.phone_rounded, color: Color(0xFF00A859)),
                    tooltip: 'Call Partner',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFDCFCE7),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: Color(0xFFE2E8F0)),

          // 3. Quick Chips Row
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final chip = _quickChips[i];
                return ActionChip(
                  label: Text(
                    chip,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => _sendMessage(chip),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // 4. Message List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A859)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final sender = (msg['sender'] ?? 'customer').toString().toLowerCase();
                      final text = msg['text']?.toString() ?? '';
                      final timeStr = _formatTime(msg['timestamp']?.toString());
                      final isMe = sender == 'customer';
                      final isSystem = sender == 'system';

                      if (isSystem) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.76,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF00A859) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                            ),
                            border: isMe ? null : Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMe) ...[
                                Text(
                                  widget.partnerName,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF00A859),
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.3,
                                  color: isMe ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 5. Bottom Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message to partner...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_textController.text),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A859),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
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
}

