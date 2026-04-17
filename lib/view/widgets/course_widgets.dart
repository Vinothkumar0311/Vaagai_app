import 'package:flutter/material.dart';
import '../../core/models/course_access_model.dart';
import '../../core/models/course_video_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATUS CHIP
// ─────────────────────────────────────────────────────────────────────────────

/// A pill-shaped chip showing Approved / Pending / Rejected / Locked states.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  /// Factory constructors for standard statuses
  factory StatusChip.fromPaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.approved:
        return StatusChip(
          label: 'Approved',
          color: const Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        );
      case PaymentStatus.rejected:
        return StatusChip(
          label: 'Rejected',
          color: Colors.red.shade700,
          icon: Icons.cancel_rounded,
        );
      case PaymentStatus.pending:
        return StatusChip(
          label: 'Pending',
          color: Colors.orange.shade700,
          icon: Icons.hourglass_top_rounded,
        );
    }
  }

  factory StatusChip.fromVideoStatus(VideoStatus status) {
    switch (status) {
      case VideoStatus.approved:
        return StatusChip(
          label: 'Approved',
          color: const Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        );
      case VideoStatus.rejected:
        return StatusChip(
          label: 'Rejected',
          color: Colors.red.shade700,
          icon: Icons.cancel_rounded,
        );
      case VideoStatus.pending:
        return StatusChip(
          label: 'Pending Review',
          color: Colors.orange.shade700,
          icon: Icons.pending_rounded,
        );
    }
  }

  factory StatusChip.locked() {
    return const StatusChip(
      label: 'Locked',
      color: Color(0xFF757575),
      icon: Icons.lock_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UPLOAD COUNTER BANNER
// ─────────────────────────────────────────────────────────────────────────────

/// Shows how many of 4 weekly uploads have been used, with a progress bar.
class WeeklyUploadBanner extends StatelessWidget {
  final int used;
  final int total;

  const WeeklyUploadBanner({
    super.key,
    required this.used,
    this.total = 4,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - used;
    final fraction = used / total;
    final color = remaining == 0
        ? Colors.red.shade600
        : remaining == 1
            ? Colors.orange.shade700
            : const Color(0xFF1B5E20);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'இந்த வார பதிவேற்றம்',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$used / $total பயன்படுத்தப்பட்டது',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (remaining == 0)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                '⚠️ வீடியோ வரம்பு நிரம்பியது. அடுத்த திங்கட்கிழமை மீண்டும் முயலவும்.',
                style: TextStyle(color: color, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO THUMBNAIL CARD (for admin approval & student view)
// ─────────────────────────────────────────────────────────────────────────────

class VideoThumbnailCard extends StatelessWidget {
  final CourseVideoModel video;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showStatus;

  const VideoThumbnailCard({
    super.key,
    required this.video,
    this.onTap,
    this.trailing,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final thumbUrl = video.thumbnailUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: thumbUrl != null
                        ? Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.play_circle_outline,
                                  size: 48, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.play_circle_outline,
                                size: 48, color: Colors.grey),
                          ),
                  ),
                  // Play icon overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  // Demo badge
                  if (video.isDemo)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'FREE PREVIEW',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E264D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By ${video.uploadedByName}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (showStatus)
                        StatusChip.fromVideoStatus(video.status),
                      if (trailing != null) trailing!,
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM DIALOG (Approve / Reject)
// ─────────────────────────────────────────────────────────────────────────────

class ConfirmActionDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool showReasonField;
  final String confirmLabel;
  final Color confirmColor;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.showReasonField = false,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  State<ConfirmActionDialog> createState() => _ConfirmActionDialogState();
}

class _ConfirmActionDialogState extends State<ConfirmActionDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          if (widget.showReasonField) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                hintText: 'காரணம் (விரும்பினால்)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('ரத்து செய்',
              style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.confirmColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(
              context, _reasonCtrl.text.trim().isEmpty ? 'confirmed' : _reasonCtrl.text.trim()),
          child: Text(widget.confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
