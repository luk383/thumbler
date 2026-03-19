import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _channelId = 'wolf_lab_channel';
const _channelName = 'Wolf Lab';
const _dailyId = 1;
const _streakId = 2;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
  }

  /// Request notification permission (iOS / Android 13+).
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    if (iOS != null) {
      return await iOS.requestPermissions(alert: true, sound: true) ?? false;
    }
    return true;
  }

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  static tz.TZDateTime _nextOccurrence(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedule a daily study reminder at [time]. ID = 1.
  static Future<void> scheduleStudyReminder(TimeOfDay time) async {
    await _plugin.cancel(_dailyId);
    await _plugin.zonedSchedule(
      _dailyId,
      'Wolf Lab — Tempo di studiare 🐺',
      'Mantieni la tua streak. Una domanda alla volta.',
      _nextOccurrence(time),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelStudyReminder() => _plugin.cancel(_dailyId);

  /// Schedule a daily streak protection reminder at [time]. ID = 2.
  static Future<void> scheduleStreakProtection(TimeOfDay time) async {
    await _plugin.cancel(_streakId);
    await _plugin.zonedSchedule(
      _streakId,
      'Wolf Lab — Non perdere la tua streak! 🔥',
      'Hai ancora tempo. Completa almeno una domanda oggi.',
      _nextOccurrence(time),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelStreakProtection() => _plugin.cancel(_streakId);

  /// Schedule a daily habit reminder. ID = habitId.hashCode.abs() % 9000 + 100.
  static Future<void> scheduleHabitReminder(
    String habitId,
    String habitName,
    String emoji,
    TimeOfDay time,
  ) async {
    final id = habitId.hashCode.abs() % 9000 + 100;
    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      '$emoji $habitName',
      'Ricordati di completare la tua abitudine oggi!',
      _nextOccurrence(time),
      _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelHabitReminder(String habitId) {
    final id = habitId.hashCode.abs() % 9000 + 100;
    return _plugin.cancel(id);
  }

  static Future<void> cancelAllHabitReminders(List<String> habitIds) async {
    for (final id in habitIds) {
      await cancelHabitReminder(id);
    }
  }

  // ── Legacy compatibility ──────────────────────────────────────────────────

  /// @deprecated Use [scheduleStudyReminder] instead.
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required bool italian,
  }) =>
      scheduleStudyReminder(TimeOfDay(hour: hour, minute: minute));

  static Future<void> cancelDailyReminder() => cancelStudyReminder();
}
