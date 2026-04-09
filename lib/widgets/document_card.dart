import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/document_model.dart';
import '../screens/home_screen.dart'; // for DocColors

class DocumentCard extends StatefulWidget {
  final DocumentModel document;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  // ── Status helpers ──────────────────────────────────────────────────────

  Color get _statusColor {
    if (widget.document.isExpired) return DocColors.red;
    if (widget.document.isExpiringsoon) return DocColors.amber;
    return DocColors.green;
  }

  Color get _statusDim => _statusColor.withValues(alpha: 0.12);

  String get _statusLabel {
    if (widget.document.isExpired) return 'Expired';
    if (widget.document.isExpiringsoon) return 'Expiring Soon';
    return 'Valid';
  }

  double get _validityFraction {
    if (widget.document.isExpired) return 1.0;
    return (widget.document.daysUntilExpiry / 365.0).clamp(0.0, 1.0);
  }

  String get _dateLabel {
    if (widget.document.isExpired) return 'Expired on';
    if (widget.document.isExpiringsoon) return 'Expires in';
    return 'Expires';
  }

  String get _dateValue {
    final fmt = DateFormat('MMM dd, yyyy');
    if (widget.document.isExpired) return fmt.format(widget.document.expiryDate);
    final days = widget.document.daysUntilExpiry;
    if (days == 0) return 'Today!';
    if (days <= 30) return '$days day${days == 1 ? '' : 's'} · ${fmt.format(widget.document.expiryDate)}';
    return fmt.format(widget.document.expiryDate);
  }

  // ── Delete confirmation ─────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _DeleteDialog(
        documentName: widget.document.documentName,
      ),
    );
    if (confirmed == true) widget.onDelete();
  }

  final bool _dismissed = false;
  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Dismissible(
      key: Key('dismissible_${widget.document.id}'),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.4},
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        final confirmed = await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.6),
          builder: (_) => _DeleteDialog(
            documentName: widget.document.documentName,
          ),
        );
        return confirmed == true;   // returning false snaps card back
      },
      onDismissed: (_) => widget.onDelete(),
      background: _DismissBackground(),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          HapticFeedback.selectionClick();
          widget.onEdit();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedBuilder(
          animation: _pressController,
          builder: (context, child) => Transform.scale(
            scale: 1.0 - (_pressController.value * 0.015),
            child: child,
          ),
          child: _CardBody(
            document: widget.document,
            statusColor: _statusColor,
            statusDim: _statusDim,
            statusLabel: _statusLabel,
            dateLabel: _dateLabel,
            dateValue: _dateValue,
            validityFraction: _validityFraction,
            onEdit: widget.onEdit,
            onDelete: _confirmDelete,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }
}

// ── Card body ──────────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.document,
    required this.statusColor,
    required this.statusDim,
    required this.statusLabel,
    required this.dateLabel,
    required this.dateValue,
    required this.validityFraction,
    required this.onEdit,
    required this.onDelete,
  });

  final DocumentModel document;
  final Color statusColor;
  final Color statusDim;
  final String statusLabel;
  final String dateLabel;
  final String dateValue;
  final double validityFraction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DocColors.navy2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Stack(
        children: [
          // Left accent bar
          Positioned(
            left: 0, top: 14, bottom: 14,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(3),
                ),
              ),
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: statusDim,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconForDoc(document.documentName),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.documentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: DocColors.text1,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            document.documentType,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: DocColors.text3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    _ActionButton(
                      icon: Icons.edit_outlined,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onEdit();
                      },
                    ),
                    const SizedBox(width: 4),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      isDestructive: true,
                      onTap: onDelete,   // ← triggers _confirmDelete
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: validityFraction,
                    minHeight: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),

                const SizedBox(height: 14),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: GoogleFonts.dmSans(
                              fontSize: 11, color: DocColors.text3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateValue,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: document.isExpired || document.isExpiringsoon
                                ? statusColor
                                : DocColors.text2,
                          ),
                        ),
                      ],
                    ),
                    _StatusPill(label: statusLabel, color: statusColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForDoc(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('passport'))                                   return Icons.flight_outlined;
    if (lower.contains('licence') || lower.contains('license') ||
        lower.contains('driving')) {
      return Icons.directions_car_outlined;
    }
    if (lower.contains('health') || lower.contains('medical'))       return Icons.health_and_safety_outlined;
    if (lower.contains('insurance'))                                  return Icons.shield_outlined;
    if (lower.contains('visa'))                                       return Icons.card_travel_outlined;
    if (lower.contains('id') || lower.contains('identity'))          return Icons.badge_outlined;
    return Icons.description_outlined;
  }
}

// ── Delete confirmation dialog ─────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.documentName});
  final String documentName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DocColors.navy2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DocColors.red.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: DocColors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DocColors.red.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: DocColors.red,
                size: 26,
              ),
            ),

            const SizedBox(height: 18),

            // Title
            Text(
              'Delete Document?',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                color: DocColors.text1,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 10),

            // Body
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: DocColors.text3,
                  height: 1.6,
                ),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: '"$documentName"',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: DocColors.text2,
                    ),
                  ),
                  const TextSpan(
                      text: '? This action cannot be undone.'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Divider
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.05),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                // Cancel
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: DocColors.navy3,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: DocColors.text2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Delete
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop(true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: DocColors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DocColors.red.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: DocColors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Delete',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DocColors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor =
    widget.isDestructive ? DocColors.red : DocColors.text1;
    final activeBg = widget.isDestructive
        ? DocColors.red.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.06);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: _hovered ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? (widget.isDestructive
                  ? DocColors.red.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.12))
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(
            widget.icon,
            size: 15,
            color: _hovered ? activeColor : DocColors.text3,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    ),
    child: Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}
class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 24),
    decoration: BoxDecoration(
      color: DocColors.red.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: DocColors.red.withValues(alpha: 0.3)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.delete_outline_rounded, color: DocColors.red, size: 22),
        const SizedBox(height: 4),
        Text(
          'Delete',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DocColors.red,
          ),
        ),
      ],
    ),
  );
}