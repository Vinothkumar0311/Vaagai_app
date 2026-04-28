import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/course_access_provider.dart';
import '../../core/utils/drive_utils.dart';
import '../../core/constants/app_strings.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isCheckingOut = false;
  static const Color _primary = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final user = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          AppStrings.cartTitle,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => cart.clearCart(),
              child: const Text("CLEAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final doc = cart.items[index];
                      return _CartItemCard(doc: doc, onRemove: () => cart.removeFromCart(doc.id));
                    },
                  ),
                ),
                _buildSummary(context, cart, user),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
            ),
            child: Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          const Text(
            AppStrings.emptyCartMsg,
            style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "பாடங்களைத் தேர்ந்தெடுத்து இங்கே சேர்க்கவும்",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartProvider cart, dynamic user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Selected (மொத்தம்)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${cart.count} Courses", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _primary)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isCheckingOut ? null : () => _handleCheckout(context, cart, user),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isCheckingOut
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(AppStrings.bulkRequestButton, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(BuildContext context, CartProvider cart, dynamic user) async {
    if (user == null) return;
    
    setState(() => _isCheckingOut = true);
    
    final accessProvider = Provider.of<CourseAccessProvider>(context, listen: false);
    final error = await cart.checkout(
      accessProvider: accessProvider,
      studentId: user.uid,
      studentName: user.name,
      studentEmail: user.email,
    );
    
    if (mounted) {
      setState(() => _isCheckingOut = false);
      
      if (error == null) {
        _showSuccessDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "வெற்றிகரமாக கோரிக்கை அனுப்பப்பட்டது!",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 12),
            Text(
              "நிர்வாகி உங்களது கோரிக்கையை சரிபார்த்து பாடங்களை அனுமதிப்பார்.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            child: const Text("DONE"),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final dynamic doc;
  final VoidCallback onRemove;

  const _CartItemCard({required this.doc, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final thumbUrl = DriveUtils.getDirectViewUrl(doc.imageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey.shade100,
              child: thumbUrl != null
                  ? Image.network(thumbUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.school))
                  : const Icon(Icons.school, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E264D)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  doc.trainers,
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
            tooltip: "Remove",
          ),
        ],
      ),
    );
  }
}
