import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class EmptyState extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.folder_open_outlined,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _fade =
  CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container with layered rings
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    // Middle ring
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          width: 1,
                        ),
                      ),
                    ),
                    // Icon core
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lightBackground2,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 28,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 10),

                // Divider line
                Container(
                  width: 32, height: 1,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),

                const SizedBox(height: 10),

                // Message
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}