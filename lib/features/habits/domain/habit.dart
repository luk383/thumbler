class Habit {
  const Habit({
    required this.id,
    required this.name,
    this.emoji = '✅',
    this.goalId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completedDates = const [],
    required this.createdAt,
    this.reminderTime,
    this.scheduledDays = const [],
  });

  final String id;
  final String name;
  final String emoji;
  final String? goalId; // optional link to a Goal
  final int currentStreak;
  final int longestStreak;
  final List<String> completedDates; // ISO date strings yyyy-MM-dd
  final DateTime createdAt;
  final String? reminderTime; // "HH:mm" format or null
  final List<int> scheduledDays; // 0=Monday … 6=Sunday, empty = every day

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isDoneOn(DateTime date) => completedDates.contains(_dateKey(date));
  bool get isDoneToday => isDoneOn(DateTime.now());

  bool get isScheduledToday {
    if (scheduledDays.isEmpty) return true;
    // DateTime.weekday: 1=Mon … 7=Sun → map to 0–6
    return scheduledDays.contains(DateTime.now().weekday - 1);
  }

  /// Computed streak that respects scheduledDays (skips non-scheduled days).
  int get computedStreak {
    if (completedDates.isEmpty) return 0;
    int streak = 0;
    var day = DateTime.now();
    final todayKey = _dateKey(day);
    if (!completedDates.contains(todayKey)) {
      day = day.subtract(const Duration(days: 1));
    }
    while (true) {
      final key = _dateKey(day);
      final dayIndex = day.weekday - 1;
      // If habit was not scheduled that day, skip without breaking streak
      if (scheduledDays.isNotEmpty && !scheduledDays.contains(dayIndex)) {
        day = day.subtract(const Duration(days: 1));
        // Safety: don't go back more than 2 years
        if (DateTime.now().difference(day).inDays > 730) break;
        continue;
      }
      if (!completedDates.contains(key)) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Habit copyWith({
    String? name,
    String? emoji,
    String? goalId,
    bool clearGoalId = false,
    int? currentStreak,
    int? longestStreak,
    List<String>? completedDates,
    String? reminderTime,
    bool clearReminderTime = false,
    List<int>? scheduledDays,
  }) => Habit(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        goalId: clearGoalId ? null : (goalId ?? this.goalId),
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        completedDates: completedDates ?? this.completedDates,
        createdAt: createdAt,
        reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime),
        scheduledDays: scheduledDays ?? this.scheduledDays,
      );

  /// Returns a new Habit with today toggled on/off.
  Habit toggleToday() {
    final today = _dateKey(DateTime.now());
    final List<String> newDates;
    if (completedDates.contains(today)) {
      newDates = completedDates.where((d) => d != today).toList();
    } else {
      newDates = [...completedDates, today];
    }
    final newStreak = _computeStreak(newDates);
    return copyWith(
      completedDates: newDates,
      currentStreak: newStreak,
      longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
    );
  }

  static int _computeStreak(List<String> dates) {
    if (dates.isEmpty) return 0;
    final sorted = [...dates]..sort();
    var streak = 0;
    var cursor = DateTime.now();
    for (var i = sorted.length - 1; i >= 0; i--) {
      final d = DateTime.parse(sorted[i]);
      final diff = cursor.difference(d).inDays;
      if (diff == 0 || diff == 1) {
        streak++;
        cursor = d;
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'goalId': goalId,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'completedDates': completedDates,
        'createdAt': createdAt.toIso8601String(),
        'reminderTime': reminderTime,
        'scheduledDays': scheduledDays,
      };

  factory Habit.fromMap(Map map) => Habit(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: map['emoji'] as String? ?? '✅',
        goalId: map['goalId'] as String?,
        currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
        completedDates: (map['completedDates'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        reminderTime: map['reminderTime'] as String?,
        scheduledDays: List<int>.from(map['scheduledDays'] ?? []),
      );
}
