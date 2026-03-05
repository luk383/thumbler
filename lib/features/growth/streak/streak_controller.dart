import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'streak_state.dart';

class StreakNotifier extends Notifier<StreakState> {
  static const _boxName = 'streak_box';
  static const _keyStreak = 'streak';
  static const _keyLastActive = 'last_active';

  late final Box _box;

  @override
  StreakState build() {
    _box = Hive.box(_boxName);
    return _computeState();
  }

  StreakState _computeState() {
    final today = _todayString();
    final lastActive = _box.get(_keyLastActive, defaultValue: '') as String;
    final streak = (_box.get(_keyStreak, defaultValue: 0) as num).toInt();

    if (lastActive == today) {
      return StreakState(currentStreak: streak, completedToday: true);
    }
    if (lastActive == _yesterdayString()) {
      return StreakState(currentStreak: streak, completedToday: false);
    }
    // Streak broken — reset but don't persist until next activity.
    return const StreakState(currentStreak: 0, completedToday: false);
  }

  /// Call whenever the user engages with the app (e.g. page change).
  void recordActivity() {
    final today = _todayString();
    final lastActive = _box.get(_keyLastActive, defaultValue: '') as String;
    if (lastActive == today) return; // already recorded today

    final previousStreak =
        (_box.get(_keyStreak, defaultValue: 0) as num).toInt();
    final isConsecutive = lastActive == _yesterdayString();
    final newStreak = isConsecutive ? previousStreak + 1 : 1;

    _box.put(_keyStreak, newStreak);
    _box.put(_keyLastActive, today);
    state = StreakState(currentStreak: newStreak, completedToday: true);
  }

  String _todayString() => DateTime.now().toIso8601String().substring(0, 10);
  String _yesterdayString() =>
      DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
}

final streakProvider =
    NotifierProvider<StreakNotifier, StreakState>(StreakNotifier.new);
