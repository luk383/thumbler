import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../growth/xp/xp_notifier.dart';
import '../data/habits_storage.dart';
import '../domain/habit.dart';

class HabitsNotifier extends Notifier<List<Habit>> {
  @override
  List<Habit> build() => HabitsStorage().all();

  void add(Habit habit) {
    HabitsStorage().save(habit);
    state = HabitsStorage().all();
  }

  void addHabit({
    required String name,
    required String emoji,
    String? goalId,
    String? reminderTime,
  }) {
    final habit = Habit(
      id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      emoji: emoji,
      goalId: goalId,
      createdAt: DateTime.now(),
      reminderTime: reminderTime,
    );
    HabitsStorage().save(habit);
    state = HabitsStorage().all();
  }

  void updateHabit(
    String habitId, {
    String? name,
    String? emoji,
    String? goalId,
    bool clearGoalId = false,
    String? reminderTime,
    bool clearReminderTime = false,
  }) {
    final habit = state.firstWhere((h) => h.id == habitId);
    final updated = habit.copyWith(
      name: name,
      emoji: emoji,
      goalId: goalId,
      clearGoalId: clearGoalId,
      reminderTime: reminderTime,
      clearReminderTime: clearReminderTime,
    );
    HabitsStorage().save(updated);
    state = HabitsStorage().all();
  }

  void toggleToday(String habitId) {
    final habit = state.firstWhere((h) => h.id == habitId);
    final wasNotDone = !habit.isDoneToday;
    HabitsStorage().save(habit.toggleToday());
    state = HabitsStorage().all();
    // Award XP only when checking in (not unchecking)
    if (wasNotDone) {
      ref.read(xpProvider.notifier).addXp(XpEvent.habitComplete);
    }
  }

  void delete(String habitId) {
    HabitsStorage().delete(habitId);
    state = HabitsStorage().all();
  }
}

final habitsProvider = NotifierProvider<HabitsNotifier, List<Habit>>(
  HabitsNotifier.new,
);
