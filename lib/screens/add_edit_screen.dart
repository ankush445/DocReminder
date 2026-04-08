import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';
import '../models/reminder_offset.dart';
import '../providers/document_provider.dart';
import '../services/file_service.dart';
import '../widgets/reminder_offset_dropdown.dart';
import '../widgets/document_preview.dart';

class AddEditScreen extends ConsumerStatefulWidget {
  final DocumentModel? document;

  const AddEditScreen({super.key, this.document});

  @override
  ConsumerState<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends ConsumerState<AddEditScreen> {
  late TextEditingController _nameController;
  late DateTime _selectedDate;
  late TimeOfDay _reminderTime;
  late bool _reminderEnabled;
  late ReminderOffset _selectedOffset;
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isLoading = false;

  final FileService _fileService = FileService();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.document?.documentName ?? '',
    );

    _selectedDate =
        widget.document?.expiryDate ?? DateTime.now().add(const Duration(days: 1));

    _reminderTime = widget.document != null
        ? TimeOfDay(
      hour: widget.document!.reminderHour,
      minute: widget.document!.reminderMinute,
    )
        : const TimeOfDay(hour: 9, minute: 0);

    _reminderEnabled = widget.document?.reminderEnabled ?? true;

    _selectedOffset =
        widget.document?.reminderOffset ?? ReminderOffset.sevenDays;

    _selectedFileName = widget.document != null
        ? _fileService.getFileName(widget.document!.filePath)
        : null;

    // ✅ Call async method separately
    _loadFilePath();
  }
  Future<void> _loadFilePath() async {
    if (widget.document?.filePath != null) {
      final fullPath =
      await _fileService.getFullPath(widget.document!.filePath);

      if (mounted) {
        setState(() {
          _selectedFilePath = fullPath;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      if (!mounted) return;
      
      FocusScope.of(context).unfocus();
      
      final filePath = await _fileService.pickFile();
      
      if (mounted && filePath != null) {
        setState(() {
          _selectedFilePath = filePath;
          _selectedFileName = _fileService.getFileName(filePath);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error picking file: $e');
      }
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      if (!mounted) return;
      
      final filePath = await _fileService.openCamera();
      
      if (mounted && filePath != null) {
        setState(() {
          _selectedFilePath = filePath;
          _selectedFileName = _fileService.getFileName(filePath);
        });
      } else if (mounted && filePath == null) {
        // Permission was denied, show message
        _showErrorSnackBar('Camera permission denied. Please enable it in settings.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error capturing from camera: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      if (!mounted) return;
      
      final filePath = await _fileService.pickFromGallery();
      
      if (mounted && filePath != null) {
        setState(() {
          _selectedFilePath = filePath;
          _selectedFileName = _fileService.getFileName(filePath);
        });
      } else if (mounted && filePath == null) {
        // Permission was denied, show message
        _showErrorSnackBar('Photo permission denied. Please enable it in settings.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error picking from gallery: $e');
      }
    }
  }

  void _showSourceOptions() {
    FocusScope.of(context).unfocus();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Document Source',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (mounted) {
                      await _captureFromCamera();
                    }
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (mounted) {
                      await _pickFromGallery();
                    }
                  },
                ),
                _buildSourceOption(
                  icon: Icons.attach_file,
                  label: 'Files',
                  color: Colors.orange,
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (mounted) {
                      await _pickFile();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    // Dismiss keyboard before opening date picker
    FocusScope.of(context).unfocus();
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    // Dismiss keyboard before opening time picker
    FocusScope.of(context).unfocus();
    
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Please enter document name');
      return;
    }

    if (_selectedFilePath == null) {
      _showErrorSnackBar('Please select a file');
      return;
    }

    // Dismiss keyboard before saving
    if (mounted) {
      FocusScope.of(context).unfocus();
    }

    setState(() => _isLoading = true);

    try {
      String finalFilePath = _selectedFilePath!;

      // Copy file to app directory if it's a new file
      if (widget.document == null ||
          widget.document!.filePath != _selectedFilePath) {
        finalFilePath = await _fileService.copyFileToAppDirectory(
          _selectedFilePath!,
        );
      }

      if (widget.document == null) {
        // Add new document
        final newDocument = DocumentModel(
          id: const Uuid().v4(),
          documentName: _nameController.text,
          filePath: finalFilePath,
          expiryDate: _selectedDate,
          reminderEnabled: _reminderEnabled,
          reminderOffsetDays: _selectedOffset.days,
          reminderHour: _reminderTime.hour,
          reminderMinute: _reminderTime.minute,
        );
        await ref.read(documentsProvider.notifier).addDocument(newDocument);
      } else {
        // Update existing document
        final updatedDocument = widget.document!.copyWith(
          documentName: _nameController.text,
          filePath: finalFilePath,
          expiryDate: _selectedDate,
          reminderEnabled: _reminderEnabled,
          reminderOffsetDays: _selectedOffset.days,
          reminderHour: _reminderTime.hour,
          reminderMinute: _reminderTime.minute,
        );
        await ref
            .read(documentsProvider.notifier)
            .updateDocument(updatedDocument);
      }

      if (mounted) {
        // Dismiss keyboard and navigate
        FocusScope.of(context).unfocus();
        
        // Use a small delay to ensure keyboard is dismissed before navigation
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessSnackBar(
            widget.document == null
                ? 'Document added successfully'
                : 'Document updated successfully',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Dismiss keyboard when back button is pressed
          if (mounted) {
            FocusScope.of(context).unfocus();
          }
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.document == null ? 'Add Document' : 'Edit Document'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document Name
                _buildSectionTitle('Document Name', isDarkMode),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Document Name',
                    hintText: 'e.g., Passport, Driver License',
                    prefixIcon: const Icon(Icons.description),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

                // File Picker
                _buildSectionTitle('Select File', isDarkMode),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showSourceOptions,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.attach_file, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFileName ?? 'Tap to select file',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedFileName != null
                                      ? (isDarkMode ? Colors.white : Colors.black)
                                      : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ),
                              if (_selectedFileName != null)
                                Text(
                                  'PDF, JPG, PNG, DOC, DOCX',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: isDarkMode ? Colors.grey[600] : Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Document Preview
                if (_selectedFileName != null)
                  Column(
                    children: [
                      DocumentPreview(
                        filePath: _selectedFilePath!,
                        fileName: _selectedFileName!,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // Expiry Date
                _buildSectionTitle('Expiry Date', isDarkMode),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_today, color: Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: isDarkMode ? Colors.grey[600] : Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Reminder Toggle
                _buildSectionTitle('Reminders', isDarkMode),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.notifications, color: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Enable Reminders',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: (value) {
                          setState(() => _reminderEnabled = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Reminder Offset (visible only if reminder is enabled)
                if (_reminderEnabled)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Remind me before', isDarkMode),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                        ),
                        child: ReminderOffsetDropdown(
                          selectedOffset: _selectedOffset,
                          onChanged: (offset) {
                            setState(() => _selectedOffset = offset);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reminder Time
                      _buildSectionTitle('Reminder Time', isDarkMode),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.access_time, color: Colors.purple),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notification Time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _reminderTime.format(context),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: isDarkMode ? Colors.grey[600] : Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDocument,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.document == null ? 'Add Document' : 'Update Document',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.grey[400] : Colors.grey,
      ),
    );
  }
}
