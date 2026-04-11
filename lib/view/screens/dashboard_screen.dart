import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'student_dashboard_screen.dart';
import 'staff_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authProvider.userModel;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('பயனர் விவரங்களைக் கண்டறிய முடியவில்லை')));
    }

    switch (user.role.toLowerCase()) {
      case 'admin':
        return const AdminDashboardScreen();
      case 'staff':
        return const StaffDashboardScreen();
      case 'student':
      default:
        return const StudentDashboardScreen();
    }
  }
}
