import '../../../core/analytics/domain_analyzer.dart';
import '../../study/domain/study_item.dart';
import 'exam_attempt.dart';

class ExamResult {
  const ExamResult({
    required this.id,
    required this.completedAt,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentageScore,
    required this.domainScores,
    this.questionIds = const [],
    this.wrongQuestionIds = const [],
  });

  final String id;
  final DateTime completedAt;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int percentageScore;
  final Map<String, int> domainScores;
  final List<String> questionIds;
  final List<String> wrongQuestionIds;

  String? get weakestDomain => getWeakestDomain(domainScores);

  Map<String, dynamic> toMap() => {
    'id': id,
    'completedAt': completedAt.toIso8601String(),
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'wrongAnswers': wrongAnswers,
    'percentageScore': percentageScore,
    'domainScores': Map.of(domainScores),
    'questionIds': List.of(questionIds),
    'wrongQuestionIds': List.of(wrongQuestionIds),
  };

  factory ExamResult.fromMap(Map map) => ExamResult(
    id: map['id'] as String,
    completedAt: DateTime.parse(map['completedAt'] as String),
    totalQuestions: (map['totalQuestions'] as num).toInt(),
    correctAnswers: (map['correctAnswers'] as num).toInt(),
    wrongAnswers: (map['wrongAnswers'] as num).toInt(),
    percentageScore: (map['percentageScore'] as num).toInt(),
    domainScores:
        (map['domainScores'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        ) ??
        const {},
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
    );

    return ExamResult(
      id: attempt.id,
      completedAt: attempt.finishedAt ?? DateTime.now(),
      totalQuestions: attempt.totalQuestions,
      correctAnswers: correctAnswers,
      wrongAnswers: attempt.totalQuestions - correctAnswers,
      percentageScore: attempt.totalQuestions == 0
          ? 0
          : ((correctAnswers / attempt.totalQuestions) * 100).round(),
      domainScores: domainScores,
      questionIds: questions.map((q) => q.id).toList(),
      wrongQuestionIds: wrongIds,
    );
  }
}
