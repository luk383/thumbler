enum JournalMood { great, good, ok, bad }

extension JournalMoodExt on JournalMood {
  String get emoji => switch (this) {
        JournalMood.great => '😄',
        JournalMood.good => '🙂',
        JournalMood.ok => '😐',
        JournalMood.bad => '😔',
      };
  String get label => switch (this) {
        JournalMood.great => 'Ottimo',
        JournalMood.good => 'Bene',
        JournalMood.ok => 'Ok',
        JournalMood.bad => 'Male',
      };
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.text,
    this.mood,
    this.tags = const [],
    this.goalId,
    this.habitId,
    required this.createdAt,
  });

  final String id;
  final String text;
  final JournalMood? mood;
  final List<String> tags;
  final String? goalId;
  final String? habitId;
  final DateTime createdAt;

  String get preview =>
      text.length > 120 ? '${text.substring(0, 120)}…' : text;

  JournalEntry copyWith({
    String? text,
    JournalMood? mood,
    List<String>? tags,
    String? goalId,
    bool clearGoalId = false,
    String? habitId,
    bool clearHabitId = false,
  }) => JournalEntry(
        id: id,
        text: text ?? this.text,
        mood: mood ?? this.mood,
        tags: tags ?? this.tags,
        goalId: clearGoalId ? null : (goalId ?? this.goalId),
        habitId: clearHabitId ? null : (habitId ?? this.habitId),
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'mood': mood?.index,
        'tags': tags,
        'goalId': goalId,
        'habitId': habitId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JournalEntry.fromMap(Map map) => JournalEntry(
        id: map['id'] as String,
        text: map['text'] as String? ?? '',
        mood: map['mood'] != null
            ? JournalMood.values[(map['mood'] as num).toInt()]
            : null,
        tags: (map['tags'] as List? ?? []).map((e) => e as String).toList(),
        goalId: map['goalId'] as String?,
        habitId: map['habitId'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
