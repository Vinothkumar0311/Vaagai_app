import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_access_provider.dart';
import '../../core/models/course_video_model.dart';
import '../widgets/course_widgets.dart';
import 'youtube_player_screen.dart';

/// Admin screen to view and approve/reject staff-uploaded course videos.
class AdminVideoApprovalScreen extends StatelessWidget {
  const AdminVideoApprovalScreen({super.key});

  static const Color _primary = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'வீடியோ ஒப்புதல்',
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
              Tab(text: 'APPROVED'),
              Tab(text: 'REJECTED'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _VideoList(statusFilter: 'pending'),
            _VideoList(statusFilter: 'approved'),
            _VideoList(statusFilter: 'rejected'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTERED VIDEO LIST
// ─────────────────────────────────────────────────────────────────────────────

class _VideoList extends StatelessWidget {
  final String statusFilter;
  const _VideoList({required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('course_videos')
          .where('status', isEqualTo: statusFilter)
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
          return _buildEmpty(statusFilter);
        }

        final videos = snapshot.data!.docs
            .map((d) => CourseVideoModel.fromFirestore(d))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: videos.length,
          itemBuilder: (context, i) => _AdminVideoCard(video: videos[i]),
        );
      },
    );
  }

  Widget _buildEmpty(String status) {
    final labels = {
      'pending': 'நிலுவையில் வீடியோக்கள் இல்லை',
      'approved': 'ஒப்புதல் பெற்ற வீடியோக்கள் இல்லை',
      'rejected': 'நிராகரிக்கப்பட்ட வீடியோக்கள் இல்லை',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(labels[status] ?? 'பட்டியல் இல்லை',
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN VIDEO CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AdminVideoCard extends StatelessWidget {
  final CourseVideoModel video;
  static const Color _primary = Color(0xFF1B5E20);

  const _AdminVideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final isPending = video.status == VideoStatus.pending;
    final thumbUrl = video.thumbnailUrl;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with play overlay
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: thumbUrl != null
                      ? Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.play_circle_outline,
                                size: 48, color: Colors.grey),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.play_circle_outline,
                              size: 48, color: Colors.grey),
                        ),
                ),
                // Tap to preview
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => YouTubePlayerScreen(
                                videoUrl: video.youtubeUrl, title: video.title),
                          ),
                        );
                      },
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: StatusChip.fromVideoStatus(video.status),
                ),
                if (video.isDemo)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('FREE PREVIEW',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E264D),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('By ${video.uploadedByName}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(width: 12),
                    Icon(Icons.menu_book_outlined,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        video.courseId, // courseTitle
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(_formatDate(video.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),

                if (video.rejectionReason != null &&
                    video.status == VideoStatus.rejected) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.red.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            video.rejectionReason!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action buttons (only for pending)
                if (isPending) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          label: 'நிராகரி',
                          icon: Icons.close_rounded,
                          color: Colors.red.shade600,
                          filled: false,
                          onTap: () => _handleReject(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionBtn(
                          label: 'ஒப்புதல்',
                          icon: Icons.check_rounded,
                          color: _primary,
                          filled: true,
                          onTap: () => _handleApprove(context),
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

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : color),
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
        title: 'வீடியோ ஒப்புதல்',
        subtitle: 'இந்த வீடியோவை ஒப்புக்கொண்டு மாணவர்களுக்கு காண்பிக்கவுமா?',
        confirmLabel: 'ஒப்புதல்',
        confirmColor: Color(0xFF1B5E20),
      ),
    );
    if (result == null || !context.mounted) return;

    final admin =
        Provider.of<AuthProvider>(context, listen: false).userModel;
    final provider =
        Provider.of<CourseAccessProvider>(context, listen: false);

    final error = await provider.approveVideo(
      videoId: video.id,
      adminId: admin?.uid ?? 'admin',
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            error == null ? const Color(0xFF1B5E20) : Colors.red.shade700,
        content: Text(
          error == null
              ? '✅ வீடியோ ஒப்புக்கொள்ளப்பட்டது! மாணவர்களுக்கு தெரியும்.'
              : '❌ $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handleReject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const ConfirmActionDialog(
        title: 'வீடியோ நிராகரிப்பு',
        subtitle: 'இந்த வீடியோவை நிராகரிக்கவுமா?',
        showReasonField: true,
        confirmLabel: 'நிராகரி',
        confirmColor: Colors.red,
      ),
    );
    if (reason == null || !context.mounted) return;

    final admin =
        Provider.of<AuthProvider>(context, listen: false).userModel;
    final provider =
        Provider.of<CourseAccessProvider>(context, listen: false);

    final error = await provider.rejectVideo(
      videoId: video.id,
      adminId: admin?.uid ?? 'admin',
      reason: reason == 'confirmed' ? null : reason,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            error == null ? Colors.orange.shade700 : Colors.red.shade700,
        content: Text(
          error == null ? '❌ வீடியோ நிராகரிக்கப்பட்டது' : '❌ $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

}
