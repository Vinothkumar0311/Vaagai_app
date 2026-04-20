import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaagai/core/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, this.role = 'Student'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('மின்னஞ்சல் மற்றும் கடவுச்சொல் தேவை');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.login(email, password);

    if (error != null) {
      _showSnack(error);
    } else {
      if (mounted) {
        final role = authProvider.userModel?.role ?? 'student';
        debugPrint("Logged in as role: $role");
        _navigateBasedOnRole(role);
      }
    }
  }

  void _navigateBasedOnRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        break;
      case 'staff':
        Navigator.pushReplacementNamed(context, AppRoutes.staffDashboard);
        break;
      case 'student':
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
        break;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    // Normalize role check for registration display
    final bool isStudentLogin = widget.role.toLowerCase() == 'student' || widget.role.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '${widget.role} ${AppStrings.loginTitle}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      AppStrings.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('மின்னஞ்சல்', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: emailController,
                    hint: 'உதாரணம்: name@domain.com',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  const Text(AppStrings.passwordLabel, style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: passwordController,
                    hint: AppStrings.passwordLabel,
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isLoading ? null : _login,
                      child: const Text(AppStrings.loginButton, style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: GestureDetector(
                      onTap: () => _showSnack(AppStrings.forgotPassword),
                      child: Text(
                        AppStrings.forgotPassword, 
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)
                      )
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (isStudentLogin)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(AppStrings.noAccount),
                          TextButton(
                            onPressed: () {
                              debugPrint("Navigating to Register...");
                              Navigator.pushReplacementNamed(context, AppRoutes.register);
                            },
                            child: const Text(
                              AppStrings.createAccount,
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                  Center(child: Text(AppStrings.footer, style: const TextStyle(color: Colors.grey, fontSize: 18))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String? hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !isPasswordVisible : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
