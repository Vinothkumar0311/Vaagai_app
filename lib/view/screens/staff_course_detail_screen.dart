import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/utils/drive_utils.dart';
import '../../core/models/uploaded_document.dart';
import '../../core/models/course_video_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_access_provider.dart';
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
  
  // Scheduling state for adding videos
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;
  
  bool _showUpdateSection = false;
  bool _showAddVideoSection = false;
  bool _showAnalyticsSection = false;
  
  bool _isUploadingVideo = false;

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

    setState(() => _isUploadingVideo = true);

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final provider = Provider.of<CourseAccessProvider>(context, listen: false);

    final targetSchedule = _isScheduled ? _scheduledDateTime : null;
    final wasScheduled = targetSchedule != null && targetSchedule.isAfter(DateTime.now());

    final error = await provider.submitVideo(
      courseDocId: widget.doc.id,
      courseTitle: widget.doc.title,
      staffId: user?.uid ?? '',
      staffName: user?.name ?? 'Staff',
      title: _videoTitleController.text.trim(),
      youtubeUrl: _youtubeUrlController.text.trim(),
      isDemo: _isDemoVideo,
      scheduledAt: targetSchedule,
    );

    if (!mounted) return;
    setState(() => _isUploadingVideo = false);

    if (error == null) {
      _videoTitleController.clear();
      _youtubeUrlController.clear();
      _isScheduled = false;
      _scheduledDateTime = null;
      setState(() => _showAddVideoSection = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B5E20),
            content: Text(
              wasScheduled
                  ? '✅ வீடியோ திட்டமிடப்பட்டது! குறிப்பிட்ட நேரத்தில் மாணவர்களுக்கு தானாக வெளியிடப்படும்.'
                  : '✅ வீடியோ வெற்றிகரமாக வெளியிடப்பட்டது! மாணவர்களுக்கு கிடைக்கிறது.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
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
                      isScheduled: _isScheduled,
                      scheduledDateTime: _scheduledDateTime,
                      onToggleSchedule: (val) {
                        setState(() {
                          _isScheduled = val;
                          if (_isScheduled && _scheduledDateTime == null) {
                            _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
                          }
                        });
                      },
                      onDateTimeChanged: (val) => setState(() => _scheduledDateTime = val),
                      fileName: _selectedFileName,
                      onPickFile: () => setState(() => _selectedFileName = "demo_file.mp4"),
                      onAdd: _onAddVideo,
                    ),
                  
                  if (_showAnalyticsSection)
                    CourseAnalyticsCard(courseId: widget.doc.id),

                  const SizedBox(height: 40),

                  // 5. VIDEO LIST (Drag and drop reorderable list)
                  _StaffCourseVideoListSection(courseDocId: widget.doc.id),
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
  final bool isScheduled;
  final DateTime? scheduledDateTime;
  final Function(bool) onToggleSchedule;
  final Function(DateTime) onDateTimeChanged;
  final String? fileName;
  final VoidCallback onPickFile;
  final VoidCallback onAdd;
  const _AddVideoCard({
    required this.titleCtrl,
    required this.urlCtrl,
    required this.isDemo,
    required this.isLoading,
    required this.onToggle,
    required this.isScheduled,
    required this.scheduledDateTime,
    required this.onToggleSchedule,
    required this.onDateTimeChanged,
    this.fileName,
    required this.onPickFile,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final currentSchedule = scheduledDateTime ?? DateTime.now().add(const Duration(hours: 1));

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
          TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                    labelText: "Video Title",
                    prefixIcon: Icon(Icons.subtitles)),
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
              const SizedBox(height: 20),

              // ── Scheduling Section ──────────────────────────────────
              const Text(
                "வெளியீட்டு முறை (Publishing Option)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => onToggleSchedule(false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isScheduled ? const Color(0xFF1B5E20) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isScheduled ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: !isScheduled ? Colors.white : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "உடனடியாக வெளியிடு",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: !isScheduled ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => onToggleSchedule(true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isScheduled ? Colors.blue.shade700 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isScheduled ? Colors.blue.shade700 : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule_send_rounded,
                                size: 16,
                                color: isScheduled ? Colors.white : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "நேரம் திட்டமிட (Schedule)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isScheduled ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (isScheduled) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 18, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            "மாணவர்களுக்கு வெளியிடப்படும் நேரம்:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: currentSchedule,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (pickedDate != null) {
                                  final newDt = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    currentSchedule.hour,
                                    currentSchedule.minute,
                                  );
                                  onDateTimeChanged(newDt);
                                }
                              },
                              icon: const Icon(Icons.calendar_month_rounded, size: 16),
                              label: Text(
                                "${currentSchedule.day.toString().padLeft(2, '0')}/${currentSchedule.month.toString().padLeft(2, '0')}/${currentSchedule.year}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(currentSchedule),
                                );
                                if (pickedTime != null) {
                                  final newDt = DateTime(
                                    currentSchedule.year,
                                    currentSchedule.month,
                                    currentSchedule.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  onDateTimeChanged(newDt);
                                }
                              },
                              icon: const Icon(Icons.access_time_rounded, size: 16),
                              label: Text(
                                TimeOfDay.fromDateTime(currentSchedule).format(context),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "குறிப்பு: இந்நேரம் வரும் வரை மாணவர்களுக்கு இந்த வீடியோ தோன்றாது.",
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: onAdd,
                        icon: Icon(
                          isScheduled ? Icons.schedule_send_rounded : Icons.cloud_upload_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isScheduled ? "திட்டமிடு (SCHEDULE VIDEO)" : "வெளியிடு (PUBLISH NOW)",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: isScheduled ? Colors.blue.shade700 : const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                      ),
              ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REORDERABLE VIDEO LIST SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _StaffCourseVideoListSection extends StatefulWidget {
  final String courseDocId;
  const _StaffCourseVideoListSection({required this.courseDocId});

  @override
  State<_StaffCourseVideoListSection> createState() =>
      _StaffCourseVideoListSectionState();
}

class _StaffCourseVideoListSectionState
    extends State<_StaffCourseVideoListSection> {
  List<CourseVideoModel> _videos = [];
  bool _isReordering = false;

  static String _cleanTitle(String title) {
    final match = RegExp(r'^\s*\d+[\.\s\-\)]+\s*(.*)$').firstMatch(title);
    final clean = (match != null ? match.group(1) : title)?.trim() ?? '';
    return clean.isNotEmpty ? clean : title.trim();
  }

  static String _updateTitleSNo(String currentTitle, int newIndex) {
    final sNo = (newIndex + 1).toString().padLeft(2, '0');
    final clean = _cleanTitle(currentTitle);
    if (clean.isEmpty) {
      return '$sNo. Video ${newIndex + 1}';
    }
    return '$sNo. $clean';
  }

  static int? _extractLeadingNumber(String title) {
    final match = RegExp(r'^\s*(\d+)').firstMatch(title);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  static int _compareVideos(CourseVideoModel a, CourseVideoModel b) {
    if (a.orderIndex != null && b.orderIndex != null) {
      return a.orderIndex!.compareTo(b.orderIndex!);
    }
    if (a.orderIndex != null) return -1;
    if (b.orderIndex != null) return 1;

    final numA = _extractLeadingNumber(a.title);
    final numB = _extractLeadingNumber(b.title);
    if (numA != null && numB != null && numA != numB) {
      return numA.compareTo(numB);
    }
    if (numA != null && numB == null) return -1;
    if (numA == null && numB != null) return 1;

    return a.createdAt.compareTo(b.createdAt);
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _videos.removeAt(oldIndex);
      _videos.insert(newIndex, item);

      // Dynamically update S.No for all videos based on the new rearranged order
      for (int i = 0; i < _videos.length; i++) {
        _videos[i] = _videos[i].copyWith(
          title: _updateTitleSNo(_videos[i].title, i),
          orderIndex: i,
        );
      }
      _isReordering = true;
    });

    final provider = Provider.of<CourseAccessProvider>(context, listen: false);
    final error = await provider.reorderCourseVideos(_videos);

    if (mounted) {
      setState(() {
        _isReordering = false;
      });

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ வீடியோ வரிசை மாற்றப்பட்டு சேமிக்கப்பட்டது!"),
            backgroundColor: Color(0xFF1B5E20),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("பிழை: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(CourseVideoModel video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('வீடியோவை நீக்கவா?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            Text('"${video.title}" வீடியோவை நிச்சயமாக நீக்க விரும்புகிறீர்களா?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('இல்லை', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('நீக்கு'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FirebaseFirestore.instance
          .collection('course_videos')
          .doc(video.id)
          .delete();
      final remaining = _videos.where((v) => v.id != video.id).toList();
      for (int i = 0; i < remaining.length; i++) {
        remaining[i] = remaining[i].copyWith(
          title: _updateTitleSNo(remaining[i].title, i),
          orderIndex: i,
        );
      }
      if (mounted) {
        await Provider.of<CourseAccessProvider>(context, listen: false)
            .reorderCourseVideos(remaining);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "COURSE CONTENT",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.2,
                color: Colors.grey,
              ),
            ),
            if (_videos.length > 1)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_vert_rounded,
                        size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      "Drag to reorder S.No",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('course_videos')
              .where('courseDocId', isEqualTo: widget.courseDocId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _videos.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData && !_isReordering) {
              final incomingVideos = snapshot.data!.docs
                  .map((d) => CourseVideoModel.fromFirestore(d))
                  .toList();
              incomingVideos.sort(_compareVideos);
              _videos = incomingVideos;
            }

            if (_videos.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "வீடியோக்கள் எதுவும் இல்லை",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              );
            }

            return ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _videos.length,
              onReorder: _handleReorder,
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                return Material(
                  elevation: 8,
                  color: Colors.transparent,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final video = _videos[index];
                return _StaffVideoListItem(
                  key: ValueKey(video.id),
                  video: video,
                  index: index,
                  onDelete: () => _handleDelete(video),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Replaces _VideoListItem — shows CourseVideoModel with schedule status and drag handle
class _StaffVideoListItem extends StatelessWidget {
  final CourseVideoModel video;
  final int index;
  final VoidCallback onDelete;

  const _StaffVideoListItem({
    super.key,
    required this.video,
    required this.index,
    required this.onDelete,
  });

  String _formatDateTime(DateTime dt, BuildContext context) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final timeStr = TimeOfDay.fromDateTime(dt).format(context);
    return '$d/$m/$y at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final isReleased = video.isReleased;
    final Color statusColor = isReleased ? const Color(0xFF2E7D32) : Colors.blue.shade700;
    final IconData statusIcon = isReleased ? Icons.check_circle_rounded : Icons.schedule_rounded;
    final String statusLabel = isReleased
        ? 'PUBLISHED'
        : 'SCHEDULED: ${_formatDateTime(video.scheduledAt ?? video.createdAt, context)}';

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
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (video.isDemo)
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
                    ),
                ],
              ),
              if (!isReleased) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _showRescheduleDialog(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_calendar_rounded, size: 12, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          "நேரத்தை மாற்றுக / உடனே வெளியிடு",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
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
              builder: (context) => YouTubePlayerScreen(
                  videoUrl: video.youtubeUrl, title: video.title),
            ),
          );
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isReleased)
              IconButton(
                onPressed: () => _showRescheduleDialog(context),
                icon: Icon(Icons.edit_calendar_rounded,
                    color: Colors.blue.shade700, size: 20),
                tooltip: 'நேரத்தை மாற்றுக (Reschedule)',
              ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 20),
              tooltip: 'நீக்கு (Delete)',
            ),
            const SizedBox(width: 4),
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRescheduleDialog(BuildContext context) async {
    DateTime selected = video.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "வெளியீட்டு நேரத்தை நிர்வகி",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.title,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  const Text("புதிய வெளியீட்டு தேதி & நேரம்:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selected,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setModalState(() {
                                selected = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  selected.hour,
                                  selected.minute,
                                );
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month_rounded, size: 16),
                          label: Text(
                            "${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selected),
                            );
                            if (pickedTime != null) {
                              setModalState(() {
                                selected = DateTime(
                                  selected.year,
                                  selected.month,
                                  selected.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text(
                            TimeOfDay.fromDateTime(selected).format(context),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final provider = Provider.of<CourseAccessProvider>(context, listen: false);
                        final err = await provider.updateVideoSchedule(
                          videoId: video.id,
                          scheduledAt: selected,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err ?? "✅ புதிய நேரம் திட்டமிடப்பட்டது!"),
                              backgroundColor: err == null ? const Color(0xFF1B5E20) : Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text("திட்டமிடலை சேமி (SAVE SCHEDULE)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final provider = Provider.of<CourseAccessProvider>(context, listen: false);
                        final err = await provider.publishVideoNow(video.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err ?? "✅ வீடியோ உடனடியாக வெளியிடப்பட்டது!"),
                              backgroundColor: err == null ? const Color(0xFF1B5E20) : Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF1B5E20)),
                      label: const Text(
                        "இப்போதே வெளியிடு (PUBLISH NOW)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}


