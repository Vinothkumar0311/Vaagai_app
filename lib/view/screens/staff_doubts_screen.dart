import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:vaagai/core/models/doubt_model.dart';
import 'package:vaagai/providers/auth_provider.dart';
import 'package:vaagai/providers/doubt_provider.dart';
import 'package:vaagai/core/routes/app_routes.dart';

class StaffDoubtsScreen extends StatelessWidget {
  const StaffDoubtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final staffUid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    final doubtProvider = Provider.of<DoubtProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('சந்தேகம் (Doubt Inbox)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<QuerySnapshot?>(
        future: staffUid != null
            ? FirebaseFirestore.instance
                .collection('course_uploads')
                .where('createdBy', isEqualTo: staffUid)
                .get()
            : Future.value(null),
        builder: (context, futureSnapshot) {
          if (futureSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!futureSnapshot.hasData || futureSnapshot.data == null || futureSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("பயிற்றுவிக்கும் பாடங்கள் எதுவும் இல்லை", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final staffCourseIds = futureSnapshot.data!.docs.map((d) => d.id).toList();

          return StreamBuilder<List<DoubtModel>>(
            stream: doubtProvider.getStaffDoubts(staffCourseIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final doubts = snapshot.data ?? [];
              if (doubts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text("சந்தேகம் எதுவும் இல்லை", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: doubts.length,
                itemBuilder: (context, index) {
                  final doubt = doubts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: _buildCourseImage(doubt.courseImage),
                      title: Text(doubt.courseName, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(doubt.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text('Video: ${doubt.videoTitle}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatusBadge(status: doubt.status),
                              Text('At ${_formatTimestamp(doubt.timestampSeconds)}',
                                style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.doubtChat, arguments: doubt);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseImage(String? imageUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: (imageUrl != null && imageUrl.startsWith('http'))
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
              )
            : const Icon(Icons.book, color: Colors.green, size: 30),
      ),
    );
  }

  String _formatTimestamp(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final DoubtStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;
    switch (status) {
      case DoubtStatus.pending: bg = Colors.orange; label = 'Pending'; break;
      case DoubtStatus.replied: bg = Colors.blue; label = 'Replied'; break;
      case DoubtStatus.closed: bg = Colors.green; label = 'Closed'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: bg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
