import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/utils/drive_utils.dart';
import '../../core/models/uploaded_document.dart';
import '../../core/models/course_video_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_access_provider.dart';
import '../widgets/course_widgets.dart';
import '../widgets/course_analytics_card.dart';
import 'youtube_player_screen.dart';
import 'pdf_viewer_screen.dart';
import '../widgets/safe_network_image.dart';


class StaffCourseDetailScreen extends StatefulWidget {
  final UploadedDocument doc;
  const StaffCourseDetailScreen({super.key, required this.doc});

  @override
  State<StaffCourseDetailScreen> createState() => _StaffCourseDetailScreenState();
}

class _StaffCourseDetailScreenState extends State<StaffCourseDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late List<TextEditingController> _trainerControllers;
  
  // Video Section Controllers
  final TextEditingController _videoTitleController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();
  
  bool _isDemoVideo = true;
  String? _selectedFileName;
  
  bool _showUpdateSection = false;
  bool _showAddVideoSection = false;
  bool _showAnalyticsSection = false;
  
  bool _isUploadingVideo = false;

  // Weekly upload tracking
  int _weeklyUploadCount = 0;
  static const int _maxWeeklyUploads = 4;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.doc.title);
    _descController = TextEditingController(text: widget.doc.objective);
    
    // Parse trainers string into a list of controllers using newline as separator
    final trainersList = widget.doc.trainers.split('\n').where((s) => s.trim().isNotEmpty).toList();
    if (trainersList.isEmpty) {
      _trainerControllers = [TextEditingController()];
    } else {
      _trainerControllers = trainersList.map((t) => TextEditingController(text: t.trim())).toList();
    }

    // Load weekly upload count
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshWeeklyCount());
  }

  Future<void> _refreshWeeklyCount() async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;
    final provider = Provider.of<CourseAccessProvider>(context, listen: false);
    final count = await provider.getWeeklyUploadCount(widget.doc.id, user.uid);
    if (mounted) setState(() => _weeklyUploadCount = count);
  }

  void _addTrainerField() {
    setState(() {
      _trainerControllers.add(TextEditingController());
    });
  }

  void _removeTrainerField(int index) {
    if (_trainerControllers.length > 1) {
      setState(() {
        final ctrl = _trainerControllers.removeAt(index);
        ctrl.dispose();
      });
    }
  }

  Future<void> _onUpdateDetails() async {
    final trainers = _trainerControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n');

    try {
      await FirebaseFirestore.instance
          .collection('course_uploads')
          .doc(widget.doc.id)
          .update({
        'title': _titleController.text.trim(),
        'objective': _descController.text.trim(),
        'trainers': trainers,
      });
      
      if (mounted) {
        setState(() => _showUpdateSection = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("விவரங்கள் புதுப்பிக்கப்பட்டன!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _onAddVideo() async {
    if (_videoTitleController.text.isEmpty || _youtubeUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("தலைப்பு மற்றும் YouTube URL தேவை")));
      return;
    }

    if (_weeklyUploadCount >= _maxWeeklyUploads) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('இந்த வாரம் 4 வீடியோக்கள் பதிவேற்றம் முடிந்தது!'),
        ),
      );
      return;
    }

    setState(() => _isUploadingVideo = true);

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final provider = Provider.of<CourseAccessProvider>(context, listen: false);

    final error = await provider.submitVideo(
      courseDocId: widget.doc.id,
      courseTitle: widget.doc.title,
      staffId: user?.uid ?? '',
      staffName: user?.name ?? 'Staff',
      title: _videoTitleController.text.trim(),
      youtubeUrl: _youtubeUrlController.text.trim(),
      isDemo: _isDemoVideo,
    );

    if (!mounted) return;
    setState(() => _isUploadingVideo = false);

    if (error == null) {
      _videoTitleController.clear();
      _youtubeUrlController.clear();
      setState(() => _showAddVideoSection = false);
      await _refreshWeeklyCount();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1B5E20),
          content: Text('✅ வீடியோ சமர்ப்பிக்கப்பட்டது! நிர்வாகி ஒப்புதலுக்காக காத்திருக்கும்.',
              style: TextStyle(color: Colors.white)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(error,
              style: const TextStyle(color: Colors.white))));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (var ctrl in _trainerControllers) {
      ctrl.dispose();
    }
    _videoTitleController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1B5E20);
    
    // Generate Direct Drive Link for Image
    String? displayUrl = DriveUtils.getDirectViewUrl(widget.doc.imageUrl);

    // Generate Direct Drive Link for PDF
    String? pdfDirectUrl = DriveUtils.getDirectDownloadUrl(widget.doc.pdfUrl);

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.doc.title,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primaryGreen, letterSpacing: -0.5),
                        ),
                      ),
                      if (pdfDirectUrl != null && pdfDirectUrl.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(
                                  pdfUrl: pdfDirectUrl,
                                  title: "${widget.doc.title} - Syllabus",
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                          label: const Text("SYLLABUS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Instructors List Section (Matching Image 2)
                  const Text(
                    "பயிற்றுநர் விவரம்",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  // Instructors Paragraph Style (Matching User's "Looks like paragraph" request)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      widget.doc.trainers.replaceAll('\n', ', '),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  const Text("பாடத்தின் நோக்கம் (வகுப்பின் நோக்கம்)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(widget.doc.objective, style: TextStyle(fontSize: 16, color: Colors.grey.shade800, height: 1.6)),

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
                            _showAnalyticsSection = false;
                          }),
                          isActive: _showUpdateSection,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: "ADD\nVIDEOS",
                          icon: Icons.video_call_rounded,
                          color: primaryGreen,
                          onPressed: () => setState(() {
                            _showAddVideoSection = !_showAddVideoSection;
                            _showUpdateSection = false;
                            _showAnalyticsSection = false;
                          }),
                          isActive: _showAddVideoSection,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          label: "VIEW\nANALYTICS",
                          icon: Icons.analytics_rounded,
                          color: Colors.orange.shade800,
                          onPressed: () => setState(() {
                            _showAnalyticsSection = !_showAnalyticsSection;
                            _showUpdateSection = false;
                            _showAddVideoSection = false;
                          }),
                          isActive: _showAnalyticsSection,
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
                      trainerControllers: _trainerControllers,
                      onAddTrainer: _addTrainerField,
                      onRemoveTrainer: _removeTrainerField,
                      onUpdate: _onUpdateDetails,
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
                      weeklyUploadsUsed: _weeklyUploadCount,
                      maxUploads: _maxWeeklyUploads,
                    ),
                  
                  if (_showAnalyticsSection)
                    CourseAnalyticsCard(courseId: widget.doc.id),

                  const SizedBox(height: 40),

                  // 5. VIDEO LIST (Student Style List)
                  const Text(
                    "COURSE CONTENT",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('course_videos')
                        .where('courseDocId', isEqualTo: widget.doc.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text("வீடியோக்கள் எதுவும் இல்லை",
                            style: TextStyle(color: Colors.grey.shade400)));
                      }

                      final videos = snapshot.data!.docs
                          .map((d) => CourseVideoModel.fromFirestore(d))
                          .toList();

                      // Sort in-memory to avoid index requirement
                      videos.sort((a, b) => (b.createdAt ?? DateTime(0))
                          .compareTo(a.createdAt ?? DateTime(0)));

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          return _StaffVideoListItem(
                            video: video,
                            onDelete: () async {
                              // Find original doc for deletion
                              final doc = snapshot.data!.docs.firstWhere(
                                  (d) => d.id == video.id);
                              await doc.reference.delete();
                            },
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
          ? SafeNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
            )
          : const Center(
              child: Icon(Icons.school, size: 50, color: Colors.grey)),
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
  final List<TextEditingController> trainerControllers;
  final VoidCallback onAddTrainer;
  final Function(int) onRemoveTrainer;
  final VoidCallback onUpdate;

  const _UpdateCourseCard({
    required this.titleCtrl, 
    required this.descCtrl, 
    required this.trainerControllers, 
    required this.onAddTrainer,
    required this.onRemoveTrainer,
    required this.onUpdate
  });

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
          _field(descCtrl, "Description (வகுப்பின் நோக்கம்)", Icons.description, minLines: 4),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("பயிற்றுநர் விவரம் (INSTRUCTORS)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              TextButton.icon(onPressed: onAddTrainer, icon: const Icon(Icons.add, size: 16), label: const Text("Add Staff")),
            ],
          ),
          ...List.generate(trainerControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(child: _field(trainerControllers[index], "Staff ${index + 1}", Icons.person)),
                  if (trainerControllers.length > 1)
                    IconButton(onPressed: () => onRemoveTrainer(index), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
                ],
              ),
            );
          }),
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
  final int weeklyUploadsUsed;
  final int maxUploads;

  const _AddVideoCard({
    required this.titleCtrl,
    required this.urlCtrl,
    required this.isDemo,
    required this.isLoading,
    required this.onToggle,
    this.fileName,
    required this.onPickFile,
    required this.onAdd,
    this.weeklyUploadsUsed = 0,
    this.maxUploads = 4,
  });

  @override
  Widget build(BuildContext context) {
    final limitReached = weeklyUploadsUsed >= maxUploads;
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
          const SizedBox(height: 16),
          // Weekly upload counter banner
          WeeklyUploadBanner(used: weeklyUploadsUsed, total: maxUploads),
          const SizedBox(height: 16),
          if (!limitReached) ...
            [
              TextFormField(
                controller: titleCtrl,
                decoration: InputDecoration(
                    labelText: "Video Title",
                    prefixIcon: const Icon(Icons.subtitles)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Free Preview Video?",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Switch(
                      value: isDemo,
                      onChanged: onToggle,
                      activeColor: const Color(0xFF1B5E20)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                    labelText: "YouTube URL",
                    prefixIcon: Icon(Icons.link, color: Colors.red),
                    hintText: 'https://youtube.com/watch?v=...'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text("SUBMIT FOR APPROVAL",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                      ),
              ),
            ],
        ],
      ),
    );
  }
}

/// Replaces _VideoListItem — shows CourseVideoModel with status chip
class _StaffVideoListItem extends StatelessWidget {
  final CourseVideoModel video;
  final VoidCallback onDelete;
  const _StaffVideoListItem({required this.video, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (video.status) {
      case VideoStatus.approved:
        statusColor = const Color(0xFF2E7D32);
        statusIcon = Icons.check_circle_rounded;
        break;
      case VideoStatus.rejected:
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.pending_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (video.isDemo ? Colors.blue : Colors.orange).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            video.isDemo ? Icons.play_arrow_rounded : Icons.lock_rounded,
            color: video.isDemo ? Colors.blue : Colors.orange,
          ),
        ),
        title: Text(video.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    video.status.name.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold),
                  ),
                  if (video.isDemo) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('FREE',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ],
              ),
              if (video.status == VideoStatus.rejected &&
                  video.rejectionReason != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 12, color: Colors.red.shade600),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              video.rejectionReason!,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _handleResubmit(context),
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('மீண்டும் சமர்ப்பி (Resubmit)',
                              style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YouTubePlayerScreen(videoUrl: video.youtubeUrl, title: video.title),
            ),
          );
        },
        trailing: video.status == VideoStatus.pending
            ? IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
              )
            : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }

  Future<void> _handleResubmit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('மீண்டும் சமர்ப்பிக்கவா?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'இந்த வீடியோவை மீண்டும் நிர்வாகியின் அனுமதிக்காக அனுப்ப வேண்டுமா?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('இல்லை', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('ஆம், அனுப்பு'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<CourseAccessProvider>(context, listen: false);
      final error = await provider.resetVideo(
        videoId: video.id,
        adminId: 'staff-reset',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? '✅ வீடியோ மீண்டும் சமர்ப்பிக்கப்பட்டது!'),
            backgroundColor: error == null ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}


