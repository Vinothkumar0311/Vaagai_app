import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../core/models/course_access_model.dart';
import '../../core/models/payment_record_model.dart';
import '../widgets/course_widgets.dart';

/// Admin screen to view and approve/reject student payment registrations.
class AdminPaymentApprovalScreen extends StatelessWidget {
  const AdminPaymentApprovalScreen({super.key});

  static const Color _primary = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'கட்டண ஒப்புதல்',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primary,
                fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _primary,
          elevation: 0,
          bottom: TabBar(
            labelColor: _primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _primary,
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(text: 'PENDING'),
              Tab(text: 'SUCCESS'),
              Tab(text: 'FAILED'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PaymentList(statusFilters: const ['pending', 'verification_pending']),
            _PaymentList(statusFilters: const ['success']),
            _PaymentList(statusFilters: const ['failed']),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTERED LIST
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentList extends StatelessWidget {
  final List<String> statusFilters;
  const _PaymentList({required this.statusFilters});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('status', whereIn: statusFilters)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmpty(statusFilters.first);
        }

        final records = snapshot.data!.docs
            .map((d) => PaymentRecordModel.fromFirestore(d))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, i) =>
              _PaymentCard(record: records[i]),
        );
      },
    );
  }

  Widget _buildEmpty(String status) {
    final labels = {
      'pending': 'நிலுவையில் உள்ள கோரிக்கைகள் இல்லை',
      'success': 'ஒப்புதல் பெற்ற கோரிக்கைகள் இல்லை',
      'failed': 'நிராகரிக்கப்பட்ட கோரிக்கைகள் இல்லை',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(labels[status] ?? 'பட்டியல் இல்லை',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final PaymentRecordModel record;
  static const Color _primary = Color(0xFF1B5E20);

  const _PaymentCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isPending = record.status == PaymentRecordStatus.pending ||
        record.status == PaymentRecordStatus.verificationPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _primary.withOpacity(0.1),
                  child: Text(
                    record.userName.isNotEmpty
                        ? record.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(record.userEmail,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                StatusChip.fromPaymentStatus(_toLegacyStatus(record.status)),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.menu_book_rounded, 'பாடம்',
                    record.courseItems.map((e) => e.courseTitle).join(', ')),
                // const SizedBox(height: 8),
                // _infoRow(Icons.currency_rupee_rounded, 'தொகை', '₹ ${record.amount}'),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.calendar_today_rounded,
                  'தேதி',
                  _formatDate(record.createdAt),
                ),
                if (record.submittedPaymentRef != null && record.submittedPaymentRef!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.tag_rounded, 'Ref ID', record.submittedPaymentRef!),
                ],
                if (record.rejectionReason != null &&
                    record.status == PaymentRecordStatus.failed) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.info_outline_rounded, 'காரணம்',
                      record.rejectionReason!,
                      valueColor: Colors.red.shade600),
                ],

                // Payment proof link (only if an actual URL exists)
                if (record.paymentScreenshotUrl != null && record.paymentScreenshotUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openUrl(record.paymentScreenshotUrl!),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 6),
                        Text('கட்டண ஆதாரம் பார்க்கவும்',
                            style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ],

                // Action Buttons (Pending only)
                if (isPending) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          context: context,
                          label: 'நிராகரி',
                          icon: Icons.close_rounded,
                          color: Colors.red.shade600,
                          onTap: () => _handleReject(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionButton(
                          context: context,
                          label: 'ஒப்புதல்',
                          icon: Icons.check_rounded,
                          color: _primary,
                          onTap: () => _handleApprove(context),
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? Colors.white : color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: filled ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const ConfirmActionDialog(
        title: 'கட்டணம் ஒப்புதல்',
        subtitle: 'இந்த மாணவரின் கட்டணத்தை ஒப்புக்கொண்டு பாடம் திறக்கவுமா?',
        confirmLabel: 'ஒப்புதல்',
        confirmColor: Color(0xFF1B5E20),
      ),
    );
    if (result == null || !context.mounted) return;

    final admin =
        Provider.of<AuthProvider>(context, listen: false).userModel;
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    final error = await provider.approvePayment(
      payment: record,
      adminId: admin?.uid ?? 'admin',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            error == null ? const Color(0xFF1B5E20) : Colors.red.shade700,
        content: Text(
          error == null ? '✅ கட்டணம் ஒப்புக்கொள்ளப்பட்டது, பாடம் திறக்கப்பட்டது!' : '❌ $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handleReject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const ConfirmActionDialog(
        title: 'கட்டணம் நிராகரிப்பு',
        subtitle: 'இந்த கோரிக்கையை நிராகரிக்கவுமா?',
        showReasonField: true,
        confirmLabel: 'நிராகரி',
        confirmColor: Colors.red,
      ),
    );
    if (reason == null || !context.mounted) return;

    final admin =
        Provider.of<AuthProvider>(context, listen: false).userModel;
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    final error = await provider.rejectPayment(
      payment: record,
      adminId: admin?.uid ?? 'admin',
      reason: reason == 'confirmed' ? 'Rejected by admin' : reason,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            error == null ? Colors.orange.shade700 : Colors.red.shade700,
        content: Text(
          error == null ? '❌ கட்டணம் நிராகரிக்கப்பட்டது' : '❌ $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  PaymentStatus _toLegacyStatus(PaymentRecordStatus status) {
    switch (status) {
      case PaymentRecordStatus.success:
        return PaymentStatus.approved;
      case PaymentRecordStatus.failed:
        return PaymentStatus.rejected;
      case PaymentRecordStatus.pending:
      case PaymentRecordStatus.verificationPending:
        return PaymentStatus.pending;
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
