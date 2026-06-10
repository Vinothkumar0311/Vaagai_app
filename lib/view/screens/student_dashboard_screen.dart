import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vaagai/core/constants/app_strings.dart';
import '../../core/utils/drive_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_access_provider.dart';
import '../../providers/progress_provider.dart';
import '../../core/models/uploaded_document.dart';
import '../../core/models/course_access_model.dart';
import '../../core/models/course_progress_model.dart';
import '../widgets/course_widgets.dart';
import 'course_content_detail_screen.dart';
import 'payment_registration_screen.dart';
import '../widgets/dialogs.dart';
import 'student_doubts_screen.dart';
import '../../providers/cart_provider.dart';
import '../../core/routes/app_routes.dart';

import 'student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  static const Color _primaryGreen = Color(0xFF1B5E20);
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user != null) {
        Provider.of<CourseAccessProvider>(context, listen: false)
            .startListeningToMyAccessRecords(user.uid);
        Provider.of<ProgressProvider>(context, listen: false)
            .startListeningToStudentProgress(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWebWide = width >= 900;

    if (isWebWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFFCF9F0),
        body: Row(
          children: [
            _buildSidebar(),
            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildWebCoursesTab(),
                  const StudentDoubtsScreen(),
                  const StudentProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildCoursesTab(),
            const StudentDoubtsScreen(),
            const StudentProfileScreen(),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSidebar() {
    final user = Provider.of<AuthProvider>(context).userModel;
    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo & App Name
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 48,
                errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 48, color: _primaryGreen),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "வாகை",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          
          // Navigation Items
          _sidebarNavItem(Icons.menu_book_rounded, AppStrings.coursesTab, 0),
          const SizedBox(height: 8),
          _sidebarNavItem(Icons.notifications_none_rounded, AppStrings.notificationsTab, 1),
          const SizedBox(height: 8),
          _sidebarNavItem(Icons.person_outline_rounded, AppStrings.profileTab, 2),
          
          const Spacer(),
          
          // User Info & Logout
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _primaryGreen.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: _primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          user.role,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("உள்நுழைவு விலகுக", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onTap: () async {
              final confirm = await DialogUtils.showLogoutConfirmation(context);
              if (confirm && mounted) {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _sidebarNavItem(IconData icon, String label, int index) {
    final bool active = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active ? _primaryGreen.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? _primaryGreen : Colors.grey.shade600, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: active ? _primaryGreen : Colors.grey.shade700,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebCoursesTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "வாகை பாடங்கள் (Vaagai Courses)",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                  ),
                ),
                Row(
                  children: [
                    Consumer<CartProvider>(
                      builder: (context, cart, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_rounded, color: _primaryGreen),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                            tooltip: 'My Cart',
                          ),
                          if (cart.count > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '${cart.count}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              AppStrings.startLearning,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen),
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('course_uploads')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                      child: CircularProgressIndicator(color: _primaryGreen)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return SliverToBoxAdapter(child: _buildEmptyState());
            }

            final docs = snapshot.data!.docs
                .map((d) => UploadedDocument.fromFirestore(d))
                .toList();

            return Consumer3<CourseAccessProvider, ProgressProvider, CartProvider>(
              builder: (context, accessProvider, progressProvider, cartProvider, _) {
                final user =
                    Provider.of<AuthProvider>(context, listen: false).userModel;
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      mainAxisExtent: 480,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        final accessRecord = user != null
                            ? accessProvider.accessRecordFor(doc.id)
                            : null;
                        final hasAccess = user != null &&
                            accessProvider.isCourseAccessible(user.uid, doc.id);
                        final progress = progressProvider.myProgress[doc.id];
                        final inCart = cartProvider.isInCart(doc.id);

                        return _CourseCard(
                          doc: doc,
                          primaryGreen: _primaryGreen,
                          hasAccess: hasAccess,
                          accessRecord: accessRecord,
                          progress: progress,
                          inCart: inCart,
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 50)),
      ],
    );
  }



  Widget _buildCoursesTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: _primaryGreen,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            title: const Text(
              "வாகை பாடங்கள்",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white),
            ),
            background: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryGreen, Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -30,
                  top: -10,
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.school, size: 200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Consumer<CartProvider>(
              builder: (context, cart, _) => Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                    tooltip: 'My Cart',
                  ),
                  if (cart.count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cart.count}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: () async {
                final confirm = await DialogUtils.showLogoutConfirmation(context);
                if (confirm && context.mounted) {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              AppStrings.startLearning,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen),
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('course_uploads')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: CircularProgressIndicator(color: _primaryGreen)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return SliverToBoxAdapter(child: _buildEmptyState());
            }

            final docs = snapshot.data!.docs
                .map((d) => UploadedDocument.fromFirestore(d))
                .toList();

            return Consumer3<CourseAccessProvider, ProgressProvider, CartProvider>(
              builder: (context, accessProvider, progressProvider, cartProvider, _) {
                final user =
                    Provider.of<AuthProvider>(context, listen: false).userModel;
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        final accessRecord = user != null
                            ? accessProvider.accessRecordFor(doc.id)
                            : null;
                        final hasAccess = user != null &&
                            accessProvider.isCourseAccessible(user.uid, doc.id);
                        final progress = progressProvider.myProgress[doc.id];
                        final inCart = cartProvider.isInCart(doc.id);

                        return _CourseCard(
                          doc: doc,
                          primaryGreen: _primaryGreen,
                          hasAccess: hasAccess,
                          accessRecord: accessRecord,
                          progress: progress,
                          inCart: inCart,
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }



  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'தற்போது பாடங்கள் எதுவும் இல்லை',
            style: TextStyle(
                color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.menu_book_rounded, AppStrings.coursesTab, 0),
          _navItem(
              Icons.notifications_none_rounded, AppStrings.notificationsTab, 1),
          _navItem(Icons.person_outline_rounded, AppStrings.profileTab, 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool active = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: active
            ? BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? _primaryGreen : Colors.grey.shade400, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: active ? _primaryGreen : Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final UploadedDocument doc;
  final Color primaryGreen;
  final bool hasAccess;
  final CourseAccessModel? accessRecord;
  final CourseProgressModel? progress;
  final bool inCart;

  const _CourseCard({
    required this.doc,
    required this.primaryGreen,
    this.hasAccess = false,
    this.accessRecord,
    this.progress,
    this.inCart = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrl = DriveUtils.getDirectViewUrl(doc.imageUrl);
    final isPending = accessRecord?.paymentStatus == PaymentStatus.pending;
    final isLocked = !hasAccess;

    bool showContactAdmin = false;
    if (isPending && accessRecord != null) {
      final diff = DateTime.now().difference(accessRecord!.createdAt);
      if (diff.inHours >= 48) {
        showContactAdmin = true;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.indigo.shade50,
                  child: displayUrl != null
                      ? Image.network(
                          displayUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.school_rounded,
                                  size: 48, color: Color(0xFF1B5E20))),
                        )
                      : const Center(
                          child: Icon(Icons.school_rounded,
                              size: 48, color: Color(0xFF1B5E20))),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4)
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F3D),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            doc.trainers.split(',').first.trim(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doc.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Color(0xFF1B5E20)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (accessRecord != null)
                        StatusChip.fromPaymentStatus(
                            accessRecord!.paymentStatus)
                      else if (isLocked)
                        StatusChip.locked(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc.objective,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (isPending && accessRecord != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          "Requested on: ${accessRecord!.createdAt.day.toString().padLeft(2, '0')}/${accessRecord!.createdAt.month.toString().padLeft(2, '0')}/${accessRecord!.createdAt.year}",
                          style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (hasAccess && progress != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700)),
                        Text(
                            '${progress!.progressPercentage.toStringAsFixed(0)}% (${progress!.completedVideosCount}/${progress!.totalVideos})',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress!.totalVideos > 0
                          ? progress!.progressPercentage / 100
                          : 0,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF1B5E20),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (hasAccess) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CourseContentDetailScreen(
                                      doc: doc,
                                      lastVideoId: progress?.lastVideoId,
                                      lastTimestamp: progress?.lastTimestamp,
                                    )),
                          );
                        } else if (isPending) {
                          if (showContactAdmin) {
                            final Uri uri = Uri.parse('tel:+919842421250');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      PaymentRegistrationScreen(doc: doc)),
                            );
                          }
                        } else {
                          // Toggle Cart or Go to Details
                          if (inCart) {
                            Navigator.pushNamed(context, AppRoutes.cart);
                          } else {
                            Provider.of<CartProvider>(context, listen: false).addToCart(doc);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${doc.title} added to cart"),
                                action: SnackBarAction(label: "VIEW CART", onPressed: () => Navigator.pushNamed(context, AppRoutes.cart)),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isPending
                                ? (showContactAdmin ? Colors.red.shade800 : Colors.orange.shade700)
                                : primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasAccess
                                ? Icons.play_arrow_rounded
                                : isPending
                                    ? (showContactAdmin ? Icons.phone : Icons.hourglass_top_rounded)
                                    : inCart ? Icons.shopping_cart_checkout : Icons.add_shopping_cart_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasAccess
                                ? (progress != null &&
                                        progress!.lastVideoId != null
                                    ? "Continue Watching"
                                    : AppStrings.accessMaterial)
                                : isPending
                                    ? (showContactAdmin
                                        ? "Contact Admin (நிர்வாகியை அழைக்கவும்)"
                                        : AppStrings.approvalPending)
                                    : inCart ? AppStrings.goToCart : AppStrings.addToCart,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!hasAccess && !isPending && !inCart)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    PaymentRegistrationScreen(doc: doc)),
                          );
                        },
                        child: Text(AppStrings.viewDetails, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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
