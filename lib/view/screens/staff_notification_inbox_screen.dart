import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vaagai/core/models/notification_model.dart';
import 'package:vaagai/core/models/doubt_model.dart';
import 'package:vaagai/core/routes/app_routes.dart';
import 'package:vaagai/providers/auth_provider.dart';
import 'package:vaagai/providers/notification_provider.dart';

class StaffNotificationInboxScreen extends StatelessWidget {
  const StaffNotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).userModel?.uid ?? '';
    final notifProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'அறிவிப்புகள்',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => notifProvider.markAllAsRead(userId),
            icon: const Icon(Icons.done_all, color: Colors.white70, size: 18),
            label: const Text(
              'எல்லாம் படித்தது',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notifProvider.notificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B5E20),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationCard(
                notification: n,
                onTap: () => _onNotificationTap(context, n, notifProvider),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 50,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'அறிவிப்புகள் எதுவும் இல்லை',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'புதிய சந்தேகங்கள் வரும்போது இங்கே தெரியும்',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _onNotificationTap(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    // Mark as read (no-op if already read)
    if (!notification.isRead) {
      await provider.markAsRead(notification.id);
    }

    // Navigate to doubt thread if applicable
    if (notification.type == 'doubt' && notification.doubtId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('doubts')
            .doc(notification.doubtId)
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
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4))
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isUnread
                      ? const Color(0xFF1B5E20).withOpacity(0.12)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.type == 'doubt'
                      ? Icons.help_outline_rounded
                      : Icons.notifications_rounded,
                  color: isUnread ? const Color(0xFF1B5E20) : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: isUnread
                                  ? const Color(0xFF1B5E20)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'இப்போது';
    if (diff.inMinutes < 60) return '${diff.inMinutes} நிமிடம் முன்பு';
    if (diff.inHours < 24) return '${diff.inHours} மணி முன்பு';
    if (diff.inDays == 1) return 'நேற்று';
    return DateFormat('d MMM, hh:mm a').format(dt);
  }
}
