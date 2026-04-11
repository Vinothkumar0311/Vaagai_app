import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaagai/core/constants/app_colors.dart';
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
      phone: phoneController.text.trim(),
      whatsapp: whatsappController.text.trim(),
      aadhar: aadharController.text.trim(),
    );

    if (error != null) {
      _showSnack(error);
    } else {
      _showSnack('பதிவு வெற்றிகரமாக முடிந்தது! 🎉');
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
        title: const Text('புதிய பதிவு'),
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
                  Text('கணக்கு உருவாக்கவும்', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text('உங்கள் விவரங்களை பூர்த்தி செய்யவும்', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  _buildTextField(controller: nameController, hint: 'பெயர் (Name)', icon: Icons.person_outline, validator: (v) => v!.trim().isEmpty ? 'பெயர் தேவை' : null),
                  _buildTextField(controller: phoneController, hint: 'கைபேசி எண் (Phone)', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
                  _buildTextField(controller: whatsappController, hint: 'வாட்ஸ்அப் எண் (WhatsApp)', icon: Icons.message_outlined, keyboard: TextInputType.phone),
                  _buildTextField(controller: emailController, hint: 'மின்னஞ்சல் (Email)', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                  _buildTextField(controller: aadharController, hint: 'ஆதார் எண் (Aadhar)', icon: Icons.credit_card_outlined, keyboard: TextInputType.number),
                  _buildPasswordField(
                    controller: passwordController,
                    hint: 'கடவுச்சொல்',
                    isVisible: _showPassword,
                    onToggle: () => setState(() => _showPassword = !_showPassword),
                    validator: (v) => v!.length < 6 ? 'குறைந்தது 6 எழுத்துகள்' : null,
                  ),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    hint: 'கடவுச்சொல் உறுதிப்படுத்தவும்',
                    isVisible: _showConfirmPassword,
                    onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    validator: (v) => v != passwordController.text ? 'கடவுச்சொல் பொருந்தவில்லை' : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isLoading ? null : registerUser,
                      child: const Text('பதிவு செய்', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ஏற்கனவே கணக்கு உள்ளதா? '),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                          child: const Text('உள்நுழைக', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, String? Function(String?)? validator, TextInputType? keyboard}) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String hint, required bool isVisible, required VoidCallback onToggle, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.secondary),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
            onPressed: onToggle,
          ),
          hintText: hint,
          filled: true,
          fillColor: AppColors.inputFill,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}