import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vaagai/core/constants/app_strings.dart';
import '../../core/utils/drive_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_access_provider.dart';
import '../../core/models/uploaded_document.dart';
import '../../core/models/course_video_model.dart';
import '../../core/models/course_access_model.dart';
import '../widgets/course_widgets.dart';
import 'youtube_player_screen.dart';
import 'pdf_viewer_screen.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../providers/cart_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/youtube_utils.dart';

/// Screen shown when a student taps on a locked course.
/// Allows them to view the course details and submit a payment registration.
class PaymentRegistrationScreen extends StatefulWidget {
  final UploadedDocument doc;

  const PaymentRegistrationScreen({super.key, required this.doc});

  @override
  State<PaymentRegistrationScreen> createState() =>
      _PaymentRegistrationScreenState();
}

class _PaymentRegistrationScreenState extends State<PaymentRegistrationScreen> {
  static const Color _primary = Color(0xFF1B5E20);
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final accessProvider = Provider.of<CourseAccessProvider>(context);
    final accessRecord = user != null ? accessProvider.accessRecordFor(widget.doc.id) : null;
    final isPending = accessRecord?.paymentStatus == PaymentStatus.pending;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          isPending ? AppStrings.statusAppBar : AppStrings.paymentAppBar,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: _primary, fontSize: 18),
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
              if (isPending)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, color: Colors.orange.shade800),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          AppStrings.pendingBanner,
                          style: TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                            fontSize: 13
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
              if (!isPending)
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
                        AppStrings.notesLabel,
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
                          hintText: AppStrings.notesHint,
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

              // Status UI or Submit Button
              if (isPending)
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        AppStrings.requestedStatus,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        AppStrings.adminContactSoon,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    final inCart = cart.isInCart(widget.doc.id);
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (inCart) {
                            Navigator.pushNamed(context, AppRoutes.cart);
                          } else {
                            cart.addToCart(widget.doc);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${widget.doc.title} added to cart"),
                                action: SnackBarAction(label: "VIEW CART", onPressed: () => Navigator.pushNamed(context, AppRoutes.cart)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: inCart ? Colors.blue.shade700 : _primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(inCart ? Icons.shopping_cart_checkout : Icons.add_shopping_cart_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              inCart ? AppStrings.goToCart : AppStrings.addToCart,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.3),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  AppStrings.adminApprovalFooter,
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
                AppStrings.paymentMethodTitle,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1B5E20)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _instructionRow('1', AppStrings.step1),
          _instructionRow('2', AppStrings.step2),
          _instructionRow('3', AppStrings.step3),
          _instructionRow('4', AppStrings.step4),
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
                    AppStrings.contactAdminInfo,
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
                          onPressed: () {
                            final pdfViewUrl =
                                DriveUtils.getDirectViewUrl(doc.pdfUrl);
                            if (pdfViewUrl != null) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PdfViewerScreen(
                                          pdfUrl: pdfViewUrl,
                                          title: doc.pdfName ?? doc.title)));
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf,
                              size: 18, color: Colors.red),
                          label: const Text(
                            AppStrings.viewSyllabusPdf,
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
}

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
          AppStrings.demoVideosTitle,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1B5E20)),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: provider.streamDemoVideos(courseDocId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Text(AppStrings.noDemoVideos,
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              );
            }

            final videos = snapshot.data!.docs
                .map((d) => CourseVideoModel.fromFirestore(d))
                .toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: videos.length,
              itemBuilder: (context, i) {
                final video = videos[i];
                
                String? thumbUrl;
                final videoId = YoutubeUtils.convertUrlToId(video.youtubeUrl);
                if (videoId != null) {
                  thumbUrl = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 100,
                          height: 60,
                          color: Colors.grey.shade100,
                          child: thumbUrl != null
                              ? Image.network(
                                  thumbUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.grey),
                                )
                              : const Icon(Icons.play_circle_fill,
                                  color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4)),
                              child: const Text("DEMO",
                                  style: TextStyle(
                                      color: Color(0xFF1976D2),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => YouTubePlayerScreen(
                                  videoUrl: video.youtubeUrl, title: video.title),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(AppStrings.watchButtonText,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
