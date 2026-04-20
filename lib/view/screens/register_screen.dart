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
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppStrings.registerAppBar),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(AppStrings.createAccountTitle,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                  const SizedBox(height: 4),
                  const Text(AppStrings.fillDetailsSubtitle,
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  _buildTextField(
                      controller: nameController,
                      hint: AppStrings.nameLabel,
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v!.trim().isEmpty ? AppStrings.nameRequired : null),
                  _buildPhoneField(
                      controller: phoneController,
                      hint: AppStrings.regPhoneLabel,
                      icon: Icons.phone_outlined),
                  _buildTextField(
                      controller: whatsappController,
                      hint: AppStrings.whatsappLabel,
                      icon: Icons.message_outlined,
                      keyboard: TextInputType.phone),
                  _buildTextField(
                      controller: emailController,
                      hint: AppStrings.emailLabel,
                      icon: Icons.email_outlined,
                      keyboard: TextInputType.emailAddress),
                  _buildTextField(
                      controller: aadharController,
                      hint: AppStrings.idLabel,
                      icon: Icons.credit_card_outlined,
                      keyboard: TextInputType.text),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordField(
                        controller: passwordController,
                        hint: AppStrings.regPasswordLabel,
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
                          return null;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 12),
                        child: Text(
                          AppStrings.passwordHelper,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    hint: AppStrings.confirmPasswordLabel,
                    isVisible: _showConfirmPassword,
                    onToggle: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword),
                    validator: (v) => v != passwordController.text
                        ? AppStrings.passwordMatchError
                        : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isLoading ? null : registerUser,
                      child: const Text(AppStrings.registerButton,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(AppStrings.alreadyHaveAccount),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, AppRoutes.login),
                          child: const Text(AppStrings.loginLinkText,
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      String? Function(String?)? validator,
      TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.secondary),
          hintText: hint,
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.secondary),
          suffixIcon: IconButton(
            icon: Icon(
                isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey),
            onPressed: onToggle,
          ),
          hintText: hint,
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildPhoneField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<String>(
              value: _countryCode,
              underline: const SizedBox(),
              items: _countryCodes
                  .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                  .toList(),
              onChanged: (val) => setState(() => _countryCode = val!),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: AppColors.secondary),
                hintText: hint,
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}