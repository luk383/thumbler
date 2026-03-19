import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../app/services/notifications/notification_service.dart';
import '../../habits/domain/habit.dart';
import '../domain/notification_settings.dart';

const _boxName = 'notifications_box';
const _settingsKey = 'settings';

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  Box get _box => Hive.box(_boxName);

  @override
  NotificationSettings build() {
    final raw = _box.get(_settingsKey);
    if (raw is Map) {
      return NotificationSettings.fromMap(raw);
    }
    return NotificationSettings.defaults;
  }

  Future<void> _save(NotificationSettings settings) async {
    state = settings;
    await _box.put(_settingsKey, settings.toMap());
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  Future<void> setStudyReminder(bool enabled, String time) async {
    final updated = state.copyWith(
      studyReminderEnabled: enabled,
      studyReminderTime: time,
    );
    await _save(updated);
    if (enabled) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleStudyReminder(_parseTime(time));
    } else {
      await NotificationService.cancelStudyReminder();
    }
  }

  Future<void> setStreakProtection(bool enabled, String time) async {
    final updated = state.copyWith(
      streakProtectionEnabled: enabled,
      streakProtectionTime: time,
    );
    await _save(updated);
    if (enabled) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleStreakProtection(_parseTime(time));
    } else {
      await NotificationService.cancelStreakProtection();
    }
  }

  Future<void> scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime == null) return;
    await NotificationService.scheduleHabitReminder(
      habit.id,
      habit.name,
      habit.emoji,
      _parseTime(habit.reminderTime!),
    );
  }

  Future<void> cancelHabitReminder(Habit habit) async {
    await NotificationService.cancelHabitReminder(habit.id);
  }
}
