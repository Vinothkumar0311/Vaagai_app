import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../core/utils/drive_utils.dart';
import '../../core/constants/app_strings.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isCheckingOut = false;
  bool _isSubmittingProof = false;
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
    
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final paymentIdOrError = await paymentProvider.createPendingPayment(
      userId: user.uid,
      userName: user.name,
      userEmail: user.email,
      courses: cart.items,
    );
    
    if (mounted) {
      setState(() => _isCheckingOut = false);
      
      if (paymentIdOrError == null || paymentIdOrError.startsWith('ERROR:')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (paymentIdOrError ?? 'ERROR: Failed to start payment')
                  .replaceFirst('ERROR: ', ''),
            ),
          ),
        );
      } else {
        final paymentId = paymentIdOrError;
        
        final proceed = await _showPrePaymentDialog(context);
        if (proceed != true || !mounted) {
          setState(() => _isCheckingOut = false);
          return;
        }

        await _openRazorpayLink();
        if (!mounted) return;
        cart.clearCart();
        await _showPostPaymentDialog(context, paymentId);
      }
    }
  }

  Future<void> _openRazorpayLink() async {
    final uri = Uri.parse(PaymentProvider.hostedPaymentLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool?> _showPrePaymentDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.prePaymentNoticeTitle,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Text(
          AppStrings.prePaymentNoticeMsg,
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("CONTINUE PAY"),
          ),
        ],
      ),
    );
  }

  Future<void> _showPostPaymentDialog(BuildContext context, String paymentId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Icon(Icons.payments_rounded, color: _primary, size: 56),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.postPaymentTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 12),
            Text(
              AppStrings.postPaymentMsg,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.postPaymentLater),
          ),
          ElevatedButton(
            onPressed: _isSubmittingProof
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    await _showProofSheet(context, paymentId);
                  },
            style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
            child: const Text(AppStrings.postPaymentPaid),
          ),
        ],
      ),
    );
  }

  Future<void> _showProofSheet(BuildContext context, String paymentId) async {
    final refCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.proofSheetTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(
                    labelText: AppStrings.proofSheetLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setSheetState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "கட்டண தேதி (Payment Date)",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingProof
                        ? null
                        : () async {
                            final ref = refCtrl.text.trim();
                            if (ref.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.proofIdRequired),
                                ),
                              );
                              return;
                            }
                            setSheetState(() => _isSubmittingProof = true);
                            final provider = Provider.of<PaymentProvider>(
                              context,
                              listen: false,
                            );
                            final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                            final error = await provider.submitManualProof(
                              paymentId: paymentId,
                              screenshotUrl: "",
                              paymentReferenceId: ref,
                              paymentDate: formattedDate,
                            );
                            if (!mounted) return;
                            setSheetState(() => _isSubmittingProof = false);
                            if (error == null) {
                              Navigator.pushNamedAndRemoveUntil(context, '/student_dashboard', (r) => false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(AppStrings.proofSubmitted),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error)),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: _primary),
                    child: _isSubmittingProof
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            AppStrings.proofSheetSubmit,
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
