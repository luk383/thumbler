import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _boxName = 'notifications_box';
const _keyEnabled = 'reminder_enabled';
const _keyHour = 'reminder_hour';
const _keyMinute = 'reminder_minute';
const _dailyId = 1;

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

  /// Request permission (iOS / Android 13+).
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

  /// Schedule a daily reminder at [hour]:[minute].
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required bool italian,
  }) async {
    await _plugin.cancel(_dailyId);

    final title = italian ? 'Wolf Lab — Tempo di studiare 🐺' : 'Wolf Lab — Time to study 🐺';
    final body = italian
        ? 'Mantieni la tua streak. Una domanda alla volta.'
        : 'Keep your streak going. One question at a time.';

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wolf_lab_daily',
          'Studio giornaliero',
          channelDescription: 'Promemoria quotidiano per studiare',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyReminder() => _plugin.cancel(_dailyId);
}

// ── Hive-backed settings ─────────────────────────────────────────────────────

class NotificationSettings {
  const NotificationSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  static Box get _box => Hive.box(_boxName);

  static NotificationSettings load() => NotificationSettings(
        enabled: _box.get(_keyEnabled, defaultValue: false) as bool,
        hour: _box.get(_keyHour, defaultValue: 20) as int,
        minute: _box.get(_keyMinute, defaultValue: 0) as int,
      );

  Future<void> save() async {
    await _box.put(_keyEnabled, enabled);
    await _box.put(_keyHour, hour);
    await _box.put(_keyMinute, minute);
  }

  NotificationSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

// ── Provider ─────────────────────────────────────────────────────────────────

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() => NotificationSettings.load();

  Future<void> setEnabled(bool enabled, {required bool italian}) async {
    state = state.copyWith(enabled: enabled);
    await state.save();
    if (enabled) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyReminder(
        hour: state.hour,
        minute: state.minute,
        italian: italian,
      );
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }

  Future<void> setTime(int hour, int minute, {required bool italian}) async {
    state = state.copyWith(hour: hour, minute: minute);
    await state.save();
    if (state.enabled) {
      await NotificationService.scheduleDailyReminder(
        hour: hour,
        minute: minute,
        italian: italian,
      );
    }
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);
