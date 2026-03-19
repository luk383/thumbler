class StudySession {
  StudySession({
    required this.id,
    required this.date,
    required this.cardCount,
    required this.correctCount,
    required this.durationSeconds,
    required this.deckName,
  });

  final String id;
  final DateTime date;
  final int cardCount;
  final int correctCount;
  final int durationSeconds;
  final String deckName;

  int get accuracyPct =>
      cardCount == 0 ? 0 : ((correctCount / cardCount) * 100).round();

  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'cardCount': cardCount,
    'correctCount': correctCount,
    'durationSeconds': durationSeconds,
    'deckName': deckName,
  };

  factory StudySession.fromMap(Map map) => StudySession(
    id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
    cardCount: (map['cardCount'] as num?)?.toInt() ?? 0,
    correctCount: (map['correctCount'] as num?)?.toInt() ?? 0,
    durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
    deckName: map['deckName'] as String? ?? '',
  );

  factory StudySession.create({
    required int cardCount,
    required int correctCount,
    required int durationSeconds,
    required String deckName,
  }) => StudySession(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    date: DateTime.now(),
    cardCount: cardCount,
    correctCount: correctCount,
    durationSeconds: durationSeconds,
    deckName: deckName,
  );
}
