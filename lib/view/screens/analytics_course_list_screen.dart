import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../widgets/course_analytics_card.dart';

class AnalyticsCourseListScreen extends StatefulWidget {
  const AnalyticsCourseListScreen({super.key});

  @override
  State<AnalyticsCourseListScreen> createState() => _AnalyticsCourseListScreenState();
}

class _AnalyticsCourseListScreenState extends State<AnalyticsCourseListScreen> {
  String? _selectedCourseId;
  String? _selectedCourseTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      
      if (auth.userModel?.role == 'admin') {
        courseProvider.fetchAllCourses();
      } else {
        courseProvider.fetchStaffCourses(auth.userModel?.uid ?? '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final bool isAdmin = auth.userModel?.role == 'admin';

    List<CourseModel> courses = isAdmin ? courseProvider.allCourses : courseProvider.staffCourses;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _selectedCourseId == null ? 'பாடநெறி பகுப்பாய்வு' : 'Analytics: $_selectedCourseTitle' , // Course Analytics
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: _selectedCourseId != null 
          ? IconButton(
              icon: const Icon(Icons.arrow_back), 
              onPressed: () => setState(() {
                _selectedCourseId = null;
                _selectedCourseTitle = null;
              })
            )
          : null,
      ),
      body: _selectedCourseId != null
        ? SingleChildScrollView(child: CourseAnalyticsCard(courseId: _selectedCourseId!))
        : courseProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : courses.isEmpty
                ? const Center(child: Text("பாடங்கள் எதுவும் இல்லை"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return _AnalyticsCourseItem(
                        course: course,
                        onTap: () => setState(() {
                          _selectedCourseId = course.id;
                          _selectedCourseTitle = course.title;
                        }),
                      );
                    },
                  ),
    );
  }
}

class _AnalyticsCourseItem extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _AnalyticsCourseItem({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 24),
        ),
        title: Text(
          course.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(course.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
