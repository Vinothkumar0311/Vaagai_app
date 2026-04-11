import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/uploaded_document.dart';
import 'pdf_viewer_screen.dart';

import 'youtube_player_screen.dart';

class CourseContentDetailScreen extends StatelessWidget {
  final UploadedDocument doc;
  const CourseContentDetailScreen({super.key, required this.doc});

  void _handleVideoTap(BuildContext context, String title, String url, bool isDemo) {
    // Navigating directly to player for all content as per request
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubePlayerScreen(videoUrl: url, title: title),
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
    
    String? displayUrl = doc.imageUrl;
    if (displayUrl != null && displayUrl.contains('/file/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(displayUrl);
      if (match != null) {
        displayUrl = 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
      }
    }

    String? pdfDirectUrl = doc.pdfUrl;
    if (pdfDirectUrl != null && pdfDirectUrl.contains('/file/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(pdfDirectUrl);
      if (match != null) {
        pdfDirectUrl = 'https://drive.google.com/uc?export=download&id=${match.group(1)}';
      }
    }

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
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin_rounded, size: 16, color: primaryGreen),
                        const SizedBox(width: 8),
                        Flexible(child: Text(doc.trainers, style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 14))),
                      ],
                    ),
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
                        .collection('course_uploads')
                        .doc(doc.id)
                        .collection('videos')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey),
                              SizedBox(width: 12),
                              Text("வீடியோக்கள் இன்னும் சேர்க்கப்படவில்லை", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final video = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          final String title = video['title'] ?? 'Chapter ${index + 1}';
                          final bool isDemo = video['isDemo'] ?? false;
                          final String url = video['url'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: (isDemo ? Colors.blue : Colors.orange).withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(isDemo ? Icons.play_arrow_rounded : Icons.lock_rounded, color: isDemo ? Colors.blue : Colors.orange),
                              ),
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(isDemo ? "Free Preview" : "Premium Content", style: TextStyle(fontSize: 11, color: isDemo ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold)),
                              trailing: ElevatedButton(
                                onPressed: () => _handleVideoTap(context, title, url, isDemo),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDemo ? Colors.blue : Colors.orange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("WATCH", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
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
