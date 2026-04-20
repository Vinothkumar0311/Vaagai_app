import 'package:flutter/material.dart';

class DialogUtils {
  static const _dialogTitleStyle = TextStyle(fontWeight: FontWeight.bold);
  static const _logoutButtonColor = Color(0xFF1B5E20);

  static Future<bool> showLogoutConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'வெளியேறுதல் (Logout)',
              style: _dialogTitleStyle,
            ),
            content: const Text('நீங்கள் நிச்சயமாக வெளியேற விரும்புகிறீர்களா?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    const Text('இல்லை', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _logoutButtonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('ஆம், வெளியேறு'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
