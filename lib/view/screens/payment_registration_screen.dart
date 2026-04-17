import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/drive_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_access_provider.dart';
import '../../core/models/uploaded_document.dart';
import '../../core/models/course_video_model.dart';
import '../widgets/course_widgets.dart';
import 'youtube_player_screen.dart';

/// Screen shown when a student taps on a locked course.
/// Allows them to view the course details and submit a payment registration.
class PaymentRegistrationScreen extends StatefulWidget {
  final UploadedDocument doc;

  const PaymentRegistrationScreen({super.key, required this.doc});

  @override
  State<PaymentRegistrationScreen> createState() =>
      _PaymentRegistrationScreenState();
}

class _PaymentRegistrationScreenState
    extends State<PaymentRegistrationScreen> {
  static const Color _primary = Color(0xFF1B5E20);
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final provider =
        Provider.of<CourseAccessProvider>(context, listen: false);

    final error = await provider.registerCourseAccess(
      studentId: user.uid,
      studentName: user.name,
      studentEmail: user.email,
      courseId: widget.doc.id,
      courseTitle: widget.doc.title,
      paymentProofUrl: null, // Can integrate Drive upload here
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _primary,
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'பதிவு வெற்றிகரமாக முடிந்தது! நிர்வாகி ஒப்புதலுக்காக காத்திருக்கவும்.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(error, style: const TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'பாட பதிவு',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _primary,
              fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Info Card
              _CourseInfoCard(doc: widget.doc),
              const SizedBox(height: 24),

              // Demo Videos Section
              _DemoVideosSection(courseDocId: widget.doc.id),
              const SizedBox(height: 24),

              // Payment Instructions Card
              _buildPaymentInstructionsCard(),
              const SizedBox(height: 24),

              // Notes field
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'கூடுதல் குறிப்பு (விரும்பினால்)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'கட்டண தகவல் அல்லது கேள்விகள்...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'பதிவு கோரிக்கை அனுப்பு',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.3),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'நிர்வாகி ஒப்புதலுக்கு பிறகு பாடம் திறக்கப்படும்',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B5E20).withOpacity(0.08),
            const Color(0xFF2E7D32).withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _primary, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.payment_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'கட்டண வழிமுறை',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1B5E20)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _instructionRow('1', 'UPI / GPay மூலம் கட்டணம் செலுத்தவும்'),
          _instructionRow('2', 'கட்டண ஸ்க்ரீன்ஷாட்டை எடுத்து வைத்துக் கொள்ளவும்'),
          _instructionRow('3', 'கீழே உள்ள "பதிவு கோரிக்கை" அனுப்பவும்'),
          _instructionRow('4', 'நிர்வாகி ஒப்புதலுக்கு பிறகு பாடம் திறக்கும்'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withOpacity(0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF1B5E20), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'கட்டண விவரங்களுக்கு நிர்வாகியை தொடர்பு கொள்ளவும்',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionRow(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(step,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COURSE INFO CARD (reusable summary card)
// ─────────────────────────────────────────────────────────────────────────────

class _CourseInfoCard extends StatelessWidget {
  final UploadedDocument doc;
  const _CourseInfoCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    String? displayUrl = DriveUtils.getDirectViewUrl(doc.imageUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.indigo.shade50,
              child: displayUrl != null
                  ? Image.network(displayUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.school_rounded,
                                size: 48, color: Color(0xFF1B5E20)),
                          ))
                  : const Center(
                      child: Icon(Icons.school_rounded,
                          size: 48, color: Color(0xFF1B5E20))),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Color(0xFF1B5E20))),
                  const SizedBox(height: 6),
                  Text(doc.objective,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          height: 1.6)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusChip.locked(),
                      if (doc.pdfUrl != null && doc.pdfUrl!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _openUrl(doc.pdfUrl!),
                          icon: const Icon(Icons.picture_as_pdf,
                              size: 18, color: Colors.red),
                          label: const Text(
                            'VIEW SYLLABUS (PDF)',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEMO VIDEOS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _DemoVideosSection extends StatelessWidget {
  final String courseDocId;
  const _DemoVideosSection({required this.courseDocId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CourseAccessProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'மாதிரி வீடியோக்கள் (Demo Videos)',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1B5E20)),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: provider.streamDemoVideos(courseDocId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('மாதிரி வீடியோக்கள் எதுவும் இல்லை',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              );
            }

            final videos = snapshot.data!.docs
                .map((d) => CourseVideoModel.fromFirestore(d))
                .toList();

            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                itemBuilder: (context, i) {
                  final video = videos[i];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    child: VideoThumbnailCard(
                      video: video,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => YouTubePlayerScreen(videoUrl: video.youtubeUrl, title: video.title),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
