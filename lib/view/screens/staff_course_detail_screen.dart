import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/uploaded_document.dart';
import 'pdf_viewer_screen.dart';

class StaffCourseDetailScreen extends StatefulWidget {
  final UploadedDocument doc;
  const StaffCourseDetailScreen({super.key, required this.doc});

  @override
  State<StaffCourseDetailScreen> createState() => _StaffCourseDetailScreenState();
}

class _StaffCourseDetailScreenState extends State<StaffCourseDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _trainerController;
  
  // Video Section Controllers
  final TextEditingController _videoTitleController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();
  
  bool _isDemoVideo = true;
  String? _selectedFileName;
  
  bool _showUpdateSection = false;
  bool _showAddVideoSection = false;
  
  bool _isUploadingVideo = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.doc.title);
    _descController = TextEditingController(text: widget.doc.objective);
    _trainerController = TextEditingController(text: widget.doc.trainers);
  }

  Future<void> _onAddVideo() async {
    if (_videoTitleController.text.isEmpty || (_isDemoVideo && _youtubeUrlController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    setState(() => _isUploadingVideo = true);

    try {
      await FirebaseFirestore.instance
          .collection('course_uploads')
          .doc(widget.doc.id)
          .collection('videos')
          .add({
        'title': _videoTitleController.text.trim(),
        'url': _youtubeUrlController.text.trim(),
        'isDemo': _isDemoVideo,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _videoTitleController.clear();
      _youtubeUrlController.clear();
      setState(() {
        _isUploadingVideo = false;
        _showAddVideoSection = false;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("வீடியோ வெற்றிகரமாக சேர்க்கப்பட்டது!")));
    } catch (e) {
      setState(() => _isUploadingVideo = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _trainerController.dispose();
    _videoTitleController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1B5E20);
    
    // Generate Direct Drive Link for Image
    String? displayUrl = widget.doc.imageUrl;
    if (displayUrl != null && displayUrl.contains('/file/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(displayUrl);
      if (match != null) {
        displayUrl = 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
      }
    }

    // Generate Direct Drive Link for PDF
    String? pdfDirectUrl = widget.doc.pdfUrl;
    if (pdfDirectUrl != null && pdfDirectUrl.contains('/file/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(pdfDirectUrl);
      if (match != null) {
        pdfDirectUrl = 'https://drive.google.com/uc?export=download&id=${match.group(1)}';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("பாட மேலாண்மை (Staff)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO IMAGE (Student Style)
            _buildHeroImage(displayUrl),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. COURSE INFO (Student Style)
                  Text(
                    widget.doc.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primaryGreen, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  _buildTrainerBadge(primaryGreen),
                  
                  const SizedBox(height: 24),
                  const Text("பாடத்தின் நோக்கம் (Description)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(widget.doc.objective, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5)),

                  const SizedBox(height: 32),

                  // 3. MANAGEMENT ACTION BUTTONS (The two buttons user requested)
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: "UPDATE\nDETAILS",
                          icon: Icons.edit_note_rounded,
                          color: Colors.blue.shade700,
                          onPressed: () => setState(() {
                            _showUpdateSection = !_showUpdateSection;
                            _showAddVideoSection = false;
                          }),
                          isActive: _showUpdateSection,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionButton(
                          label: "ADD\nVIDEOS",
                          icon: Icons.video_call_rounded,
                          color: primaryGreen,
                          onPressed: () => setState(() {
                            _showAddVideoSection = !_showAddVideoSection;
                            _showUpdateSection = false;
                          }),
                          isActive: _showAddVideoSection,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 4. CONDITIONAL SECTIONS (Update or Add Video)
                  if (_showUpdateSection) 
                    _UpdateCourseCard(
                      titleCtrl: _titleController,
                      descCtrl: _descController,
                      trainerCtrl: _trainerController,
                      onUpdate: () => setState(() => _showUpdateSection = false),
                    ),
                  
                  if (_showAddVideoSection)
                    _AddVideoCard(
                      titleCtrl: _videoTitleController,
                      urlCtrl: _youtubeUrlController,
                      isDemo: _isDemoVideo,
                      isLoading: _isUploadingVideo,
                      onToggle: (val) => setState(() => _isDemoVideo = val),
                      fileName: _selectedFileName,
                      onPickFile: () => setState(() => _selectedFileName = "demo_file.mp4"),
                      onAdd: _onAddVideo,
                    ),

                  const SizedBox(height: 40),

                  // 5. VIDEO LIST (Student Style List)
                  const Text(
                    "COURSE CONTENT",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('course_uploads')
                        .doc(widget.doc.id)
                        .collection('videos')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("வீடியோக்கள் எதுவும் இல்லை", style: TextStyle(color: Colors.grey.shade400)));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final video = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          return _VideoListItem(
                            title: video['title'] ?? 'No Title',
                            isDemo: video['isDemo'] ?? false,
                            onDelete: () => snapshot.data!.docs[index].reference.delete(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(String? url) {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: url != null
          ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)))
          : const Center(child: Icon(Icons.school, size: 50, color: Colors.grey)),
    );
  }

  Widget _buildTrainerBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_pin_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(widget.doc.trainers, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onPressed, bool isActive = false}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? color : color.withOpacity(0.2)),
          boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : color, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: isActive ? Colors.white : color, fontWeight: FontWeight.w900, fontSize: 12, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _UpdateCourseCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController trainerCtrl;
  final VoidCallback onUpdate;

  const _UpdateCourseCard({required this.titleCtrl, required this.descCtrl, required this.trainerCtrl, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("UPDATE COURSE INFO", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.blue)),
          const SizedBox(height: 20),
          _field(titleCtrl, "Title", Icons.title),
          const SizedBox(height: 12),
          _field(descCtrl, "Description", Icons.description, minLines: 3),
          const SizedBox(height: 12),
          _field(trainerCtrl, "Instructor Name", Icons.person, minLines: 1),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onUpdate,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int minLines = 1}) {
    return TextFormField(
      controller: ctrl,
      minLines: minLines,
      maxLines: null, // Allow it to expand as user types
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.blue.shade300),
        filled: true, fillColor: Colors.blue.shade50.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _AddVideoCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController urlCtrl;
  final bool isDemo;
  final bool isLoading;
  final Function(bool) onToggle;
  final String? fileName;
  final VoidCallback onPickFile;
  final VoidCallback onAdd;

  const _AddVideoCard({required this.titleCtrl, required this.urlCtrl, required this.isDemo, required this.isLoading, required this.onToggle, this.fileName, required this.onPickFile, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("UPLOAD NEW CONTENT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1B5E20))),
          const SizedBox(height: 20),
          TextFormField(
            controller: titleCtrl,
            decoration: InputDecoration(labelText: "Video Title", prefixIcon: const Icon(Icons.subtitles)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Make this a Demo Video?", style: TextStyle(fontWeight: FontWeight.bold)),
              Switch(value: isDemo, onChanged: onToggle, activeColor: const Color(0xFF1B5E20)),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          TextFormField(
            controller: urlCtrl,
            decoration: const InputDecoration(labelText: "YouTube URL", prefixIcon: Icon(Icons.link, color: Colors.red)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("UPLOAD VIDEO", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
          ),
        ],
      ),
    );
  }
}

class _VideoListItem extends StatelessWidget {
  final String title;
  final bool isDemo;
  final VoidCallback onDelete;
  const _VideoListItem({required this.title, required this.isDemo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (isDemo ? Colors.blue : Colors.orange).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(isDemo ? Icons.play_arrow_rounded : Icons.lock_rounded, color: isDemo ? Colors.blue : Colors.orange),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(isDemo ? "Free Preview" : "Premium Content", style: TextStyle(fontSize: 11, color: isDemo ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold)),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
        ),
      ),
    );
  }
}
