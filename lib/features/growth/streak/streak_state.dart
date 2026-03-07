class StreakState {
  const StreakState({
    this.lastStudyDate,
    this.currentStreak = 0,
    this.completedToday = false,
    this.answeredToday = 0,
  });

  final String? lastStudyDate;
  final int currentStreak;
  final bool completedToday;
  final int answeredToday;

  int get remainingToday => answeredToday >= 3 ? 0 : 3 - answeredToday;
}
