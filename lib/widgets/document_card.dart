import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document_model.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getStatusColor() {
    if (document.isExpired) {
      return Colors.red;
    } else if (document.isExpiringsoon) {
      return Colors.orange;
    }
    return Colors.green;
  }

  IconData _getStatusIcon() {
    if (document.isExpired) {
      return Icons.error;
    } else if (document.isExpiringsoon) {
      return Icons.warning;
    }
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = _getStatusColor();
    final daysUntilExpiry = document.daysUntilExpiry;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(document.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getStatusIcon(), color: statusColor, size: 28),
            ),
            title: Text(
              document.documentName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expires: ${dateFormat.format(document.expiryDate)}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    document.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (daysUntilExpiry >= 0 && daysUntilExpiry <= 7)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      daysUntilExpiry == 0
                          ? 'Expires today!'
                          : 'Expires in $daysUntilExpiry day${daysUntilExpiry > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            onTap: onEdit,
          ),
        ),
      ),
    );
  }
}
