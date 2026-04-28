import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'admin_payment_approval_screen.dart';
import 'admin_video_approval_screen.dart';
import '../widgets/dialogs.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('நிர்வாகி பகுதி (Admin)', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final confirm = await DialogUtils.showLogoutConfirmation(context);
              if (confirm && context.mounted) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Action Cards ──────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'நிர்வாக பணிகள்',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('course_access')
                            .where('paymentStatus', isEqualTo: 'pending')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.docs.length ?? 0;
                          return _AdminActionCard(
                            icon: Icons.payments_rounded,
                            title: 'கட்டண ஒப்பதல்கள்',
                            subtitle: count > 30 ? '30+ requests' : '$count requests',
                            color: const Color(0xFF2E7D32),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminPaymentApprovalScreen()),
                            ),
                          );
                        }
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('course_videos')
                            .where('status', isEqualTo: 'pending')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.docs.length ?? 0;
                          return _AdminActionCard(
                            icon: Icons.video_collection_rounded,
                            title: 'வீடியோ ஒப்பதல்கள்',
                            subtitle: count > 10 ? '10+ videos' : '$count videos',
                            color: Colors.indigo.shade800,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminVideoApprovalScreen()),
                            ),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Management Sections ──────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'மேலாண்மை',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AdminSelectionCard(
                      title: 'பயனர் மேலாண்மை',
                      subtitle: 'பயனர்களைத் தேடவும், வடிகட்டவும் மற்றும் பங்குகளை மாற்றவும்',
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.userManagement),
                    ),
                    const SizedBox(height: 16),
                    _AdminSelectionCard(
                      title: 'பாடநெறி அமைப்புகள்',
                      subtitle: 'பாடநெறிகளை நிர்வகிக்கவும் மற்றும் புதியவற்றைச் சேர்க்கவும்',
                      icon: Icons.menu_book_rounded,
                      color: Colors.orange.shade800,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.documentUpload),
                    ),
                    const SizedBox(height: 16),
                    _AdminSelectionCard(
                      title: 'பாடநெறி பகுப்பாய்வு',
                      subtitle: 'அனைத்து பாடநெறிகளின் மாணவர் முன்னேற்றத்தை சரிபார்க்கவும்',
                      icon: Icons.analytics_rounded,
                      color: Colors.blue.shade800,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminSelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 14),
          ],
        ),
      ),
    );
  }
}
