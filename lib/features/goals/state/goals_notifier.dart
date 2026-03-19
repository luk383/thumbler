import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goals_storage.dart';
import '../domain/goal.dart';

class GoalsNotifier extends Notifier<List<Goal>> {
  @override
  List<Goal> build() => GoalsStorage().all();

  void add(Goal goal) {
    GoalsStorage().save(goal);
    state = GoalsStorage().all();
  }

  void update(Goal goal) {
    GoalsStorage().save(goal);
    state = GoalsStorage().all();
  }

  void toggleMilestone(String goalId, String milestoneId) {
    final goal = state.firstWhere((g) => g.id == goalId);
    final updated = goal.copyWith(
      milestones: goal.milestones
          .map((m) => m.id == milestoneId ? m.copyWith(done: !m.done) : m)
          .toList(),
    );
    // Auto-complete goal if all milestones done
    final allDone =
        updated.milestones.isNotEmpty && updated.milestones.every((m) => m.done);
    GoalsStorage().save(allDone ? updated.copyWith(completed: true) : updated);
    state = GoalsStorage().all();
  }

  void toggleCompleted(String goalId) {
    final goal = state.firstWhere((g) => g.id == goalId);
    GoalsStorage().save(goal.copyWith(completed: !goal.completed));
    state = GoalsStorage().all();
  }

  void delete(String goalId) {
    GoalsStorage().delete(goalId);
    state = GoalsStorage().all();
  }
}

final goalsProvider = NotifierProvider<GoalsNotifier, List<Goal>>(
  GoalsNotifier.new,
);
