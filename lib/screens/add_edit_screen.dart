import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';
import '../models/reminder_offset.dart';
import '../providers/document_provider.dart';
import '../services/file_service.dart';
import '../widgets/reminder_offset_dropdown.dart';
import '../widgets/document_preview.dart';
import 'home_screen.dart'; // for DocColors

class AddEditScreen extends ConsumerStatefulWidget {
  final DocumentModel? document;
  const AddEditScreen({super.key, this.document});

  @override
  ConsumerState<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends ConsumerState<AddEditScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late DateTime _selectedDate;
  late TimeOfDay _reminderTime;
  late bool _reminderEnabled;
  late ReminderOffset _selectedOffset;
  String? _selectedFilePath;
  String? _selectedFileName;
  String? _selectedDocumentType;
  bool _isLoading = false;

  late final AnimationController _saveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  final FileService _fileService = FileService();

  // ── Document types ─────────────────────────────────────────────────────
  static const _documentTypes = [
    ('🪪', 'Identity',    'ID Card, Aadhar, PAN'),
    ('🛂', 'Travel',      'Passport, Visa'),
    ('🚗', 'Vehicle',     'Licence, RC, Insurance'),
    ('🏥', 'Medical',     'Health card, Reports'),
    ('🏦', 'Financial',   'Bank, Tax, Statements'),
    ('🏠', 'Property',    'Lease, Deed, NOC'),
    ('🎓', 'Education',   'Degree, Certificates'),
    ('📋', 'Other',       'Miscellaneous'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.document?.documentName ?? '',
    );
    _selectedDate = widget.document?.expiryDate ??
        DateTime.now().add(const Duration(days: 1));
    _reminderTime = widget.document != null
        ? TimeOfDay(
      hour: widget.document!.reminderHour,
      minute: widget.document!.reminderMinute,
    )
        : const TimeOfDay(hour: 9, minute: 0);
    _reminderEnabled = widget.document?.reminderEnabled ?? true;
    _selectedOffset = widget.document?.reminderOffset ?? ReminderOffset.sevenDays;
    _selectedDocumentType = widget.document?.documentType;
    _selectedFileName =
    widget.document != null ? _fileService.getFileName(widget.document!.filePath) : null;
    _loadFilePath();
  }

  Future<void> _loadFilePath() async {
    if (widget.document?.filePath != null) {
      final fullPath = await _fileService.getFullPath(widget.document!.filePath);
      if (mounted) setState(() => _selectedFilePath = fullPath);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  // ── File picking ────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      FocusScope.of(context).unfocus();
      final filePath = await _fileService.pickFile();
      if (mounted && filePath != null) {
        setState(() {
          _selectedFilePath = filePath;
          _selectedFileName = _fileService.getFileName(filePath);
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error picking file: $e');
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final filePath = await _fileService.openCamera();
      if (mounted && filePath != null) {
        setState(() {
          _selectedFilePath = filePath;
          _selectedFileName = _fileService.getFileName(filePath);
        });
      } else if (mounted) {
        _showErrorSnackbar('Camera permission denied. Enable it in settings.');
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final filePath = await _fileService.pickFromGallery();
      if (mounted && filePath != null) {
        setState(() {
          _selectedFilePath = filePath;
          _selectedFileName = _fileService.getFileName(filePath);
        });
      } else if (mounted) {
        _showErrorSnackbar('Photo permission denied. Enable it in settings.');
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error: $e');
    }
  }

  void _showSourceOptions() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SourceBottomSheet(
        onCamera: () async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) await _captureFromCamera();
        },
        onGallery: () async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) await _pickFromGallery();
        },
        onFiles: () async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) await _pickFile();
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: _datePickerTheme(context),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    FocusScope.of(context).unfocus();
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: _datePickerTheme(context),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  ThemeData _datePickerTheme(BuildContext context) => ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(
      primary: DocColors.gold,
      onPrimary: DocColors.navy,
      surface: DocColors.navy2,
      onSurface: DocColors.text1,
    ),
    dialogBackgroundColor: DocColors.navy2,
  );

  // ── Save ────────────────────────────────────────────────────────────────

  Future<void> _saveDocument() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackbar('Please enter a document name');
      return;
    }
    if (_selectedFilePath == null) {
      _showErrorSnackbar('Please select a file');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      String finalPath = _selectedFilePath!;
      if (widget.document == null ||
          widget.document!.filePath != _selectedFilePath) {
        finalPath = await _fileService.copyFileToAppDirectory(_selectedFilePath!);
      }

      if (widget.document == null) {
        await ref.read(documentsProvider.notifier).addDocument(
          DocumentModel(
            id: const Uuid().v4(),
            documentName: _nameController.text.trim(),
            documentType: _selectedDocumentType ?? "Other",
            filePath: finalPath,
            expiryDate: _selectedDate,
            reminderEnabled: _reminderEnabled,
            reminderOffsetDays: _selectedOffset.days,
            reminderHour: _reminderTime.hour,
            reminderMinute: _reminderTime.minute,
          ),
        );
      } else {
        await ref.read(documentsProvider.notifier).updateDocument(
          widget.document!.copyWith(
            documentName: _nameController.text.trim(),
            documentType: _selectedDocumentType,
            filePath: finalPath,
            expiryDate: _selectedDate,
            reminderEnabled: _reminderEnabled,
            reminderOffsetDays: _selectedOffset.days,
            reminderHour: _reminderTime.hour,
            reminderMinute: _reminderTime.minute,
          ),
        );
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        Navigator.of(context).pop();
        _showSuccessSnackbar(
          widget.document == null ? 'Document added' : 'Document updated',
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Snackbars ───────────────────────────────────────────────────────────

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: DocColors.text1)),
      backgroundColor: DocColors.red.withValues(alpha: 0.85),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: DocColors.text1)),
      backgroundColor: DocColors.green.withValues(alpha: 0.85),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.document != null;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && mounted) FocusScope.of(context).unfocus();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: DocColors.navy,
          body: Stack(
            children: [
              // Radial glow (top-right, matches home screen)
              Positioned(
                top: -60, right: -40,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      DocColors.gold.withValues(alpha: 0.10),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),

              Column(
                children: [
                  // ── Pinned header ────────────────────────────────────
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: DocColors.navy.withValues(alpha: 0.85),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 20, 12),
                            child: Row(
                              children: [
                                // Back button
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: DocColors.text2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEdit ? 'EDIT DOCUMENT' : 'NEW DOCUMENT',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 2.2,
                                          color: DocColors.gold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isEdit ? 'Update details' : 'Add to vault',
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: 22,
                                          color: DocColors.text1,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Scrollable body ──────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Document Name
                          _SectionLabel(label: 'Document Name'),
                          const SizedBox(height: 8),
                          _PremiumTextField(
                            controller: _nameController,
                            hint: 'e.g., Passport, Driver Licence',
                            icon: Icons.description_outlined,
                          ),
                          const SizedBox(height: 24),

                          // Document Type
                          _SectionLabel(label: 'Document Type'),
                          const SizedBox(height: 10),

                          _DocumentTypeGrid(
                            types: _documentTypes,
                            selected: _selectedDocumentType,
                            onSelect: (t) =>
                                setState(() => _selectedDocumentType = t),
                          ),
                          const SizedBox(height: 24),

                          // File
                          _SectionLabel(label: 'Attach File'),
                          const SizedBox(height: 8),
                          _FilePicker(
                            fileName: _selectedFileName,
                            onTap: _showSourceOptions,
                          ),
                          if (_selectedFilePath != null && _selectedFileName != null) ...[
                            const SizedBox(height: 12),
                            DocumentPreview(
                              filePath: _selectedFilePath!,
                              fileName: _selectedFileName!,
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Expiry Date
                          _SectionLabel(label: 'Expiry Date'),
                          const SizedBox(height: 8),
                          _TapRow(
                            icon: Icons.calendar_today_outlined,
                            iconColor: DocColors.amber,
                            label: 'Expiry Date',
                            value: DateFormat('MMM dd, yyyy').format(_selectedDate),
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 24),

                          // Reminders
                          _SectionLabel(label: 'Reminders'),
                          const SizedBox(height: 8),
                          _ReminderToggle(
                            enabled: _reminderEnabled,
                            onChanged: (v) =>
                                setState(() => _reminderEnabled = v),
                          ),

                          if (_reminderEnabled) ...[
                            const SizedBox(height: 12),
                            _OffsetRow(
                              selectedOffset: _selectedOffset,
                              onChanged: (o) =>
                                  setState(() => _selectedOffset = o),
                            ),
                            const SizedBox(height: 12),
                            _TapRow(
                              icon: Icons.access_time_outlined,
                              iconColor: DocColors.gold,
                              label: 'Notification Time',
                              value: _reminderTime.format(context),
                              onTap: _selectTime,
                            ),
                          ],

                          const SizedBox(height: 36),

                          // Save button
                          _SaveButton(
                            isLoading: _isLoading,
                            isEdit: isEdit,
                            controller: _saveController,
                            onTap: _saveDocument,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Extracted widgets
// ═══════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: GoogleFonts.dmSans(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
      color: DocColors.text3,
    ),
  );
}

// ── Premium text field ─────────────────────────────────────────────────────

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.hint,
    required this.icon,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textCapitalization: TextCapitalization.sentences,
    style: GoogleFonts.dmSans(fontSize: 15, color: DocColors.text1),
    cursorColor: DocColors.gold,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: DocColors.text3),
      prefixIcon: Icon(icon, color: DocColors.text3, size: 18),
      filled: true,
      fillColor: DocColors.navy2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: DocColors.gold.withValues(alpha: 0.4), width: 1.5),
      ),
    ),
  );
}

// ── Document type grid ─────────────────────────────────────────────────────

class _DocumentTypeGrid extends StatelessWidget {
  const _DocumentTypeGrid({
    required this.types,
    required this.selected,
    required this.onSelect,
  });
  final List<(String, String, String)> types;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.zero, // 👈 IMPORTANT
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
    ),
    itemCount: types.length,
    itemBuilder: (context, i) {
      final (emoji, name, _) = types[i];
      final isSelected = selected == name;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelect(name);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected
                ? DocColors.gold.withValues(alpha: 0.15)
                : DocColors.navy2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? DocColors.gold.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? DocColors.gold : DocColors.text2,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── File picker row ────────────────────────────────────────────────────────

class _FilePicker extends StatelessWidget {
  const _FilePicker({required this.fileName, required this.onTap});
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DocColors.navy2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fileName != null
              ? DocColors.green.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: fileName != null
                  ? DocColors.green.withValues(alpha: 0.12)
                  : DocColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              fileName != null
                  ? Icons.check_circle_outline_rounded
                  : Icons.attach_file_rounded,
              color: fileName != null ? DocColors.green : DocColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName ?? 'Tap to attach a file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: fileName != null ? DocColors.text1 : DocColors.text3,
                  ),
                ),
                if (fileName != null)
                  Text(
                    'Tap to change',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: DocColors.text3),
                  )
                else
                  Text(
                    'PDF, JPG, PNG, DOC supported',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: DocColors.text3),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: DocColors.text3, size: 20),
        ],
      ),
    ),
  );
}

// ── Tap row (date / time) ──────────────────────────────────────────────────

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: DocColors.navy2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: DocColors.text3),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: DocColors.text1,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: DocColors.text3, size: 20),
        ],
      ),
    ),
  );
}

// ── Reminder toggle ────────────────────────────────────────────────────────

class _ReminderToggle extends StatelessWidget {
  const _ReminderToggle({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: DocColors.navy2,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: enabled
            ? DocColors.green.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.06),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: DocColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: DocColors.green,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enable Reminders',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DocColors.text1,
                ),
              ),
              Text(
                enabled ? 'Notifications are on' : 'Notifications are off',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: DocColors.text3),
              ),
            ],
          ),
        ),
        Switch(
          value: enabled,
          onChanged: onChanged,
          activeThumbColor: DocColors.green,
          activeTrackColor: DocColors.green.withValues(alpha: 0.25),
          inactiveThumbColor: DocColors.text3,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
        ),
      ],
    ),
  );
}

// ── Reminder offset row ────────────────────────────────────────────────────

class _OffsetRow extends StatelessWidget {
  const _OffsetRow({required this.selectedOffset, required this.onChanged});
  final ReminderOffset selectedOffset;
  final ValueChanged<ReminderOffset> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: DocColors.navy2,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: DocColors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.timer_outlined, color: DocColors.amber, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ReminderOffsetDropdown(
            selectedOffset: selectedOffset,
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}

// ── Save button ────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isLoading,
    required this.isEdit,
    required this.controller,
    required this.onTap,
  });
  final bool isLoading;
  final bool isEdit;
  final AnimationController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => controller.forward(),
    onTapUp: (_) {
      controller.reverse();
      if (!isLoading) onTap();
    },
    onTapCancel: () => controller.reverse(),
    child: ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: isLoading ? DocColors.gold.withValues(alpha: 0.5) : DocColors.gold,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isLoading
              ? []
              : [
            BoxShadow(
              color: DocColors.gold.withValues(alpha: 0.35),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
              AlwaysStoppedAnimation<Color>(DocColors.navy),
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEdit
                    ? Icons.check_rounded
                    : Icons.add_rounded,
                color: DocColors.navy,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Update Document' : 'Add to Vault',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DocColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── Source bottom sheet ────────────────────────────────────────────────────

class _SourceBottomSheet extends StatelessWidget {
  const _SourceBottomSheet({
    required this.onCamera,
    required this.onGallery,
    required this.onFiles,
  });
  final VoidCallback onCamera, onGallery, onFiles;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        decoration: BoxDecoration(
          color: DocColors.navy2.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: DocColors.text3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ATTACH DOCUMENT',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: DocColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _SourceTile(
                  emoji: '📷',
                  label: 'Camera',
                  color: DocColors.green,
                  onTap: onCamera,
                ),
                const SizedBox(width: 12),
                _SourceTile(
                  emoji: '🖼',
                  label: 'Gallery',
                  color: DocColors.amber,
                  onTap: onGallery,
                ),
                const SizedBox(width: 12),
                _SourceTile(
                  emoji: '📁',
                  label: 'Files',
                  color: DocColors.gold,
                  onTap: onFiles,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}