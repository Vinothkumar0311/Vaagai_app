import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../core/models/app_models.dart';
import '../../services/drive_upload_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  List<TopicModel> _topics = [];
  List<MaterialModel> _materials = [];
  bool _isLoading = true;

  final Color primaryGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cp = Provider.of<CourseProvider>(context, listen: false);
    final topics = await cp.getTopics(widget.course.id);
    final materials = await cp.getMaterials(widget.course.id);
    if (mounted) {
      setState(() {
        _topics = topics;
        _materials = materials;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final isStaffOrAdmin = user?.role == 'staff' || user?.role == 'admin';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            widget.course.title,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryGreen),
          ),
          backgroundColor: Colors.white,
          foregroundColor: primaryGreen,
          elevation: 0,
          bottom: TabBar(
            labelColor: primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryGreen,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'TOPICS'),
              Tab(text: 'RESOURCES'),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryGreen))
            : TabBarView(
                children: [
                  _buildTopicsTab(isStaffOrAdmin),
                  _buildMaterialsTab(isStaffOrAdmin),
                ],
              ),
        floatingActionButton: isStaffOrAdmin
            ? FloatingActionButton.extended(
                onPressed: () => _showAddAction(context),
                backgroundColor: primaryGreen,
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text("ADD CONTENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  Widget _buildTopicsTab(bool isStaff) {
    if (_topics.isEmpty) return _buildEmptyState('No topics added yet');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final topic = _topics[index];
        return _buildGenericCard(
          title: topic.title,
          subtitle: "Video Lecture",
          icon: Icons.play_circle_fill_rounded,
          color: Colors.red,
          onTap: () => _launchURL(topic.videoUrl),
          cta: "WATCH NOW",
        );
      },
    );
  }

  Widget _buildMaterialsTab(bool isStaff) {
    if (_materials.isEmpty) return _buildEmptyState('No materials uploaded yet');
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final material = _materials[index];
        return _buildGenericCard(
          title: material.fileName,
          subtitle: material.fileType.toUpperCase(),
          icon: Icons.picture_as_pdf_rounded,
          color: Colors.blue,
          onTap: () => _launchURL(material.fileUrl),
          cta: "OPEN FILE",
        );
      },
    );
  }

  Widget _buildGenericCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String cta,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled Header (Matching AI card aesthetic)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Icon(icon, size: 60, color: color),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E264D)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(cta, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAddAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.video_call, color: primaryGreen),
            title: const Text('Add Topic (Video URL)'),
            onTap: () {
              Navigator.pop(context);
              _showAddTopicDialog();
            },
          ),
          ListTile(
            leading: Icon(Icons.upload_file, color: primaryGreen),
            title: const Text('Upload Material (PDF/Drive)'),
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadFile();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAddTopicDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Topic Title')),
            TextField(controller: urlController, decoration: const InputDecoration(labelText: 'Video URL (YouTube)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
            onPressed: () async {
              if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                await Provider.of<CourseProvider>(context, listen: false)
                    .addTopic(widget.course.id, titleController.text, urlController.text);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator(color: primaryGreen)),
      );

      try {
        final driveUrl = await DriveUploadService.uploadFile(
          file: file,
          fileName: fileName,
          mimeType: DriveUploadService.mimeTypeFrom(fileName),
        );

        await Provider.of<CourseProvider>(context, listen: false)
            .addMaterial(widget.course.id, fileName, driveUrl, 'pdf');
        
        if (mounted) Navigator.pop(context); // Hide loading
        _loadData();
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
