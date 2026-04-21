import 'package:flutter/material.dart';
import 'package:vaagai/splash_screen.dart';
import 'package:vaagai/view/screens/login_screen.dart';
import 'package:vaagai/view/screens/register_screen.dart';
import 'package:vaagai/view/screens/dashboard_screen.dart';
import 'package:vaagai/view/screens/course_detail_screen.dart';
import 'package:vaagai/core/models/app_models.dart';
import 'package:vaagai/view/screens/staff_screen.dart';
import 'package:vaagai/view/screens/document_upload_screen.dart';
import 'package:vaagai/view/screens/role_selection_screen.dart';
import 'package:vaagai/view/screens/student_dashboard_screen.dart';
import 'package:vaagai/view/screens/staff_dashboard_screen.dart';
import 'package:vaagai/view/screens/admin_dashboard_screen.dart';
import 'package:vaagai/view/screens/forgot_password_screen.dart';
import 'package:vaagai/view/screens/user_management_screen.dart';

class AppRoutes {
  // 🔹 Route Names
  static const String splash = '/';
  static const String roleSelection = '/role_selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String studentDashboard = '/student_dashboard';
  static const String staffDashboard = '/staff_dashboard';
  static const String adminDashboard = '/admin_dashboard';
  static const String courseDetail = '/course_detail';
  static const String staff = '/staff';
  static const String documentUpload = '/document_upload';
  static const String forgotPassword = '/forgot_password';
  static const String userManagement = '/user_management';

  // 🔹 Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case login:
        final role = settings.arguments as String? ?? 'Student';
        return MaterialPageRoute(builder: (_) => LoginScreen(role: role));
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case studentDashboard:
        return MaterialPageRoute(builder: (_) => const StudentDashboardScreen());
      case staffDashboard:
        return MaterialPageRoute(builder: (_) => const StaffDashboardScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case courseDetail:
        final course = settings.arguments as CourseModel;
        return MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course));
      case staff:
        return MaterialPageRoute(builder: (_) => const StaffScreen());
      case documentUpload:
        return MaterialPageRoute(builder: (_) => const DocumentUploadScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("No Route Found"))),
        );
    }
  }
}
