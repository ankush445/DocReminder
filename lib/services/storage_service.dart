import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/document_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  late Box<DocumentModel> _documentBox;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DocumentModelAdapter());
    _documentBox = await Hive.openBox<DocumentModel>('documents');
  }

  Future<void> addDocument(DocumentModel document) async {
    await _documentBox.put(document.id, document);
  }

  Future<void> updateDocument(DocumentModel document) async {
    await _documentBox.put(document.id, document);
  }

  Future<void> deleteDocument(String id) async {
    await _documentBox.delete(id);
  }

  DocumentModel? getDocument(String id) {
    return _documentBox.get(id);
  }

  List<DocumentModel> getAllDocuments() {
    return _documentBox.values.toList();
  }

  List<DocumentModel> searchDocuments(String query) {
    return _documentBox.values
        .where((doc) =>
            doc.documentName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<String> getAppDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Box<DocumentModel> get documentBox => _documentBox;
}
