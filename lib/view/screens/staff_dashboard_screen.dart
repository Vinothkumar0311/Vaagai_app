import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/models/app_models.dart';
import '../../core/models/uploaded_document.dart';
import '../../core/utils/drive_utils.dart';
import 'staff_course_detail_screen.dart';
import '../widgets/dialogs.dart';
import '../widgets/safe_network_image.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      Provider.of<CourseProvider>(context, listen: false)
          .fetchStaffCourses(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: StreamBuilder<List<CourseModel>>(
        stream: user != null ? courseProvider.streamStaffCourses(user.uid) : Stream.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final courses = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(user),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeHeader(user),
                      const SizedBox(height: 24),
                      _buildQuickStats(context, courses.length),
                      const SizedBox(height: 32),
                      const Text(
                        "எனது பாடங்கள் (My Courses)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E264D),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              courses.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState())
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.2,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _CourseCard(course: courses[index]),
                          childCount: courses.length,
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.documentUpload),
        backgroundColor: AppColors.primary,
        elevation: 6,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('New Course',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAppBar(UserModel? user) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: const Text('Vaagai Staff', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      actions: [
        _buildNotificationBell(user?.uid ?? ''),
        IconButton(
          icon: const Icon(Icons.analytics_rounded),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.analytics),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () async {
            final confirm = await DialogUtils.showLogoutConfirmation(context);
            if (confirm && context.mounted) {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationBell(String userId) {
    return StreamBuilder<int>(
      stream: Provider.of<NotificationProvider>(context, listen: false).unreadCountStream(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.staffNotificationInbox),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeHeader(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "வணக்கம், ${user?.name ?? 'Teacher'}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20)),
        ),
        const SizedBox(height: 4),
        Text(
          "இன்று உங்கள் மாணவர்களுக்கு என்ன கற்பிக்கப் போகிறீர்கள்?",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, int courseCount) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: "பாடங்கள்",
            value: courseCount.toString(),
            icon: Icons.auto_stories_rounded,
            color: Colors.blue.shade700,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: "சந்தேகங்கள்",
            value: "Inbox",
            icon: Icons.forum_rounded,
            color: Colors.orange.shade800,
            onTap: () => Navigator.pushNamed(context, AppRoutes.staffDoubts),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade100)),
              child: Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade200),
            ),
            const SizedBox(height: 24),
            const Text(
              "பாடங்கள் எதுவும் உருவாக்கப்படவில்லை",
              style: TextStyle(color: Color(0xFF1E264D), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "உங்கள் முதல் பாடத்தை இப்போதே உருவாக்குங்கள்",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E264D))),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    String? thumbUrl = DriveUtils.getDirectViewUrl(course.imageUrl);

    return InkWell(
      onTap: () {
        // Convert CourseModel back to UploadedDocument for the detail screen
        final doc = UploadedDocument(
          id: course.id,
          title: course.title,
          objective: course.description,
          trainers: course.trainers,
          imageUrl: course.imageUrl,
          pdfUrl: course.pdfUrl,
          createdAt: course.createdAt,
          createdBy: course.createdBy,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StaffCourseDetailScreen(doc: doc)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Container(
                width: 120,
                height: double.infinity,
                color: Colors.grey.shade100,
                child: thumbUrl != null
                    ? SafeNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.school_rounded, color: Colors.grey),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(course.category.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 9)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E264D)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${course.createdAt.day}/${course.createdAt.month}/${course.createdAt.year}",
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
