enum ContentType { microCard, examQuestion }

class StudyItem {
  const StudyItem({
    required this.id,
    this.deckId,
    required this.contentType,
    required this.category,
    this.topic,
    this.subtopic,
    this.objectiveId,
    required this.promptText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanationText,
    this.difficulty,
    this.againCount = 0,
    this.goodCount = 0,
    this.timesSeen = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.avgTimeMs,
    this.nextReviewAt,
    this.lastReviewedAt,
    // SM-2 fields
    this.easeFactor = 2.5,
    this.srsInterval = 0,
    this.srsRepetitions = 0,
    // Personal note
    this.userNote,
    // Flagging
    this.isStarred = false,
    // FSRS v4 state
    this.fsrsStability = 0.0,
    this.fsrsDifficulty = 0.0,
  });

  final String id;
  final String? deckId;
  final ContentType contentType;
  final String category;
  final String? topic;
  final String? subtopic;
  final String? objectiveId;

  final String promptText;
  final String? explanationText;
  final List<String> options;
  final int correctAnswerIndex;
  final int? difficulty;

  // Stats
  final int againCount;
  final int goodCount;
  final int timesSeen;
  final int correctCount;
  final int wrongCount;
  final int? avgTimeMs;

  // SRS scheduling
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;

  // SM-2 state
  final double easeFactor;   // starts at 2.5, min 1.3
  final int srsInterval;     // interval in days
  final int srsRepetitions;  // consecutive correct reviews

  // Personal annotation
  final String? userNote;

  // Flagging
  final bool isStarred;

  // FSRS v4 state (0.0 = not yet initialized → first review uses init formulas)
  final double fsrsStability;
  final double fsrsDifficulty;

  String get correctAnswer => options[correctAnswerIndex];

  StudyItem copyWith({
    String? deckId,
    int? againCount,
    int? goodCount,
    int? timesSeen,
    int? correctCount,
    int? wrongCount,
    int? avgTimeMs,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    double? easeFactor,
    int? srsInterval,
    int? srsRepetitions,
    Object? userNote = _sentinel,
    bool? isStarred,
    double? fsrsStability,
    double? fsrsDifficulty,
  }) => StudyItem(
    id: id,
    deckId: deckId ?? this.deckId,
    contentType: contentType,
    category: category,
    topic: topic,
    subtopic: subtopic,
    objectiveId: objectiveId,
    promptText: promptText,
    explanationText: explanationText,
    options: options,
    correctAnswerIndex: correctAnswerIndex,
    difficulty: difficulty,
    againCount: againCount ?? this.againCount,
    goodCount: goodCount ?? this.goodCount,
    timesSeen: timesSeen ?? this.timesSeen,
    correctCount: correctCount ?? this.correctCount,
    wrongCount: wrongCount ?? this.wrongCount,
    avgTimeMs: avgTimeMs ?? this.avgTimeMs,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    easeFactor: easeFactor ?? this.easeFactor,
    srsInterval: srsInterval ?? this.srsInterval,
    srsRepetitions: srsRepetitions ?? this.srsRepetitions,
    userNote: userNote == _sentinel ? this.userNote : userNote as String?,
    isStarred: isStarred ?? this.isStarred,
    fsrsStability: fsrsStability ?? this.fsrsStability,
    fsrsDifficulty: fsrsDifficulty ?? this.fsrsDifficulty,
  );

  static const Object _sentinel = Object();

  Map<String, dynamic> toMap() => {
    'id': id,
    'deckId': deckId,
    'contentType': contentType.index,
    'category': category,
    'topic': topic,
    'subtopic': subtopic,
    'objectiveId': objectiveId,
    'promptText': promptText,
    'explanationText': explanationText,
    'options': options,
    'correctAnswerIndex': correctAnswerIndex,
    'difficulty': difficulty,
    'againCount': againCount,
    'goodCount': goodCount,
    'timesSeen': timesSeen,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'avgTimeMs': avgTimeMs,
    'nextReviewAt': nextReviewAt?.toIso8601String(),
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    'easeFactor': easeFactor,
    'srsInterval': srsInterval,
    'srsRepetitions': srsRepetitions,
    'userNote': userNote,
    'isStarred': isStarred,
    'fsrsStability': fsrsStability,
    'fsrsDifficulty': fsrsDifficulty,
  };

  factory StudyItem.fromMap(Map map) => StudyItem(
    id: map['id'] as String? ?? map['lessonId'] as String,
    deckId: map['deckId'] as String?,
    contentType: ContentType.values[(map['contentType'] as num?)?.toInt() ?? 0],
    category: map['category'] as String,
    topic: map['topic'] as String?,
    subtopic: map['subtopic'] as String?,
    objectiveId: map['objectiveId'] as String?,
    promptText: map['promptText'] as String? ?? map['hook'] as String? ?? '',
    explanationText: map['explanationText'] as String?,
    options:
        (map['options'] as List?)?.map((e) => e as String).toList() ?? const [],
    correctAnswerIndex: (map['correctAnswerIndex'] as num?)?.toInt() ?? 0,
    difficulty: (map['difficulty'] as num?)?.toInt(),
    againCount: (map['againCount'] as num?)?.toInt() ?? 0,
    goodCount: (map['goodCount'] as num?)?.toInt() ?? 0,
    timesSeen: (map['timesSeen'] as num?)?.toInt() ?? 0,
    correctCount: (map['correctCount'] as num?)?.toInt() ?? 0,
    wrongCount: (map['wrongCount'] as num?)?.toInt() ?? 0,
    avgTimeMs: (map['avgTimeMs'] as num?)?.toInt(),
    nextReviewAt: map['nextReviewAt'] != null
        ? DateTime.tryParse(map['nextReviewAt'] as String)
        : null,
    lastReviewedAt: map['lastReviewedAt'] != null
        ? DateTime.tryParse(map['lastReviewedAt'] as String)
        : null,
    easeFactor: (map['easeFactor'] as num?)?.toDouble() ?? 2.5,
    srsInterval: (map['srsInterval'] as num?)?.toInt() ?? 0,
    srsRepetitions: (map['srsRepetitions'] as num?)?.toInt() ?? 0,
    userNote: map['userNote'] as String?,
    isStarred: (map['isStarred'] as bool?) ?? false,
    fsrsStability: (map['fsrsStability'] as num?)?.toDouble() ?? 0.0,
    fsrsDifficulty: (map['fsrsDifficulty'] as num?)?.toDouble() ?? 0.0,
  );

  static StudyItem fromLesson({
    required String id,
    String? deckId,
    required String category,
    required String hook,
    required String explanation,
    required List<String> options,
    required int correctAnswerIndex,
  }) => StudyItem(
    id: id,
    deckId: deckId,
    contentType: ContentType.microCard,
    category: category,
    promptText: hook,
    explanationText: explanation,
    options: options,
    correctAnswerIndex: correctAnswerIndex,
  );
}
