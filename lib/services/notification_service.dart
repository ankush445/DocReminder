import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/document_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  static const String _notificationChannelId = 'document_reminder_channel';

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  Future<void> initialize() async {
    try {
      // ✅ Android initialization
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // ✅ iOS initialization
      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      // ✅ Combine both (CORRECT WAY)
      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // ✅ Initialize plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // ✅ Create channel (Android)
      await _createNotificationChannel();

      // ✅ Request permissions
      await _requestPermissions();
    } catch (e) {
      _logError('Notification initialization failed', e);
    }
  }

  Future<void> _createNotificationChannel() async {
    try {
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          _notificationChannelId,
          'Document Reminders',
          description: 'Notifications for document expiry reminders',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    } catch (e) {
      _logError('Failed to create notification channel', e);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Only request notification permission on Android 13+
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }

        // Request alarm permission on Android 12+
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      } else if (Platform.isIOS) {
        // Request iOS permissions
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (e) {
      _logError('Failed to request permissions', e);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  Future<int> _getNextNotificationId() async {
    final notifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    if (notifications.isEmpty) return 1;
    return notifications.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<bool> scheduleDocumentReminder(DocumentModel document) async {
    try {
      if (!document.reminderEnabled) {
        await cancelNotificationById(document.notificationId ?? 0);
        return true;
      }

      // Cancel existing notification
      if (document.notificationId != null) {
        try {
          await _flutterLocalNotificationsPlugin
              .cancel(document.notificationId!);
        } catch (e) {
          _logError('Failed to cancel existing notification', e);
        }
      }

      final now = DateTime.now();
      final expiryDate = document.expiryDate;

      // If document is already expired, don't schedule notifications
      if (expiryDate.isBefore(now)) {
        return true;
      }

      // Calculate when reminders should start
      final reminderStartDate = expiryDate
          .subtract(Duration(days: document.reminderOffset.days));

      // Determine the first notification date
      DateTime firstNotificationDate;
      
      if (reminderStartDate.isBefore(now)) {
        // Reminder period has already started, use today
        firstNotificationDate = DateTime(
          now.year,
          now.month,
          now.day,
          document.reminderHour,
          document.reminderMinute,
        );
        
        // If today's time has already passed, start from tomorrow
        if (firstNotificationDate.isBefore(now)) {
          firstNotificationDate = firstNotificationDate.add(const Duration(days: 1));
        }
      } else {
        // Reminder period hasn't started yet, use the reminder start date
        firstNotificationDate = DateTime(
          reminderStartDate.year,
          reminderStartDate.month,
          reminderStartDate.day,
          document.reminderHour,
          document.reminderMinute,
        );
      }

      // Schedule daily notifications from first notification date until expiry date
      final notificationId = await _getNextNotificationId();
      
      final tzDateTime = tz.TZDateTime.from(firstNotificationDate, tz.local);
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Document Reminder',
        '${document.documentName} expires on ${_formatDate(expiryDate)}',
        tzDateTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            'Document Reminders',
            channelDescription: 'Notifications for document expiry reminders',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
      document.notificationId = notificationId;
      return true;
    } catch (e) {
      _logError('Failed to schedule notification for ${document.documentName}', e);
      return false;
    }
  }

  Future<bool> cancelNotificationById(int notificationId) async {
    try {
      if (notificationId > 0) {
        await _flutterLocalNotificationsPlugin.cancel(notificationId);
        return true;
      }
      return true;
    } catch (e) {
      _logError('Failed to cancel notification with ID $notificationId', e);
      return false;
    }
  }

  void _logError(String message, dynamic error) {
    // Log error for debugging
    // In production, you might want to send this to a logging service
    // Using debugPrint instead of print to avoid production warnings
    if (kDebugMode) {
      debugPrint('NotificationService Error: $message');
      debugPrint('Error details: $error');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
