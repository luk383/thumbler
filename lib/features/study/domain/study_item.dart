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
    // SRS placeholders (TODO: implement scheduling v2)
    this.nextReviewAt,
    this.lastReviewedAt,
  });

  final String id; // lessonId for microCard, custom uuid for examQuestion
  final String? deckId;
  final ContentType contentType;
  final String category;

  /// Optional subtopic within a category (e.g. "Security" within "Technology").
  final String? topic;
  final String? subtopic;
  final String? objectiveId;

  final String promptText; // hook (microCard) or question (examQuestion)
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

  // SRS (TODO: use for scheduling v2)
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;

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
  );

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
  );

  /// Build a StudyItem from a feed Lesson (micro_card type).
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
