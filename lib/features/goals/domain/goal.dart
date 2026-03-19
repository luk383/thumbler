class GoalMilestone {
  const GoalMilestone({required this.id, required this.text, this.done = false});

  final String id;
  final String text;
  final bool done;

  GoalMilestone copyWith({bool? done}) =>
      GoalMilestone(id: id, text: text, done: done ?? this.done);

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'done': done};

  factory GoalMilestone.fromMap(Map map) => GoalMilestone(
        id: map['id'] as String,
        text: map['text'] as String,
        done: map['done'] as bool? ?? false,
      );
}

enum GoalArea {
  study('Studio', '📚'),
  career('Carriera', '💼'),
  health('Salute', '🏃'),
  personal('Personale', '🌱'),
  finance('Finanze', '💰'),
  creative('Creativo', '🎨');

  const GoalArea(this.label, this.emoji);
  final String label;
  final String emoji;
}

class Goal {
  const Goal({
    required this.id,
    required this.title,
    this.description,
    this.area = GoalArea.personal,
    this.targetDate,
    this.milestones = const [],
    this.completed = false,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final GoalArea area;
  final DateTime? targetDate;
  final List<GoalMilestone> milestones;
  final bool completed;
  final DateTime createdAt;

  int get doneCount => milestones.where((m) => m.done).length;
  double get progress =>
      milestones.isEmpty ? 0 : doneCount / milestones.length;

  Goal copyWith({
    String? title,
    String? description,
    GoalArea? area,
    DateTime? targetDate,
    List<GoalMilestone>? milestones,
    bool? completed,
  }) => Goal(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        area: area ?? this.area,
        targetDate: targetDate ?? this.targetDate,
        milestones: milestones ?? this.milestones,
        completed: completed ?? this.completed,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'area': area.index,
        'targetDate': targetDate?.toIso8601String(),
        'milestones': milestones.map((m) => m.toMap()).toList(),
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromMap(Map map) => Goal(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        area: GoalArea.values[(map['area'] as num?)?.toInt() ?? 4],
        targetDate: map['targetDate'] != null
            ? DateTime.tryParse(map['targetDate'] as String)
            : null,
        milestones: (map['milestones'] as List? ?? [])
            .map((m) => GoalMilestone.fromMap(m as Map))
            .toList(),
        completed: map['completed'] as bool? ?? false,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
