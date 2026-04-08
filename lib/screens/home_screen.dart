import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_status.dart';
import '../providers/document_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import 'add_edit_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  DocumentStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Dismiss keyboard when screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dismissKeyboard();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocuments = ref.watch(filteredDocumentsProvider);
    final documentsByStatus = ref.watch(documentsByStatusProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get documents based on selected filter
    List<dynamic> displayedDocuments;
    String filterTitle;

    switch (_selectedStatus) {
      case DocumentStatus.valid:
        displayedDocuments = documentsByStatus[DocumentStatus.valid] ?? [];
        filterTitle = 'Valid Documents';
        break;
      case DocumentStatus.expiringSoon:
        displayedDocuments = documentsByStatus[DocumentStatus.expiringSoon] ?? [];
        filterTitle = 'Expiring Soon';
        break;
      case DocumentStatus.expired:
        displayedDocuments = documentsByStatus[DocumentStatus.expired] ?? [];
        filterTitle = 'Expired Documents';
        break;
      default:
        displayedDocuments = filteredDocuments;
        filterTitle = 'All Documents';
    }

    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'DocReminder',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          elevation: 0,
          shadowColor: Colors.black26,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All',
                      count: filteredDocuments.length,
                      isSelected: _selectedStatus == null,
                      onTap: () {
                        setState(() => _selectedStatus = null);
                      },
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Valid',
                      count: documentsByStatus[DocumentStatus.valid]?.length ?? 0,
                      isSelected: _selectedStatus == DocumentStatus.valid,
                      onTap: () {
                        setState(() => _selectedStatus = DocumentStatus.valid);
                      },
                      isDarkMode: isDarkMode,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Expiring Soon',
                      count: documentsByStatus[DocumentStatus.expiringSoon]?.length ?? 0,
                      isSelected: _selectedStatus == DocumentStatus.expiringSoon,
                      onTap: () {
                        setState(() => _selectedStatus = DocumentStatus.expiringSoon);
                      },
                      isDarkMode: isDarkMode,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Expired',
                      count: documentsByStatus[DocumentStatus.expired]?.length ?? 0,
                      isSelected: _selectedStatus == DocumentStatus.expired,
                      onTap: () {
                        setState(() => _selectedStatus = DocumentStatus.expired);
                      },
                      isDarkMode: isDarkMode,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Document List
            Expanded(
              child: _buildDocumentList(displayedDocuments, filterTitle, isDarkMode),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _dismissKeyboard();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddEditScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Document'),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? Colors.blue).withValues(alpha: 0.2)
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          border: Border.all(
            color: isSelected ? (color ?? Colors.blue) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? (color ?? Colors.blue) : null,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? (color ?? Colors.blue) : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(List<dynamic> documents, String title, bool isDarkMode) {
    if (documents.isEmpty) {
      return EmptyState(
        title: 'No $title',
        message: 'Add your first document to get started',
        icon: Icons.document_scanner,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentCard(
          document: document,
          onEdit: () {
            _dismissKeyboard();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddEditScreen(document: document),
              ),
            );
          },
          onDelete: () {
            ref.read(documentsProvider.notifier).deleteDocument(document.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Document deleted'),
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[700],
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    // Undo functionality can be added here
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
