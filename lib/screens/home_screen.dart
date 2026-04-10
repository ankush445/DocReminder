// home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/document_status.dart';
import '../providers/document_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';
import 'add_edit_screen.dart';

// ── Screen ─────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  DocumentStatus? _selectedStatus;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: AppConstants.animationNormal,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _dismissKeyboard());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    if (mounted) FocusScope.of(context).unfocus();
  }

  double _getHeaderHeight() {
    // Calculate header height: padding (64 + 20) + title height (~60) + spacing
    return 144;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocuments   = ref.watch(filteredDocumentsProvider);
    final documentsByStatus   = ref.watch(documentsByStatusProvider);

    final List<dynamic> displayed;
    final String sectionLabel;

    switch (_selectedStatus) {
      case DocumentStatus.valid:
        displayed    = documentsByStatus[DocumentStatus.valid] ?? [];
        sectionLabel = 'Valid Documents';
      case DocumentStatus.expiringSoon:
        displayed    = documentsByStatus[DocumentStatus.expiringSoon] ?? [];
        sectionLabel = 'Expiring Soon';
      case DocumentStatus.expired:
        displayed    = documentsByStatus[DocumentStatus.expired] ?? [];
        sectionLabel = 'Expired Documents';
      default:
        displayed    = filteredDocuments;
        sectionLabel = 'All Documents';
    }

    final validCount   = documentsByStatus[DocumentStatus.valid]?.length ?? 0;
    final warningCount = documentsByStatus[DocumentStatus.expiringSoon]?.length ?? 0;
    final expiredCount = documentsByStatus[DocumentStatus.expired]?.length ?? 0;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        resizeToAvoidBottomInset: false,

        backgroundColor: AppColors.lightBackground,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Radial glow behind header
            Positioned(
              top: -60, right: -40,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha:0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha:0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Scrollable content (without header)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child:  CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Add padding at top to account for fixed header
                  SliverToBoxAdapter(
                    child: SizedBox(height: _getHeaderHeight()),
                  ),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(
                    child: _StatsRow(
                      valid: validCount,
                      warning: warningCount,
                      expired: expiredCount,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildFilterChips(
                      filteredDocuments.length,
                      validCount, warningCount, expiredCount,
                    ),
                  ),
                  // SliverToBoxAdapter(child: _Divider()),
                  SliverToBoxAdapter(child: _buildSectionLabel(sectionLabel)),
                  displayed.isEmpty
                      ? SliverFillRemaining(
                    hasScrollBody: false, // ✅ IMPORTANT
                    child: Center(
                      child: EmptyState(
                        title: 'No $sectionLabel',
                        message: 'Add your first document to get started',
                        icon: Icons.document_scanner_outlined,
                      ),
                    ),
                  )
                      : SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final doc = displayed[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            20, index == 0 ? 0 : 6, 20, 6,
                          ),
                          child: _AnimatedCard(
                            index: index,
                            child: DocumentCard(
                              document: doc,
                              onEdit: () {
                                _dismissKeyboard();
                                Navigator.push(
                                  context,
                                  _slideRoute(AddEditScreen(document: doc)),
                                );
                              },
                              onDelete: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(documentsProvider.notifier)
                                    .deleteDocument(doc.id);
                              },
                            ),
                          ),
                        );
                      },
                      childCount: displayed.length,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 110),
                  ),
                ],
              )
            ),
            // Fixed header at top with transparency effect
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.lightBackground.withValues(alpha: 0.95),
                      AppColors.lightBackground.withValues(alpha: 0.7),
                      AppColors.lightBackground.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
                child: _buildHeader(),
              ),
            ),

            // Gold FAB
            Positioned(
              bottom: 36, left: 0, right: 0,
              child: Center(child: _buildFAB()),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-builders ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DOCUMENT VAULT',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    color: AppColors.primary,
                  ),
                ),
                // const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 32,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    children: const [
                      TextSpan(text: 'Doc'),
                      TextSpan(
                        text: 'Reminder',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _AvatarButton(initials: 'AM'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (v) {
          ref.read(searchQueryProvider.notifier).state = v;
          setState(() {});
        },
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500, // 🔥 better readability
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search documents…',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textTertiary,
          ),

          // 🔥 FIXED PREFIX ICON SPACING
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 30,
          ),

          // 🔥 SUFFIX ICON IMPROVED
          suffixIcon: _searchController.text.isNotEmpty
              ? Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: AppColors.textTertiary,
                size: 18,
              ),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
                setState(() {});
              },
            ),
          )
              : null,

          filled: true,
          fillColor: AppColors.lightSurface,

          // 🔥 REDUCED HEIGHT
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(int all, int valid, int warning, int expired) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _FilterChip(
            label: 'All', count: all,
            isSelected: _selectedStatus == null,
            activeColor: AppColors.primary,
            onTap: () => setState(() => _selectedStatus = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Valid', count: valid,
            isSelected: _selectedStatus == DocumentStatus.valid,
            activeColor: AppColors.success,
            onTap: () => setState(() => _selectedStatus = DocumentStatus.valid),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Expiring Soon', count: warning,
            isSelected: _selectedStatus == DocumentStatus.expiringSoon,
            activeColor: AppColors.warning,
            onTap: () => setState(() => _selectedStatus = DocumentStatus.expiringSoon),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Expired', count: expired,
            isSelected: _selectedStatus == DocumentStatus.expired,
            activeColor: AppColors.error,
            onTap: () => setState(() => _selectedStatus = DocumentStatus.expired),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTapDown: (_) => _fabController.forward(),
      onTapUp: (_) {
        _fabController.reverse();
        HapticFeedback.mediumImpact();
        _dismissKeyboard();
        Navigator.push(context, _slideRoute(const AddEditScreen()));
      },
      onTapCancel: () => _fabController.reverse(),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha:0.4),
                blurRadius: 24, offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha:0.25),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: AppColors.lightBackground, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add Document',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Route _slideRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, _) => page,
    transitionsBuilder: (_, a, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(1, 0), end: Offset.zero,
      ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 320),
  );
}

// ── Extracted widgets ──────────────────────────────────────────────────────

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.lightSurfaceVariant,
      border: Border.all(color: AppColors.primary.withValues(alpha:0.3), width: 1.5),
    ),
    child: Center(
      child: Text(
        initials,
        style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary,
        ),
      ),
    ),
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.valid, required this.warning, required this.expired});
  final int valid, warning, expired;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Row(
      children: [
        _StatCard(value: valid,   label: 'Valid',    color: AppColors.success),
        const SizedBox(width: 10),
        _StatCard(value: warning, label: 'Expiring', color: AppColors.warning),
        const SizedBox(width: 10),
        _StatCard(value: expired, label: 'Expired',  color: AppColors.error),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        // 🔥 LIGHT GRADIENT
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.10), // light tint
            color.withValues(alpha: 0.04), // very subtle
          ],
        ),
        borderRadius: BorderRadius.circular(12),

        // optional soft border
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w700, // 🔥 slightly bold
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.selectionClick(); onTap(); },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withValues(alpha:0.15) : AppColors.lightSurface,
        border: Border.all(
          color: isSelected ? activeColor.withValues(alpha:0.4) : Colors.white.withValues(alpha:0.08),
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isSelected ? activeColor : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
            ),
            child: isSelected
                ? Text(
              '$count',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: activeColor,
              ),
            )
                : Icon(
              Icons.arrow_forward_ios_rounded, // 🔥 clean arrow
              size: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    ),
  );
}

// class _Divider extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//     child: Container(height: 1, color: Colors.black.withValues(alpha:0.04)),
//   );
// }

class _AnimatedCard extends StatefulWidget {
  const _AnimatedCard({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.08), end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 + widget.index * 55), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}
