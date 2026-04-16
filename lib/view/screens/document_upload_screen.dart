import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/drive_upload_service.dart';
import 'staff_course_detail_screen.dart';
import '../../core/models/uploaded_document.dart';

// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// List Screen
// ─────────────────────────────────────────────────────────────────────────────
class DocumentUploadScreen extends StatelessWidget {
  const DocumentUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Course Management",
          style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 20, color: primaryGreen),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: primaryGreen),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('course_uploads')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: primaryGreen));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final docs = snapshot.data!.docs
                .map((d) => UploadedDocument.fromFirestore(d))
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) =>
                  _DocumentCard(doc: docs[index], primaryGreen: primaryGreen),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        backgroundColor: primaryGreen,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text(
          "CREATE COURSE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UploadFormModal(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No course materials yet.",
            style: TextStyle(
                color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document Card - Re-designed to match the AI Engineer Reference exactly
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentCard extends StatelessWidget {
  final UploadedDocument doc;
  final Color primaryGreen;

  const _DocumentCard({required this.doc, required this.primaryGreen});

  @override
  Widget build(BuildContext context) {
    // Generate Direct Drive Link for Image
    String? displayUrl = doc.imageUrl;
    if (displayUrl != null && displayUrl.contains('/file/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(displayUrl);
      if (match != null) {
        displayUrl =
            'https://drive.google.com/uc?export=view&id=${match.group(1)}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image with Brand Overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 190,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: displayUrl != null
                      ? Image.network(
                          displayUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image,
                                  size: 50, color: Colors.grey)),
                        )
                      : const Center(
                          child:
                              Icon(Icons.school, size: 50, color: Colors.grey)),
                ),
              ),
              // Brand Strip (Translucent like reference)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.4)
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF1A1F3D), // Deep Navy from reference
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            doc.trainers.split('\n').length > 1 
                                ? "${doc.trainers.split('\n').first.split(',').first.trim()} & others"
                                : doc.trainers.split('\n').first.split(',').first.trim(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Color(0xFF1E264D), // Dark Indigo depth
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  doc.objective,
                  style: const TextStyle(
                    color: Color(0xFF424B7A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (doc.imageName != null)
                          _fileTag(Icons.image_rounded, Colors.blue),
                        if (doc.imageName != null && doc.pdfName != null)
                          const SizedBox(width: 8),
                        if (doc.pdfName != null)
                          _fileTag(Icons.picture_as_pdf_rounded, Colors.red),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StaffCourseDetailScreen(doc: doc),
                          )
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text("ACCESS COURSE",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileTag(IconData icon, Color col) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: col, size: 18),
    );
  }

  void _openUrl(BuildContext context, String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Launch Material"),
        content: const Text(
            "Would you like to open this course material in your browser?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              Navigator.pop(context);
            },
            child: const Text("OPEN"),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Modal
// ─────────────────────────────────────────────────────────────────────────────
class UploadFormModal extends StatefulWidget {
  const UploadFormModal({super.key});

  @override
  State<UploadFormModal> createState() => _UploadFormModalState();
}

class _UploadFormModalState extends State<UploadFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _degreeController = TextEditingController();
  final _objectiveController = TextEditingController();
  final List<TextEditingController> _trainerControllers = [TextEditingController()];

  Uint8List? _imageBytes;
  String? _imageName;
  Uint8List? _pdfBytes;
  String? _pdfName;

  bool _isUploading = false;

  @override
  void dispose() {
    _degreeController.dispose();
    _objectiveController.dispose();
    for (var controller in _trainerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTrainer() {
    setState(() {
      _trainerControllers.add(TextEditingController());
    });
  }

  void _removeTrainer(int index) {
    if (_trainerControllers.length > 1) {
      setState(() {
        final controller = _trainerControllers.removeAt(index);
        controller.dispose();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = xFile.name;
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pdfBytes = result.files.single.bytes;
        _pdfName = result.files.single.name;
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null && _pdfBytes == null) {
      _showSnack("Please select Image or PDF", Colors.red);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl;
      String? pdfUrl;

      if (_imageBytes != null) {
        imageUrl = await DriveUploadService.uploadFile(
          bytes: _imageBytes!,
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$_imageName',
          mimeType: DriveUploadService.mimeTypeFrom(_imageName!),
        );
      }

      if (_pdfBytes != null) {
        pdfUrl = await DriveUploadService.uploadFile(
          bytes: _pdfBytes!,
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$_pdfName',
          mimeType: DriveUploadService.mimeTypeFrom(_pdfName!),
        );
      }

      final trainers = _trainerControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .join('\n');

      await FirebaseFirestore.instance.collection('course_uploads').add({
        'title': _degreeController.text.trim(),
        'objective': _objectiveController.text.trim(),
        'trainers': trainers,
        'imageUrl': imageUrl,
        'pdfUrl': pdfUrl,
        'imageName': _imageName,
        'pdfName': _pdfName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showSnack('Upload failed: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: EdgeInsets.only(
          top: 12,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 30),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.only(bottom: 24))),
              const Text("Publish New Course",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B5E20))),
              const SizedBox(height: 24),
              _styledInput(_degreeController, "Course Title",
                  Icons.auto_stories_rounded),
              const SizedBox(height: 16),
              _styledInput(_objectiveController, "Course Objective (வகுப்பின் நோக்கம்)",
                  Icons.lightbulb_outline_rounded,
                  maxLines: 4),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "பயிற்றுநர் விவரம் (Instructors)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addTrainer,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add Staff"),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1B5E20),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_trainerControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _styledInput(
                          _trainerControllers[index],
                          "Instructor Name & Details ${index + 1}",
                          Icons.person_outline_rounded,
                        ),
                      ),
                      if (_trainerControllers.length > 1)
                        IconButton(
                          onPressed: () => _removeTrainer(index),
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  _fileBox("Thumbnail", _imageName, Colors.blue, _pickImage),
                  const SizedBox(width: 12),
                  _fileBox("Syllabus", _pdfName, Colors.red, _pickPdf),
                ],
              ),
              const SizedBox(height: 32),
              if (_isUploading)
                const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
              else
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: _upload,
                    child: const Text("PUBLISH COURSE",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styledInput(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1B5E20), size: 22),
        labelText: hint,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }

  Widget _fileBox(String label, String? name, Color col, VoidCallback tap) {
    return Expanded(
      child: InkWell(
        onTap: tap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
              color: col.withOpacity(0.05),
              border: Border.all(color: col.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(15)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  name != null
                      ? Icons.check_circle_rounded
                      : Icons.file_upload_outlined,
                  color: col,
                  size: 28),
              const SizedBox(height: 6),
              Text(name ?? label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: col)),
            ],
          ),
        ),
      ),
    );
  }
}
