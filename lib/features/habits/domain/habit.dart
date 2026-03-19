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

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isDoneOn(DateTime date) => completedDates.contains(_dateKey(date));
  bool get isDoneToday => isDoneOn(DateTime.now());

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
      );
}
