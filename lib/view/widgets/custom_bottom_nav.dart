import 'package:flutter/material.dart';
import 'package:vaagai/core/constants/app_colors.dart';
import 'package:vaagai/core/routes/app_routes.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            break;
          case 1:
            Navigator.pushReplacementNamed(context, AppRoutes.courseDetail);
            break;
          // Add additional cases for other tabs (Learning, Profile) when the screens are ready
          case 2:
            break;
          case 3:
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: [
        _buildItem(Icons.home, 'முகப்பு', 0),
        _buildItem(Icons.menu_book, 'பாடங்கள்', 1),
        _buildItem(Icons.auto_stories, 'கற்றல்', 2),
        _buildItem(Icons.person, 'சுயவிவரம்', 3),
      ],
    );
  }

  BottomNavigationBarItem _buildItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: currentIndex == index
                ? Colors.green.shade50
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon),
        ),
      ),
      label: label,
    );
  }
}
