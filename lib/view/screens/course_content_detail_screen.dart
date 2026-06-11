import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/uploaded_document.dart';
import '../../core/utils/drive_utils.dart';
import 'pdf_viewer_screen.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'youtube_player_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/progress_provider.dart';
import '../../core/utils/youtube_utils.dart';
import '../widgets/safe_network_image.dart';

class CourseContentDetailScreen extends StatelessWidget {
  final UploadedDocument doc;
  final String? lastVideoId;
  final int? lastTimestamp;

  const CourseContentDetailScreen({
    super.key,
    required this.doc,
    this.lastVideoId,
    this.lastTimestamp,
  });

  Future<void> _handleVideoTap(BuildContext context, String title, String url,
      bool isDemo, String videoDocId, int totalVideos) async {
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);

    // Hybrid Resume Flow: Use reactive Provider state as source of truth
    final progress = progressProvider.myProgress[doc.id];
    final localProgress = await progressProvider.getLocalProgress(doc.id);

    int? seekToSeconds;

    // Primary: Check if this is the video the user was last watching (from Firestore)
    if (progress != null && progress.lastVideoId == videoDocId) {
      seekToSeconds = progress.lastTimestamp;
    }

    // Secondary: Check local cache (usually more recent)
    if (localProgress != null && localProgress['videoId'] == videoDocId) {
      seekToSeconds = localProgress['timestamp'];
    }

    // UX Upgrade: Substract 3 seconds for context (if > 3s)
    if (seekToSeconds != null && seekToSeconds > 3) {
      seekToSeconds = seekToSeconds - 3;
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubePlayerScreen(
          videoUrl: url,
          title: title,
          courseId: doc.id,
          courseName: doc.title,
          courseImage: DriveUtils.getDirectViewUrl(doc.imageUrl),
          videoDocId: videoDocId,
          totalVideosInCourse: totalVideos,
          startAt: seekToSeconds,
        ),
      ),
    );
  }

  void _showPremiumPaymentModal(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded,
                  size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            Text(
              "PREMIUM CONTENT",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 12),
            const Text(
              "இந்த பாடத்தைப் பார்க்க பிரீமியம் மெம்பர்ஷிப் தேவை. எங்களை தொடர்பு கொள்ளவும்.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Contacting Support for Payment...")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("UNLOCK NOW",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1B5E20);

    String? displayUrl = DriveUtils.getDirectViewUrl(doc.imageUrl);
    String? pdfDirectUrl = DriveUtils.getDirectDownloadUrl(doc.pdfUrl);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("பாட விவரங்கள்",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: displayUrl != null
                  ? SafeNetworkImage(
                      imageUrl: displayUrl,
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Icon(Icons.school_rounded,
                          size: 80, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: primaryGreen,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "பயிற்றுநர் விவரம்",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doc.trainers.replaceAll('\n', ', '),
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.6,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 32),
                  const Text("பாடத்தின் நோக்கம்",
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  Text(doc.objective,
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.6,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 40),
                  const SizedBox(height: 40),
                  Consumer<ProgressProvider>(
                    builder: (context, progressProvider, _) {
                      final progress = progressProvider.myProgress[doc.id];
                      final completedVideos = progress?.completedVideos ?? [];

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('course_videos')
                            .where('courseDocId', isEqualTo: doc.id)
                            .where('status', isEqualTo: 'approved')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.grey),
                                  SizedBox(width: 12),
                                  Text("வீடியோக்கள் இன்னும் சேர்க்கப்படவில்லை",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }

                          // Sort in-memory (chronological: oldest first = 1, 2, 3...)
                          final docs = snapshot.data!.docs.toList();
                          docs.sort((a, b) {
                            final aTime =
                                (a.data() as Map<String, dynamic>)['createdAt']
                                    as Timestamp?;
                            final bTime =
                                (b.data() as Map<String, dynamic>)['createdAt']
                                    as Timestamp?;
                            return (aTime ?? Timestamp(0, 0))
                                .compareTo(bTime ?? Timestamp(0, 0));
                          });

                          // Determine the "Current/Next" video to watch
                          int nextIndex = 0;
                          if (progress != null) {
                            if (progress.lastVideoId != null) {
                              nextIndex = docs.indexWhere(
                                  (d) => d.id == progress.lastVideoId);
                              if (nextIndex == -1) nextIndex = 0;
                            } else {
                              // Find first uncompleted
                              nextIndex = docs.indexWhere(
                                  (d) => !completedVideos.contains(d.id));
                              if (nextIndex == -1) nextIndex = 0;
                            }
                          }
                          final nextVideoDoc = docs[nextIndex];
                          final nextData =
                              nextVideoDoc.data() as Map<String, dynamic>;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Resume Card
                              _buildResumeCard(
                                context,
                                title: nextData['title'] ??
                                    'Chapter ${nextIndex + 1}',
                                url: nextData['youtubeUrl'] ?? '',
                                videoDocId: nextVideoDoc.id,
                                totalVideos: docs.length,
                                isCompleted:
                                    completedVideos.contains(nextVideoDoc.id),
                              ),
                              const SizedBox(height: 32),
                              const Text("பாட வீடியோக்கள் (Videos)",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: Colors.black87)),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final videoDoc = docs[index];
                                  final data =
                                      videoDoc.data() as Map<String, dynamic>;
                                  final String title =
                                      data['title'] ?? 'Chapter ${index + 1}';
                                  final bool isDemo = data['isDemo'] ?? false;
                                  final String url = data['youtubeUrl'] ?? '';
                                  final bool isActive = index == nextIndex;

                                  // Extract Thumbnail
                                  String? thumbUrl;
                                  final videoId = YoutubeUtils.convertUrlToId(url);
                                  if (videoId != null) {
                                    thumbUrl =
                                        'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: Colors.grey.shade100),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4))
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Thumbnail
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            width: 100,
                                            height: 60,
                                            color: Colors.grey.shade100,
                                            child: thumbUrl != null
                                                ? SafeNetworkImage(
                                                    imageUrl: thumbUrl,
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Icon(
                                                    Icons.play_circle_fill,
                                                    color: Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Title and demo tag
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                          color: isActive
                                                              ? const Color(
                                                                  0xFF1B5E20)
                                                              : Colors.black87),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isActive &&
                                                      !completedVideos.contains(
                                                          videoDoc.id))
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 8),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF1B5E20)
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: const Text("NEXT",
                                                          style: TextStyle(
                                                              color: Color(
                                                                  0xFF1B5E20),
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ),
                                                  if (completedVideos.contains(
                                                      docs[index].id)) // ✅ sorted
                                                    const Icon(
                                                        Icons.check_circle,
                                                        color: Colors.green,
                                                        size: 16),
                                                ],
                                              ),
                                              if (isDemo)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 4),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color:
                                                          Colors.blue.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4)),
                                                  child: Text("DEMO",
                                                      style: TextStyle(
                                                          color: Colors
                                                              .blue.shade700,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // WATCH Button
                                        ElevatedButton(
                                          onPressed: () => _handleVideoTap(
                                              context,
                                              title,
                                              url,
                                              isDemo,
                                              docs[index].id,
                                              docs.length),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1B5E20),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                          child: const Text("WATCH",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  if (doc.pdfUrl != null) ...[
                    const Text("பாடப் பொருட்கள் (Materials)",
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.black87)),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(
                                    pdfUrl: pdfDirectUrl!,
                                    title: doc.pdfName ?? doc.title)));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade100)),
                        child: Row(
                          children: [
                            Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.picture_as_pdf_rounded,
                                    color: Colors.red, size: 28)),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doc.pdfName ?? "பாடக் குறிப்பேடு (PDF)",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFFB71C1C))),
                                  const Text("View document natively in-app",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.red, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeCard(BuildContext context,
      {required String title,
      required String url,
      required String videoDocId,
      required int totalVideos,
      required bool isCompleted}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "தொடரவும் (CONTINUE)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.play_circle_outline,
                  color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _handleVideoTap(
                  context, title, url, false, videoDocId, totalVideos),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                "பாடத்தைத் தொடங்கவும் (START LESSON)",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
