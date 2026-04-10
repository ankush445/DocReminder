/// App-wide constants for the DocReminder application
class AppConstants {
  // Notification
  static const String notificationChannelId = 'document_reminder_channel';
  static const String notificationChannelName = 'Document Reminders';
  static const String notificationChannelDescription =
      'Notifications for document expiry reminders';

  // Animation durations (standardized)
  static const Duration animationFast = Duration(milliseconds: 120);
  static const Duration animationNormal = Duration(milliseconds: 200);
  static const Duration animationSlow = Duration(milliseconds: 400);
  static const Duration animationVerySlow = Duration(milliseconds: 600);

  // Spacing scale (8px grid system)
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;

  // Reminder defaults
  static const int defaultReminderOffsetDays = 7;
  static const int defaultReminderHour = 9;
  static const int defaultReminderMinute = 0;

  // Search debounce duration
  static const Duration searchDebounceDuration = Duration(milliseconds: 300);

  // File operations
  static const String documentsBoxName = 'documents';
  static const String appName = 'DocReminder';
}
