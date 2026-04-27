import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/notification_model.dart';
import '../../core/models/doubt_model.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class StaffNotificationInboxScreen extends StatelessWidget {
  const StaffNotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1B5E20);
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login first")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "அறிவிப்புகள் (Notifications)",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => provider.markAllAsRead(user.uid),
            icon: const Icon(Icons.done_all_rounded),
            tooltip: "Mark all as read",
          ),
          IconButton(
            onPressed: () => _confirmClearAll(context, provider, user.uid),
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: "Clear all",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: provider.notificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final note = notifications[index];
              return Dismissible(
                key: Key(note.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return true;
                },
                onDismissed: (_) {
                  provider.deleteNotification(note.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("அறிவிப்பு நீக்கப்பட்டது (Notification Deleted)", style: TextStyle(fontSize: 12)), duration: Duration(seconds: 1)),
                  );
                },
                child: _NotificationCard(note: note, primaryGreen: primaryGreen),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context, NotificationProvider provider, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("அனைத்தையும் நீக்கவா? (Clear All?)"),
        content: const Text("அனைத்து அறிவிப்புகளையும் நீக்க விரும்புகிறீர்களா? இதை மாற்ற முடியாது."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              provider.clearAllNotifications(userId);
              Navigator.pop(ctx);
            },
            child: const Text("CLEAR ALL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text(
            "அறிவிப்புகள் எதுவும் இல்லை",
            style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "புதிய அறிவிப்புகள் வரும்போது இங்கே தெரியும்",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel note;
  final Color primaryGreen;

  const _NotificationCard({required this.note, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: note.isRead ? null : Border.all(color: primaryGreen.withOpacity(0.1), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onNotificationTap(context, note, provider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon / Avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: note.isRead ? Colors.grey.shade100 : primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    note.type == 'doubt' ? Icons.forum_rounded : Icons.notifications_rounded,
                    color: note.isRead ? Colors.grey : primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              style: TextStyle(
                                fontWeight: note.isRead ? FontWeight.w600 : FontWeight.w900,
                                fontSize: 15,
                                color: note.isRead ? Colors.grey.shade700 : const Color(0xFF1E264D),
                              ),
                            ),
                          ),
                          if (!note.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.body,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(note.createdAt),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onNotificationTap(BuildContext context, NotificationModel note, NotificationProvider provider) async {
    if (!note.isRead) await provider.markAsRead(note.id);
    
    if (note.type == 'doubt' && note.doubtId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('doubts')
            .doc(note.doubtId)
            .get();

        if (doc.exists && context.mounted) {
          final doubt = DoubtModel.fromFirestore(doc);
          Navigator.pushNamed(context, AppRoutes.doubtChat, arguments: doubt);
        }
      } catch (e) {
        debugPrint('Error navigating from inbox tap: $e');
      }
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'இப்போது (Just now)';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'நேற்று (Yesterday)';
    return DateFormat('d MMM, hh:mm a').format(dt);
  }
}
