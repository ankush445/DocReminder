import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import '../theme/app_colors.dart';

class DocumentPreview extends StatefulWidget {
  final String filePath;
  final String fileName;

  const DocumentPreview({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<DocumentPreview> {
  bool _isOpening = false;
  DateTime? _lastTapTime;

  String get _extension => widget.filePath.split('.').last.toLowerCase();

  // ── File type mappings ────────────────────────────────────────────────

  IconData get _icon {
    switch (_extension) {
      case 'pdf':  return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':  return Icons.image_outlined;
      case 'doc':
      case 'docx': return Icons.description_outlined;
      case 'xls':
      case 'xlsx': return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx': return Icons.slideshow_outlined;
      default:     return Icons.insert_drive_file_outlined;
    }
  }

  Color get _color {
    switch (_extension) {
      case 'pdf':  return AppColors.error;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':  return const Color(0xFFB06DD4);  // soft purple
      case 'doc':
      case 'docx': return const Color(0xFF5B9BD5);  // word blue
      case 'xls':
      case 'xlsx': return AppColors.success;
      case 'ppt':
      case 'pptx': return AppColors.warning;
      default:     return AppColors.textTertiary;
    }
  }

  // ── Open file ─────────────────────────────────────────────────────────

  Future<void> _openFile() async {
    if (_isOpening) {
      setState(() => _isOpening = false);
      return;
    }
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 500) {
      return;
    }
    _lastTapTime = now;

    HapticFeedback.selectionClick();
    setState(() => _isOpening = true);

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        if (mounted) _showSnackbar('File not found. It may have been moved or deleted.', isError: true);
        return;
      }
      final result = await OpenFile.open(widget.filePath);
      if (mounted && result.type != ResultType.done) {
        _showSnackbar(
          result.type == ResultType.noAppToOpen
              ? 'No app available to open this file type'
              : 'Error opening file: ${result.message}',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) _showSnackbar('Error: $e', isError: true);
      if (kDebugMode) debugPrint('DocumentPreview error: $e');
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: AppColors.lightBackground)),
      backgroundColor: isError
          ? AppColors.error.withValues(alpha: 0.85)
          : AppColors.success.withValues(alpha: 0.85),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openFile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightBackground2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // File type icon box
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _color, size: 26),
            ),
            const SizedBox(width: 14),

            // File name + extension badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _color.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          _extension.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'File Preview',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Open button
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _isOpening
                    ? _color.withValues(alpha: 0.08)
                    : _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _color.withValues(alpha: 0.2)),
              ),
              child: _isOpening
                  ? Padding(
                padding: const EdgeInsets.all(9),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
              )
                  : Icon(
                Icons.open_in_new_rounded,
                color: _color,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}