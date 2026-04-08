import 'package:document_reminder/services/file_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_model.dart';
import '../models/document_status.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'storage_provider.dart';
import 'notification_provider.dart';

final documentsProvider =
    StateNotifierProvider<DocumentNotifier, List<DocumentModel>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return DocumentNotifier(storageService, notificationService);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredDocumentsProvider =
    Provider<List<DocumentModel>>((ref) {
  final documents = ref.watch(documentsProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return documents;
  }

  return documents
      .where((doc) =>
          doc.documentName.toLowerCase().contains(query.toLowerCase()))
      .toList();
});

final documentsByStatusProvider =
    Provider<Map<DocumentStatus, List<DocumentModel>>>((ref) {
  // Use filteredDocumentsProvider to apply search filter first
  final documents = ref.watch(filteredDocumentsProvider);

  final valid = <DocumentModel>[];
  final expiringSoon = <DocumentModel>[];
  final expired = <DocumentModel>[];

  for (final doc in documents) {
    if (doc.isExpired) {
      expired.add(doc);
    } else if (doc.isExpiringsoon) {
      expiringSoon.add(doc);
    } else {
      valid.add(doc);
    }
  }

  return {
    DocumentStatus.valid: valid,
    DocumentStatus.expiringSoon: expiringSoon,
    DocumentStatus.expired: expired,
  };
});

class DocumentNotifier extends StateNotifier<List<DocumentModel>> {
  final StorageService _storageService;
  final NotificationService _notificationService;
  final FileService _fileService = FileService();

  DocumentNotifier(this._storageService, this._notificationService)
      : super([]) {
    _loadDocuments();
  }

  void _loadDocuments() {
    state = _storageService.getAllDocuments();
  }

  Future<void> addDocument(DocumentModel document) async {
    await _storageService.addDocument(document);
    if (document.reminderEnabled) {
      await _notificationService.scheduleDocumentReminder(document);
    }
    _loadDocuments();
  }

  Future<void> updateDocument(DocumentModel document) async {
    await _storageService.updateDocument(document);
    if (document.reminderEnabled) {
      await _notificationService.scheduleDocumentReminder(document);
    } else {
      if (document.notificationId != null) {
        await _notificationService.cancelNotificationById(document.notificationId!);
      }
    }
    _loadDocuments();
  }

  Future<void> deleteDocument(String id) async {
    final document = _storageService.getDocument(id);

    if (document != null) {
      // Cancel notification
      if (document.notificationId != null) {
        await _notificationService
            .cancelNotificationById(document.notificationId!);
      }

      //  Delete file safely
      try {
        await _fileService.deleteFile(document.filePath);
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    }
    //  Delete record
    await _storageService.deleteDocument(id);

    _loadDocuments();
  }

  DocumentModel? getDocument(String id) {
    return _storageService.getDocument(id);
  }
}
