import '../../../core/analytics/domain_analyzer.dart';
import '../../study/domain/study_item.dart';
import 'exam_attempt.dart';

class ExamResult {
  const ExamResult({
    required this.id,
    required this.completedAt,
    this.deckId,
    this.deckTitle,
    this.provider,
    this.certificationId,
    this.examCode,
    this.durationSeconds,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentageScore,
    required this.domainScores,
    this.weakestDomain,
    this.questionIds = const [],
    this.wrongQuestionIds = const [],
  });

  final String id;
  final DateTime completedAt;
  final String? deckId;
  final String? deckTitle;
  final String? provider;
  final String? certificationId;
  final String? examCode;
  final int? durationSeconds;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int percentageScore;
  final Map<String, double> domainScores;
  final String? weakestDomain;
  final List<String> questionIds;
  final List<String> wrongQuestionIds;

  Map<String, dynamic> toMap() => {
    'id': id,
    'completedAt': completedAt.toIso8601String(),
    'deckId': deckId,
    'deckTitle': deckTitle,
    'provider': provider,
    'certificationId': certificationId,
    'examCode': examCode,
    'durationSeconds': durationSeconds,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'wrongAnswers': wrongAnswers,
    'percentageScore': percentageScore,
    'domainScores': Map.of(domainScores),
    'weakestDomain': weakestDomain,
    'questionIds': List.of(questionIds),
    'wrongQuestionIds': List.of(wrongQuestionIds),
  };

  factory ExamResult.fromMap(Map map) => ExamResult(
    id: map['id'] as String,
    completedAt: DateTime.parse(map['completedAt'] as String),
    deckId: map['deckId'] as String?,
    deckTitle: map['deckTitle'] as String?,
    provider: map['provider'] as String?,
    certificationId: map['certificationId'] as String?,
    examCode: map['examCode'] as String?,
    durationSeconds: (map['durationSeconds'] as num?)?.toInt(),
    totalQuestions: (map['totalQuestions'] as num).toInt(),
    correctAnswers: (map['correctAnswers'] as num).toInt(),
    wrongAnswers: (map['wrongAnswers'] as num).toInt(),
    percentageScore: (map['percentageScore'] as num).toInt(),
    domainScores:
        (map['domainScores'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ) ??
        const {},
    weakestDomain:
        map['weakestDomain'] as String? ??
        getWeakestDomain(
          (map['domainScores'] as Map?)?.map(
                (k, v) => MapEntry(k as String, v as num),
              ) ??
              const {},
        ),
    questionIds:
        (map['questionIds'] as List?)?.map((e) => e as String).toList() ??
        const [],
    wrongQuestionIds:
        (map['wrongQuestionIds'] as List?)?.map((e) => e as String).toList() ??
        const [],
  );

  static ExamResult fromAttempt({
    required ExamAttempt attempt,
    required List<StudyItem> questions,
  }) {
    final correctAnswers = attempt.scoreCorrect;
    final wrongIds = questions
        .where((q) {
          final selected = attempt.answers[q.id];
          return selected == null || selected != q.correctAnswerIndex;
        })
        .map((q) => q.id)
        .toList();
    final domainScores = calculateDomainScores(
      questions: questions,
      answers: attempt.answers,
    ).map((key, value) => MapEntry(key, value.toDouble()));
    final weakestDomain = getWeakestDomain(domainScores);

    return ExamResult(
      id: attempt.id,
      completedAt: attempt.finishedAt ?? DateTime.now(),
      deckId: attempt.deckId,
      deckTitle: attempt.deckTitle,
      provider: attempt.provider,
      certificationId: attempt.certificationId,
      examCode: attempt.examCode,
      durationSeconds: attempt.elapsedSeconds,
      totalQuestions: attempt.totalQuestions,
      correctAnswers: correctAnswers,
      wrongAnswers: attempt.totalQuestions - correctAnswers,
      percentageScore: attempt.totalQuestions == 0
          ? 0
          : ((correctAnswers / attempt.totalQuestions) * 100).round(),
      domainScores: domainScores,
      weakestDomain: weakestDomain,
      questionIds: questions.map((q) => q.id).toList(),
      wrongQuestionIds: wrongIds,
    );
  }
}
