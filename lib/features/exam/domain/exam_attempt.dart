// ---------------------------------------------------------------------------
// Exam domain models — no freezed, plain Dart with toMap/fromMap for Hive.
// ---------------------------------------------------------------------------

class DomainStats {
  const DomainStats({required this.total, required this.correct});

  final int total;
  final int correct;

  double get percentage => total == 0 ? 0.0 : correct / total;
  int get percentageInt => (percentage * 100).round();

  Map<String, dynamic> toMap() => {'total': total, 'correct': correct};

  factory DomainStats.fromMap(Map m) => DomainStats(
        total: (m['total'] as num).toInt(),
        correct: (m['correct'] as num).toInt(),
      );
}

class ExamAttempt {
  ExamAttempt({
    required this.id,
    required this.startedAt,
    this.finishedAt,
    required this.totalQuestions,
    required this.durationSeconds,
    required this.remainingSeconds,
    required this.questionIds,
    Map<String, int>? answers,
    List<String>? flaggedIds,
    this.isCompleted = false,
    this.scoreCorrect = 0,
    Map<String, DomainStats>? domainBreakdown,
  })  : answers = answers ?? {},
        flaggedIds = flaggedIds ?? [],
        domainBreakdown = domainBreakdown ?? {};

  final String id;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int totalQuestions;

  /// Total seconds allocated (e.g. 5400 for 90 min).
  final int durationSeconds;

  /// Seconds remaining at last save / current tick.
  final int remainingSeconds;

  /// Ordered list of question IDs in this attempt.
  final List<String> questionIds;

  /// questionId → selected option index (0-based).
  final Map<String, int> answers;

  final List<String> flaggedIds;
  final bool isCompleted;
  final int scoreCorrect;

  /// category → DomainStats (populated at finish).
  final Map<String, DomainStats> domainBreakdown;

  // ── Derived ───────────────────────────────────────────────────────────────

  int get answeredCount => answers.length;
  int get unansweredCount => totalQuestions - answers.length;
  int get flaggedCount => flaggedIds.length;
  int get elapsedSeconds => durationSeconds - remainingSeconds;

  // ── CopyWith ──────────────────────────────────────────────────────────────

  ExamAttempt copyWith({
    DateTime? finishedAt,
    int? remainingSeconds,
    Map<String, int>? answers,
    List<String>? flaggedIds,
    bool? isCompleted,
    int? scoreCorrect,
    Map<String, DomainStats>? domainBreakdown,
  }) =>
      ExamAttempt(
        id: id,
        startedAt: startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        totalQuestions: totalQuestions,
        durationSeconds: durationSeconds,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        questionIds: questionIds,
        answers: answers ?? Map.of(this.answers),
        flaggedIds: flaggedIds ?? List.of(this.flaggedIds),
        isCompleted: isCompleted ?? this.isCompleted,
        scoreCorrect: scoreCorrect ?? this.scoreCorrect,
        domainBreakdown: domainBreakdown ?? Map.of(this.domainBreakdown),
      );

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'totalQuestions': totalQuestions,
        'durationSeconds': durationSeconds,
        'remainingSeconds': remainingSeconds,
        'questionIds': List.of(questionIds),
        'answers': Map.of(answers),
        'flaggedIds': List.of(flaggedIds),
        'isCompleted': isCompleted,
        'scoreCorrect': scoreCorrect,
        'domainBreakdown':
            domainBreakdown.map((k, v) => MapEntry(k, v.toMap())),
      };

  factory ExamAttempt.fromMap(Map m) => ExamAttempt(
        id: m['id'] as String,
        startedAt: DateTime.parse(m['startedAt'] as String),
        finishedAt: m['finishedAt'] != null
            ? DateTime.parse(m['finishedAt'] as String)
            : null,
        totalQuestions: (m['totalQuestions'] as num).toInt(),
        durationSeconds: (m['durationSeconds'] as num).toInt(),
        remainingSeconds: (m['remainingSeconds'] as num).toInt(),
        questionIds:
            (m['questionIds'] as List).map((e) => e as String).toList(),
        answers: (m['answers'] as Map?)?.map(
              (k, v) => MapEntry(k as String, (v as num).toInt()),
            ) ??
            {},
        flaggedIds: (m['flaggedIds'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        isCompleted: (m['isCompleted'] as bool?) ?? false,
        scoreCorrect: (m['scoreCorrect'] as num?)?.toInt() ?? 0,
        domainBreakdown: (m['domainBreakdown'] as Map?)?.map(
              (k, v) => MapEntry(k as String, DomainStats.fromMap(v as Map)),
            ) ??
            {},
      );
}
