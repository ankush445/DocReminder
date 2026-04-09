import 'package:hive/hive.dart';
import 'reminder_offset.dart';

part 'document_model.g.dart';

@HiveType(typeId: 0)
class DocumentModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String documentName;

  @HiveField(2)
  late String filePath;

  @HiveField(3)
  late DateTime expiryDate;

  @HiveField(4)
  late bool reminderEnabled;

  @HiveField(5)
  late int reminderOffsetDays;

  @HiveField(6)
  late int? notificationId;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  late int reminderHour;

  @HiveField(9)
  late int reminderMinute;

  @HiveField(10)
  late String documentType;


  DocumentModel({
    required this.id,
    required this.documentName,
    required this.filePath,
    required this.expiryDate,
    this.reminderEnabled = true,
    this.reminderOffsetDays = 7,
    this.notificationId,
    DateTime? createdAt,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.documentType = "Other"

  }) {
    this.createdAt = createdAt ?? DateTime.now();
  }

  ReminderOffset get reminderOffset =>
      ReminderOffset.fromDays(reminderOffsetDays);

  /// Get today's date at midnight (00:00:00)
  DateTime _getTodayAtMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get expiry date at midnight (00:00:00)
  DateTime _getExpiryDateAtMidnight() {
    return DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
  }

  /// Check if document is expired (expiry date is before today)
  bool get isExpired {
    final today = _getTodayAtMidnight();
    final expiry = _getExpiryDateAtMidnight();
    return expiry.isBefore(today);
  }

  /// Check if document is expiring soon (within 7 days from today, not including today)
  bool get isExpiringsoon {
    final today = _getTodayAtMidnight();
    final expiry = _getExpiryDateAtMidnight();
    final sevenDaysFromNow = today.add(const Duration(days: 7));

    // Expiring soon if expiry is after today and before/on 7 days from now
    return expiry.isAfter(today) && expiry.isBefore(sevenDaysFromNow);
  }

  /// Get the number of days until expiry (0 = today, 1 = tomorrow, etc.)
  int get daysUntilExpiry {
    final today = _getTodayAtMidnight();
    final expiry = _getExpiryDateAtMidnight();
    return expiry.difference(today).inDays;
  }

  String get status {
    if (isExpired) return 'Expired';
    if (isExpiringsoon) return 'Expiring Soon';
    return 'Valid';
  }

  DocumentModel copyWith({
    String? id,
    String? documentName,
    String? filePath,
    DateTime? expiryDate,
    bool? reminderEnabled,
    int? reminderOffsetDays,
    int? notificationId,
    DateTime? createdAt,
    int? reminderHour,
    int? reminderMinute,
    String? documentType,

  }) {
    return DocumentModel(
      id: id ?? this.id,
      documentName: documentName ?? this.documentName,
      filePath: filePath ?? this.filePath,
      expiryDate: expiryDate ?? this.expiryDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderOffsetDays: reminderOffsetDays ?? this.reminderOffsetDays,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      documentType: documentType ?? this.documentType,

    );
  }
}
