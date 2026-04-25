import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/uploaded_document.dart';
import '../../core/utils/drive_utils.dart';
import 'pdf_viewer_screen.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'youtube_player_screen.dart';

class CourseContentDetailScreen extends StatelessWidget {
  final UploadedDocument doc;
  const CourseContentDetailScreen({super.key, required this.doc});

  void _handleVideoTap(BuildContext context, String title, String url, bool isDemo, String videoDocId) {
    // Navigating directly to player for all content as per request
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
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            Text(
              "PREMIUM CONTENT",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade700, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contacting Support for Payment...")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("UNLOCK NOW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
        title: const Text("பாட விவரங்கள்", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  ? Image.network(
                      displayUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.school_rounded, size: 80, color: Colors.grey)),
                    )
                  : const Center(child: Icon(Icons.school_rounded, size: 80, color: Colors.grey)),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primaryGreen, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  
                  const Text(
                    "பயிற்றுநர் விவரம்",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doc.trainers.replaceAll('\n', ', '),
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  const Text("பாடத்தின் நோக்கம்", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Text(doc.objective, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.6, fontWeight: FontWeight.w500)),

                  const SizedBox(height: 40),

                  const Text("பாட வீடியோக்கள் (Videos)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 16),
                  
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('course_videos')
                        .where('courseDocId', isEqualTo: doc.id)
                        .where('status', isEqualTo: 'approved')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          final String title = data['title'] ?? 'Chapter ${index + 1}';
                          final bool isDemo = data['isDemo'] ?? false;
                          final String url = data['youtubeUrl'] ?? '';
                          
                          // Extract Thumbnail
                          String? thumbUrl;
                          final uri = Uri.tryParse(url);
                          if (uri != null) {
                            String? videoId = YoutubePlayerController.convertUrlToId(url);
                            if (videoId != null) {
                              thumbUrl = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 100,
                                    height: 60,
                                    color: Colors.grey.shade100,
                                    child: thumbUrl != null 
                                      ? Image.network(thumbUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.play_circle_fill, color: Colors.grey))
                                      : const Icon(Icons.play_circle_fill, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Title and demo tag
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isDemo)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                          child: Text("DEMO", style: TextStyle(color: Colors.blue.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // WATCH Button
                                ElevatedButton(
                                  onPressed: () => _handleVideoTap(context, title, url, isDemo, snapshot.data!.docs[index].id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text("WATCH", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),


                  const SizedBox(height: 40),

                  if (doc.pdfUrl != null) ...[
                    const Text("பாடப் பொருட்கள் (Materials)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PdfViewerScreen(pdfUrl: pdfDirectUrl!, title: doc.pdfName ?? doc.title)));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.shade100)),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28)),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doc.pdfName ?? "பாடக் குறிப்பேடு (PDF)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFB71C1C))),
                                  const Text("View document natively in-app", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.red, size: 18),
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
}
