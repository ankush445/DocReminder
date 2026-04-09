import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileService {
  static final FileService _instance = FileService._internal();
  final ImagePicker _imagePicker = ImagePicker();

  factory FileService() {
    return _instance;
  }

  FileService._internal();

  Future<String?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking file: $e');
      }
      return null;
    }
  }

  Future<String?> openCamera() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        return image.path; // temp path
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Camera error: $e');
      }
      return null;
    }
  }

  Future<String?> pickFromGallery() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo != null) {
        if (kDebugMode) {
          debugPrint('Gallery photo selected: ${photo.path}');
        }
        return photo.path;
      } else {
        if (kDebugMode) {
          debugPrint('Gallery cancelled by user');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking from gallery: $e');
      }
      return null;
    }
  }

  Future<String> copyFileToAppDirectory(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(sourcePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final newPath = path.join(appDir.path, 'documents', newFileName);

      // Create documents directory if it doesn't exist
      final documentsDir = Directory(path.join(appDir.path, 'documents'));
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
        if (kDebugMode) {
          debugPrint('Created documents directory: ${documentsDir.path}');
        }
      }

      // Verify source file exists before copying
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        if (kDebugMode) {
          debugPrint('Source file does not exist: $sourcePath');
        }
        throw Exception('Source file not found: $sourcePath');
      }

      // Copy the file
      final newFile = await sourceFile.copy(newPath);

      // Verify the file was copied successfully
      if (!await newFile.exists()) {
        if (kDebugMode) {
          debugPrint(
            'File copy failed - destination file does not exist: $newPath',
          );
        }
        throw Exception('File copy failed');
      }

      if (kDebugMode) {
        debugPrint('File successfully copied to: $newPath');
        debugPrint('File size: ${await newFile.length()} bytes');
      }

      return path.basename(newFile.path);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error copying file: $e');
      }
      rethrow;
    }
  }

  Future<bool> fileExists(String filePath) async {
    try {
      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteFile(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fullPath = path.join(dir.path, 'documents', fileName);

      final file = File(fullPath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  String getFileName(String filePath) {
    return path.basename(filePath);
  }

  Future<String> getFullPath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return path.join(dir.path, 'documents', fileName);
  }

  String getFileExtension(String filePath) {
    return path.extension(filePath).replaceFirst('.', '').toUpperCase();
  }
}
