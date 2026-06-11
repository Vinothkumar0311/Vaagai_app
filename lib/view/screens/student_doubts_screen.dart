import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaagai/core/models/doubt_model.dart';
import 'package:vaagai/providers/auth_provider.dart';
import 'package:vaagai/providers/doubt_provider.dart';
import 'package:vaagai/core/routes/app_routes.dart';
import '../widgets/safe_network_image.dart';

class StudentDoubtsScreen extends StatelessWidget {
  const StudentDoubtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentId = authProvider.userModel?.uid;
    final doubtProvider = Provider.of<DoubtProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('எனது சந்தேகங்கள் (My Doubts)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: studentId == null 
        ? const Center(child: Text("Please login to see doubts")) 
        : StreamBuilder<List<DoubtModel>>(
            stream: doubtProvider.getStudentDoubts(studentId),
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
                      const Text("சந்தேகங்கள் எதுவும் இல்லை", style: TextStyle(color: Colors.grey)),
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
                          Text(doubt.videoTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatusBadge(status: doubt.status),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(_formatTimestamp(doubt.timestampSeconds),
                                    style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
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
          ),
    );
  }

  Widget _buildCourseImage(String? imageUrl) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: (imageUrl != null && imageUrl.startsWith('http'))
            ? SafeNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.book, color: Colors.green, size: 24),
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
    Color color = status == DoubtStatus.replied ? Colors.green : Colors.orange;
    String label = status == DoubtStatus.replied ? 'Replied' : 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
