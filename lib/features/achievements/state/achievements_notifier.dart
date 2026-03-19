import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../goals/state/goals_notifier.dart';
import '../../habits/state/habits_notifier.dart';
import '../../journal/state/journal_notifier.dart';
import '../../reading/state/reading_notifier.dart';
import '../../reading/domain/reading_item.dart';
import '../../reflection/state/reflection_notifier.dart';
import '../../growth/streak/streak_notifier.dart';
import '../../pomodoro/state/pomodoro_notifier.dart';
import '../domain/achievement.dart';

class AchievementsNotifier extends Notifier<Set<String>> {
  static const _boxName = 'achievements_box';
  static const _keyUnlocked = 'unlocked_ids';

  @override
  Set<String> build() {
    final box = Hive.box(_boxName);
    final raw = box.get(_keyUnlocked, defaultValue: <dynamic>[]) as List;
    return raw.cast<String>().toSet();
  }

  /// Computes earned achievement IDs from current app state.
  Set<String> computeEarned() {
    final habits = ref.read(habitsProvider);
    final goals = ref.read(goalsProvider);
    final journal = ref.read(journalProvider);
    final reading = ref.read(readingProvider);
    final reflections = ref.read(reflectionProvider);
    final streak = ref.read(streakProvider);
    final pomodoro = ref.read(pomodoroProvider.notifier).totalCompleted;

    // Study stats from XP box
    final studyBox = Hive.box('study_box');
    final totalAnswered = studyBox.values
        .fold<int>(0, (s, v) {
          if (v is Map) {
            final right = (v['rightCount'] as num?)?.toInt() ?? 0;
            final wrong = (v['wrongCount'] as num?)?.toInt() ?? 0;
            return s + right + wrong;
          }
          return s;
        });
    final hasCustomCard = studyBox.values.any((v) {
      if (v is Map) {
        final id = v['id'] as String? ?? '';
        return id.startsWith('custom_');
      }
      return false;
    });

    final totalMilestones = goals.fold<int>(
      0, (s, g) => s + g.milestones.where((m) => m.done).length);
    final completedReading = reading.where(
      (i) => i.status == ReadingStatus.completed).length;

    final earned = <String>{};

    // Study
    if (totalAnswered >= 1) earned.add('first_card');
    if (totalAnswered >= 100) earned.add('centurion');
    if (totalAnswered >= 500) earned.add('scholar');
    if (streak.currentStreak >= 7) earned.add('week_streak');
    if (streak.currentStreak >= 30) earned.add('month_streak');
    if (hasCustomCard) earned.add('card_creator');
    // Habits
    if (habits.isNotEmpty) earned.add('habit_starter');
    if (habits.any((h) => h.currentStreak >= 7)) earned.add('week_habit');
    if (habits.any((h) => h.longestStreak >= 30)) earned.add('month_habit');
    // Goals
    if (goals.isNotEmpty) earned.add('goal_setter');
    if (totalMilestones >= 5) earned.add('milestone_master');
    if (goals.any((g) => g.completed)) earned.add('goal_complete');
    // Journal
    if (journal.isNotEmpty) earned.add('first_entry');
    if (journal.length >= 10) earned.add('journalist');
    // Reflection
    if (reflections.isNotEmpty) earned.add('reflective');
    if (reflections.length >= 4) earned.add('consistent_reflector');
    // Reading
    if (completedReading >= 1) earned.add('bookworm');
    if (completedReading >= 5) earned.add('voracious');
    // Pomodoro
    if (pomodoro >= 1) earned.add('first_pomodoro');
    if (pomodoro >= 10) earned.add('focused');

    return earned;
  }

  /// Returns newly unlocked achievements (earned but not yet in stored set).
  List<Achievement> checkAndUnlock() {
    final earned = computeEarned();
    final newlyUnlocked = earned.difference(state);
    if (newlyUnlocked.isEmpty) return [];

    final updated = {...state, ...newlyUnlocked};
    final box = Hive.box(_boxName);
    box.put(_keyUnlocked, updated.toList());
    state = updated;

    return allAchievements
        .where((a) => newlyUnlocked.contains(a.id))
        .toList();
  }
}

final achievementsProvider =
    NotifierProvider<AchievementsNotifier, Set<String>>(
  AchievementsNotifier.new,
);

/// Derived provider: all earned achievements sorted by category
final earnedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final unlocked = ref.watch(achievementsProvider);
  return allAchievements.where((a) => unlocked.contains(a.id)).toList();
});
