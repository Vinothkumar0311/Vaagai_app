import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaagai/core/constants/app_colors.dart';
import 'package:vaagai/core/constants/app_strings.dart';
import 'package:vaagai/core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController aadharController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _countryCode = '+91';
  final List<String> _countryCodes = [
    '+91', '+1', '+44', '+971', '+65', '+60', '+61', '+49', '+33', '+81'
  ];

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    emailController.dispose();
    aadharController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.register(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      phone: '$_countryCode${phoneController.text.trim()}',
      whatsapp: whatsappController.text.trim(),
      aadhar: aadharController.text.trim(),
    );

    if (error != null) {
      _showSnack(error);
    } else {
      _showSnack(AppStrings.registerSuccess);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        // After registration, user is already logged in Firebase Auth.
        // Redirect to dashboard (which handles role-based UI).
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: msg.contains('வெற்றிகரமாக') ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   foregroundColor: AppColors.primary,
      //   elevation: 0,
      //   centerTitle: true,
      // ),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.04),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    // Logo Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 70,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.school, size: 50, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      AppStrings.createAccountTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.fillDetailsSubtitle,
                      style: TextStyle(
                        color: Colors.grey, 
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 35),
                    
                    // Registration Form Card
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
                          _buildLabel(AppStrings.nameLabel),
                          _buildTextField(
                              controller: nameController,
                              hint: "உங்கள் பெயர்",
                              icon: Icons.person_rounded,
                              validator: (v) =>
                                  v!.trim().isEmpty ? AppStrings.nameRequired : null),
                          const SizedBox(height: 24),
                          
                          _buildLabel(AppStrings.regPhoneLabel),
                          _buildPhoneField(
                              controller: phoneController,
                              hint: "9876543210",
                              icon: Icons.phone_android_rounded),
                          const SizedBox(height: 24),

                          _buildLabel(AppStrings.whatsappLabel),
                          _buildTextField(
                              controller: whatsappController,
                              hint: "வாட்ஸ்அப் எண்",
                              icon: Icons.chat_bubble_rounded,
                              keyboard: TextInputType.phone),
                          const SizedBox(height: 24),

                          _buildLabel(AppStrings.emailLabel),
                          _buildTextField(
                              controller: emailController,
                              hint: "name@email.com",
                              icon: Icons.alternate_email_rounded,
                              keyboard: TextInputType.emailAddress),
                          const SizedBox(height: 24),

                          _buildLabel(AppStrings.idLabel),
                          _buildTextField(
                              controller: aadharController,
                              hint: "ஆதார் எண்",
                              icon: Icons.badge_rounded,
                              keyboard: TextInputType.text),
                          const SizedBox(height: 24),

                          _buildLabel(AppStrings.regPasswordLabel),
                          _buildPasswordField(
                            controller: passwordController,
                            hint: "கடவுச்சொல்",
                            isVisible: _showPassword,
                            onToggle: () =>
                                setState(() => _showPassword = !_showPassword),
                            validator: (v) {
                              if (v!.length < 8) return AppStrings.passwordMinError;
                              if (!v.contains(RegExp(r'[A-Z]'))) {
                                return AppStrings.passwordCapsError;
                              }
                              if (!v.contains(RegExp(r'[0-9]'))) {
                                return AppStrings.passwordNumError;
                              }
                              if (!v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
                                return AppStrings.passwordSymbolError;
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 8),
                            child: Text(
                              AppStrings.passwordHelper,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildLabel(AppStrings.confirmPasswordLabel),
                          _buildPasswordField(
                            controller: confirmPasswordController,
                            hint: "கடவுச்சொல்லை மீண்டும் உள்ளிடவும்",
                            isVisible: _showConfirmPassword,
                            onToggle: () => setState(
                                () => _showConfirmPassword = !_showConfirmPassword),
                            validator: (v) => v != passwordController.text
                                ? AppStrings.passwordMatchError
                                : null,
                          ),
                          const SizedBox(height: 32),

                          // Register Button with Gradient
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
                              onPressed: isLoading ? null : registerUser,
                              child: const Text(AppStrings.registerButton,
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 35),
                    
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(AppStrings.alreadyHaveAccount, 
                            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, AppRoutes.login),
                          child: const Text(AppStrings.loginLinkText,
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
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
                    const Text(
                      "பதிவு செய்கிறது...",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      String? Function(String?)? validator,
      TextInputType? keyboard}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 45),
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11.5,
              fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
      {required TextEditingController controller,
      required String hint,
      required bool isVisible,
      required VoidCallback onToggle,
      String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 45),
          suffixIcon: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
                isVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.grey.shade400,
                size: 18),
            onPressed: onToggle,
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 40),
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11.5,
              fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
        ),
      ),
    );
  }

  Widget _buildPhoneField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButton<String>(
            value: _countryCode,
            underline: const SizedBox(),
            items: _countryCodes
                .map((code) => DropdownMenuItem(
                    value: code,
                    child: Text(code,
                        style: const TextStyle(fontWeight: FontWeight.w600))))
                .toList(),
            onChanged: (val) => setState(() => _countryCode = val!),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
                prefixIconConstraints: const BoxConstraints(minWidth: 45),
                hintText: hint,
                hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11.5,
                    fontWeight: FontWeight.normal),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}