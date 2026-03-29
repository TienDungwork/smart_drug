import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine_schedule.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _channelId = 'medicine_reminder_channel';
  static const String _channelName = 'Nhắc uống thuốc';
  static const String _channelDescription =
      'Thông báo nhắc nhở uống thuốc đúng giờ';

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidInitSettings);

    await _plugin.initialize(settings);
    await _requestAndroidNotificationPermission();

    _isInitialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final String timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> _requestAndroidNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyReminder(MedicineSchedule schedule) async {
    final tz.TZDateTime scheduledDate =
        _nextInstanceOfTime(schedule.hour, schedule.minute);

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        schedule.notificationId,
        'Nhắc uống thuốc',
        'Đến giờ uống ${schedule.medicineName}',
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        schedule.notificationId,
        'Nhắc uống thuốc',
        'Đến giờ uống ${schedule.medicineName}',
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelScheduleNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<void> syncAllSchedules({
    required List<MedicineSchedule> schedules,
    required bool notificationsEnabled,
  }) async {
    await cancelAllNotifications();

    if (!notificationsEnabled) {
      return;
    }

    for (final MedicineSchedule schedule in schedules) {
      await scheduleDailyReminder(schedule);
    }
  }
}
