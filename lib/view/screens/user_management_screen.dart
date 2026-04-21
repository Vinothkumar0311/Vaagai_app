import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';
import '../../providers/auth_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';
  bool _isAscending = true;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _roles = ['all', 'student', 'staff', 'admin'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('பயனர் மேலாண்மை', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isAscending ? Icons.sort_by_alpha_rounded : Icons.sort_by_alpha_rounded, 
                      color: Colors.white),
            onPressed: () => setState(() => _isAscending = !_isAscending),
            tooltip: _isAscending ? 'A-Z' : 'Z-A',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search and Filter Header ─────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'பெயரைத் தேடுங்கள்...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roles.map((role) {
                      final isSelected = _selectedRoleFilter == role;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            role == 'all' ? 'அனைத்தும்' : role.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? const Color.fromARGB(255, 31, 138, 38) : const Color.fromARGB(255, 0, 0, 0), // Pure white for unselected
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedRoleFilter = role);
                          },
                          selectedColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.1), // Keep background subtle
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          side: BorderSide(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5), // Stronger border
                            width: 1,
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── User List ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('பயனர்கள் யாரும் இல்லை'));
                }

                var users = snapshot.data!.docs
                    .map((doc) => UserModel.fromFirestore(doc))
                    .toList();

                // Apply Search Filter
                if (_searchQuery.isNotEmpty) {
                  users = users.where((user) => 
                    user.name.toLowerCase().contains(_searchQuery) ||
                    user.email.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                // Apply Role Filter
                if (_selectedRoleFilter != 'all') {
                  users = users.where((user) => user.role.toLowerCase() == _selectedRoleFilter).toList();
                }

                // Apply Sorting
                users.sort((a, b) {
                  return _isAscending 
                    ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
                    : b.name.toLowerCase().compareTo(a.name.toLowerCase());
                });

                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('பயனர்கள் யாரும் கிடைக்கவில்லை', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _CompactUserCard(user: user);
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

class _CompactUserCard extends StatefulWidget {
  final UserModel user;
  const _CompactUserCard({required this.user});

  @override
  State<_CompactUserCard> createState() => _CompactUserCardState();
}

class _CompactUserCardState extends State<_CompactUserCard> {
  late String _currentRole;
  final List<String> _availableRoles = ['student', 'staff', 'admin'];

  @override
  void initState() {
    super.initState();
    _currentRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 2, right: 2), // Slightly more margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Increased opacity for better elevation
            blurRadius: 15, // Softer shadow
            offset: const Offset(0, 8), // More vertical offset
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  radius: 22,
                  child: Text(
                    widget.user.name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.email,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                _RoleBadge(role: widget.user.role),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('பங்கு:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentRole,
                        isDense: true,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black),
                        items: _availableRoles.map((role) => DropdownMenuItem(
                          value: role, 
                          child: Text(role.toUpperCase(), style: const TextStyle(letterSpacing: 0.5))
                        )).toList(),
                        onChanged: (v) => setState(() => _currentRole = v!),
                      ),
                    ),
                  ),
                  if (_currentRole != widget.user.role)
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          await authProvider.updateRole(widget.user.uid, _currentRole);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('பயனர் பங்கு புதுப்பிக்கப்பட்டது')),
                            );
                          }
                        },
                        child: const Text('Update', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role.toLowerCase()) {
      case 'admin': color = Colors.red.shade600; break;
      case 'staff': color = Colors.blue.shade600; break;
      default: color = Colors.green.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
      ),
    );
  }
}
