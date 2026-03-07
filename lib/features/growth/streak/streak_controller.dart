import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'streak_state.dart';

class StreakNotifier extends Notifier<StreakState> {
  static const _boxName = 'streak_box';
  static const _keyStreak = 'current_streak';
  static const _keyLastStudyDate = 'last_study_date';
  static const _keyDailyCountDate = 'daily_count_date';
  static const _keyAnsweredToday = 'answered_today_count';

  late final Box _box;

  @override
  StreakState build() {
    _box = Hive.box(_boxName);
    return _computeState();
  }

  StreakState _computeState() {
    final today = _todayString();
    final lastStudyDate =
        (_box.get(_keyLastStudyDate, defaultValue: '') as String).trim();
    final dailyCountDate =
        (_box.get(_keyDailyCountDate, defaultValue: '') as String).trim();
    final answeredToday = dailyCountDate == today
        ? (_box.get(_keyAnsweredToday, defaultValue: 0) as num).toInt()
        : 0;
    final streak = (_box.get(_keyStreak, defaultValue: 0) as num).toInt();

    if (lastStudyDate == today) {
      return StreakState(
        lastStudyDate: lastStudyDate,
        currentStreak: streak,
        completedToday: true,
        answeredToday: answeredToday,
      );
    }
    if (lastStudyDate == _yesterdayString()) {
      return StreakState(
        lastStudyDate: lastStudyDate,
        currentStreak: streak,
        completedToday: false,
        answeredToday: answeredToday,
      );
    }
    return StreakState(
      lastStudyDate: lastStudyDate.isEmpty ? null : lastStudyDate,
      currentStreak: 0,
      completedToday: false,
      answeredToday: answeredToday,
    );
  }

  /// Call when the user completes a study question in Feed or Study mode.
  void recordStudyQuestion() {
    final today = _todayString();
    final previousQualifiedDate =
        (_box.get(_keyLastStudyDate, defaultValue: '') as String).trim();
    final countDate = (_box.get(_keyDailyCountDate, defaultValue: '') as String)
        .trim();

    var answeredToday = countDate == today
        ? (_box.get(_keyAnsweredToday, defaultValue: 0) as num).toInt()
        : 0;

    answeredToday += 1;
    _box.put(_keyDailyCountDate, today);
    _box.put(_keyAnsweredToday, answeredToday);

    var storedStreak = (_box.get(_keyStreak, defaultValue: 0) as num).toInt();
    var completedToday = previousQualifiedDate == today;
    var effectiveLastStudyDate = previousQualifiedDate.isEmpty
        ? null
        : previousQualifiedDate;

    if (!completedToday && answeredToday >= 3) {
      final isConsecutive = previousQualifiedDate == _yesterdayString();
      storedStreak = isConsecutive ? storedStreak + 1 : 1;
      _box.put(_keyStreak, storedStreak);
      _box.put(_keyLastStudyDate, today);
      completedToday = true;
      effectiveLastStudyDate = today;
    }

    state = StreakState(
      lastStudyDate: effectiveLastStudyDate,
      currentStreak: _effectiveStreak(storedStreak, effectiveLastStudyDate),
      completedToday: completedToday,
      answeredToday: answeredToday,
    );
  }

  void reloadFromStorage() {
    state = _computeState();
  }

  int _effectiveStreak(int storedStreak, String? lastStudyDate) {
    if (lastStudyDate == null || lastStudyDate.isEmpty) return 0;
    if (lastStudyDate == _todayString() ||
        lastStudyDate == _yesterdayString()) {
      return storedStreak;
    }
    return 0;
  }

  DateTime currentTime() => DateTime.now();

  String _todayString() => currentTime().toIso8601String().substring(0, 10);
  String _yesterdayString() => currentTime()
      .subtract(const Duration(days: 1))
      .toIso8601String()
      .substring(0, 10);
}

final streakProvider = NotifierProvider<StreakNotifier, StreakState>(
  StreakNotifier.new,
);
