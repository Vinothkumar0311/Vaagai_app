import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaagai/core/models/doubt_model.dart';
import 'package:vaagai/providers/auth_provider.dart';
import 'package:vaagai/providers/doubt_provider.dart';
import 'package:intl/intl.dart';

class DoubtChatScreen extends StatefulWidget {
  final DoubtModel doubt;
  const DoubtChatScreen({super.key, required this.doubt});

  @override
  State<DoubtChatScreen> createState() => _DoubtChatScreenState();
}

class _DoubtChatScreenState extends State<DoubtChatScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSubmitting = false;

  void _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    
    try {
      final doubtProvider = Provider.of<DoubtProvider>(context, listen: false);
      await doubtProvider.replyToDoubt(
        doubtId: widget.doubt.id,
        staffReply: text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('பதில் அனுப்பப்பட்டது (Reply sent)')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final isStaff = user?.role == 'staff' || user?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('சந்தேகம் (Doubt Resolution)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoubtCard(),
            const SizedBox(height: 24),
            _buildReplySection(isStaff),
          ],
        ),
      ),
    );
  }

  Widget _buildDoubtCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: const Icon(Icons.person, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.doubt.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(DateFormat('MMM dd, yyyy • hh:mm a').format(widget.doubt.createdAt),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              _buildStatusBadge(widget.doubt.status),
            ],
          ),
          const Divider(height: 24),
          Text(widget.doubt.courseName, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Video: ${widget.doubt.videoTitle}', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('At ${_formatDuration(widget.doubt.timestampSeconds)}',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('கேள்வி (Question):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(widget.doubt.message, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildReplySection(bool isStaff) {
    if (widget.doubt.staffReply != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text('பதில் (Staff Reply):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Text(widget.doubt.staffReply!, style: const TextStyle(fontSize: 15, height: 1.5)),
            if (widget.doubt.repliedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Replied on: ${DateFormat('MMM dd, yyyy • hh:mm a').format(widget.doubt.repliedAt!)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ]
          ],
        ),
      );
    }

    if (isStaff) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('பதில் எழுதுக (Write Reply):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _replyController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'மாணவருக்கு பதில் எழுதவும்...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _sendReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('அனுப்புக (Send Reply)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, color: Colors.grey.shade300, size: 48),
          const SizedBox(height: 8),
          const Text('பதிலுக்காக காத்திருக்கவும் (Waiting for reply)', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DoubtStatus status) {
    Color color = status == DoubtStatus.replied ? Colors.green : Colors.orange;
    String label = status == DoubtStatus.replied ? 'Replied' : 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
