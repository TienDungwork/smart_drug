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
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> scheduleReminder(MedicineSchedule schedule) async {
    if (schedule.isDaily) {
      await _scheduleDailyReminder(schedule);
      return;
    }
    await _scheduleOneTimeReminder(schedule);
  }

  Future<void> _scheduleDailyReminder(MedicineSchedule schedule) async {
    final tz.TZDateTime scheduledDate =
        _nextInstanceOfTime(schedule.hour, schedule.minute);
    final NotificationDetails details = _buildNotificationDetails();

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

  Future<void> _scheduleOneTimeReminder(MedicineSchedule schedule) async {
    final DateTime? specificDate = schedule.specificDate;
    if (specificDate == null) {
      return;
    }

    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      specificDate.year,
      specificDate.month,
      specificDate.day,
      schedule.hour,
      schedule.minute,
    );

    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      return;
    }

    final NotificationDetails details = _buildNotificationDetails();

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
      );
    }
  }

  NotificationDetails _buildNotificationDetails() {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    return details;
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
      await scheduleReminder(schedule);
    }
  }
}
