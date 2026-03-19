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
