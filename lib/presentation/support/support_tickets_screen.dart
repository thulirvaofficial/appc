import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../data/models/support_ticket_model.dart';
import 'create_ticket_screen.dart';
import 'ticket_chat_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<SupportTicketModel> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.dio.get('support/tickets');
      if (res.data != null && res.data['success'] == true) {
        final list = res.data['tickets'] as List?;
        if (list != null && mounted) {
          setState(() {
            _tickets = list
                .map((j) => SupportTicketModel.fromJson(j as Map<String, dynamic>))
                .toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
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

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('delay')) return Icons.access_time;
    if (cat.contains('quality')) return Icons.verified;
    if (cat.contains('pay') || cat.contains('refund')) return Icons.payment;
    if (cat.contains('damage')) return Icons.broken_image_outlined;
    if (cat.contains('subscript')) return Icons.calendar_today;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        elevation: 0,
        title: const Text(
          'Customer Care & Support',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forestGreen,
        icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
        label: const Text('Raise Ticket', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
          );
          if (created == true) _fetchTickets();
        },
      ),
      body: RefreshIndicator(
        color: AppColors.forestGreen,
        onRefresh: _fetchTickets,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Channels Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D6B45)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.headset_mic_outlined, color: AppColors.gold, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Direct Care Helpdesk',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Dedicated farm operations support team is available every morning to assist you.',
                      style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildContactChip(Icons.phone, '+91 79048 80944'),
                        const SizedBox(width: 8),
                        _buildContactChip(Icons.email_outlined, 'support@thulirva.com'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Frequently Asked Questions
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              _buildFaqTile(
                'When does morning delivery arrive?',
                'Daily morning farm dispatches arrive between 6:00 AM and 8:00 AM at your doorstep.',
              ),
              _buildFaqTile(
                'How do refunds work?',
                'Refunds for missed deliveries or cancelled items are credited back to your original payment method or wallet within 24-48 hours.',
              ),
              _buildFaqTile(
                'How to pause my milk subscription?',
                'You can pause your subscription anytime before 7:00 PM for the next morning from the Subscriptions tab.',
              ),
              const SizedBox(height: 22),

              // Tickets Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Support Tickets',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16, color: AppColors.forestGreen),
                    label: const Text('New Ticket', style: TextStyle(color: AppColors.forestGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () async {
                      final created = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                      );
                      if (created == true) _fetchTickets();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Ticket List
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
                )
              else if (_tickets.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      const Text(
                        'No support tickets raised yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Need assistance with an order or subscription? Tap Raise Ticket below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final t = _tickets[index];
                    return _buildTicketCard(t);
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.gold),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
        children: [
          Text(answer, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35)),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket) {
    final statusColor = _getStatusColor(ticket.status);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketChatScreen(
              ticketId: ticket.ticketId,
              subject: ticket.subject,
              initialStatus: ticket.status,
            ),
          ),
        );
        _fetchTickets();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getCategoryIcon(ticket.category), size: 16, color: AppColors.forestGreen),
                    const SizedBox(width: 6),
                    Text(
                      ticket.ticketId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor, width: 0.8),
                  ),
                  child: Text(
                    ticket.status.replaceAll('_', ' '),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.subject,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (ticket.orderId != null && ticket.orderId!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Order: ${ticket.orderId}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontFamily: 'monospace')),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(ticket.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

