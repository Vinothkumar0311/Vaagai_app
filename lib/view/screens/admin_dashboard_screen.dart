import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import 'admin_payment_approval_screen.dart';
import 'admin_video_approval_screen.dart';
import '../widgets/dialogs.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  static const _roles = ['student', 'staff', 'admin'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('நிர்வாகி பகுதி (Admin)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await DialogUtils.showLogoutConfirmation(context);
              if (confirm && context.mounted) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Action Cards ──────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'நிர்வாக பகுதிகள்',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
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
                              icon: Icons.payment_rounded,
                              title: 'கட்டண\nஒப்புதல்',
                              subtitle:
                                  count > 0 ? '$count requests' : 'No requests',
                              color: const Color(0xFF1B5E20),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminPaymentApprovalScreen()),
                              ),
                            );
                          }),
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
                              icon: Icons.video_library_rounded,
                              title: 'வீடியோ\nஒப்புதல்',
                              subtitle:
                                  count > 0 ? '$count videos' : 'No videos',
                              color: Colors.indigo.shade700,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminVideoApprovalScreen()),
                              ),
                            );
                          }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 4),
                const Text(
                  'பயனர் மேலாண்மை',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          // ── User List ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('பயனர்கள் யாரும் இல்லை'));
                }

                final users = snapshot.data!.docs
                    .map((doc) => UserModel.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserListItem(user: user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN ACTION CARD
// ─────────────────────────────────────────────────────────────────────────────

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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.2),
            ),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.75), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _UserListItem extends StatefulWidget {
  final UserModel user;
  const _UserListItem({required this.user});

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(widget.user.name[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(widget.user.email,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(widget.user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.user.role.toUpperCase(),
                    style: TextStyle(
                        color: _getRoleColor(widget.user.role),
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: AdminDashboardScreen._roles.map((role) {
                      return DropdownMenuItem(
                          value: role, child: Text(role.toUpperCase()));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedRole = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await authProvider.updateRole(
                        widget.user.uid, _selectedRole);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('பயனர் பங்கு புதுப்பிக்கப்பட்டது')),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'staff':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}
