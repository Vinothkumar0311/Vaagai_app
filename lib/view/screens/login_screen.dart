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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 35),
                  // Logo Section with glass effect background
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.school,
                                size: 80, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.loginTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.phoneLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                              fontSize: 14,
                            )),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: emailController,
                          hint: AppStrings.phoneHint,
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 24),
                        Text(AppStrings.passwordLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                              fontSize: 14,
                            )),
                        const SizedBox(height: 12),
                        _buildInputField(
                          controller: passwordController,
                          hint: AppStrings.passwordLabel,
                          icon: Icons.lock_rounded,
                          isPassword: true,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                            child: Text(
                              "கடவுச்சொல் மறந்துவிட்டதா?", 
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ))),
                        ),
                        const SizedBox(height: 32),

                        // Login Button with Gradient
                        Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: isLoading ? null : _login,
                            child: const Text(AppStrings.loginButton,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // Register Link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        AppStrings.noAccount,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.register);
                        },
                        child: const Text(
                          AppStrings.createAccount,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // const SizedBox(height: 50),
                  // Text(
                  //   AppStrings.footer.toUpperCase(),
                  //   style: TextStyle(
                  //     color: Colors.grey.shade300,
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w900,
                  //     letterSpacing: 4,
                  //   )
                  // ),
                  // const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withAlpha(120),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Card(
                      elevation: 10,
                      shape: CircleBorder(),
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "சரிபார்க்கிறது...",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !isPasswordVisible : false,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11.5,
              fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 45),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => isPasswordVisible = !isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
        ),
      ),
    );
  }
}
