class ReflectionEntry {
  const ReflectionEntry({
    required this.id,
    required this.weekStart, // Monday of the week
    this.learned,
    this.grateful,
    this.improve,
    this.freeText,
    required this.createdAt,
  });

  final String id;
  final DateTime weekStart;
  final String? learned;
  final String? grateful;
  final String? improve;
  final String? freeText;
  final DateTime createdAt;

  static DateTime currentWeekStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  bool get isEmpty =>
      (learned?.isEmpty ?? true) &&
      (grateful?.isEmpty ?? true) &&
      (improve?.isEmpty ?? true) &&
      (freeText?.isEmpty ?? true);

  ReflectionEntry copyWith({
    String? learned,
    String? grateful,
    String? improve,
    String? freeText,
  }) => ReflectionEntry(
        id: id,
        weekStart: weekStart,
        learned: learned ?? this.learned,
        grateful: grateful ?? this.grateful,
        improve: improve ?? this.improve,
        freeText: freeText ?? this.freeText,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'weekStart': weekStart.toIso8601String(),
        'learned': learned,
        'grateful': grateful,
        'improve': improve,
        'freeText': freeText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReflectionEntry.fromMap(Map map) => ReflectionEntry(
        id: map['id'] as String,
        weekStart: DateTime.tryParse(map['weekStart'] as String? ?? '') ??
            DateTime.now(),
        learned: map['learned'] as String?,
        grateful: map['grateful'] as String?,
        improve: map['improve'] as String?,
        freeText: map['freeText'] as String?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
