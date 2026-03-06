import '../../features/exam/domain/exam_attempt.dart';
import '../../features/study/domain/study_item.dart';

Map<String, DomainStats> calculateDomainStats({
  required List<StudyItem> questions,
  required Map<String, int> answers,
}) {
  final stats = <String, DomainStats>{};

  for (final question in questions) {
    final category = question.category.trim();
    if (category.isEmpty) continue;

    final selected = answers[question.id];
    final isCorrect =
        selected != null && selected == question.correctAnswerIndex;
    final previous = stats[category];

    stats[category] = DomainStats(
      total: (previous?.total ?? 0) + 1,
      correct: (previous?.correct ?? 0) + (isCorrect ? 1 : 0),
    );
  }

  return stats;
}

Map<String, int> calculateDomainScores({
  required List<StudyItem> questions,
  required Map<String, int> answers,
}) {
  final stats = calculateDomainStats(questions: questions, answers: answers);
  return {
    for (final entry in stats.entries) entry.key: entry.value.percentageInt,
  };
}

String? getWeakestDomain(Map<String, int> scores) {
  if (scores.isEmpty) return null;

  final ordered = scores.entries.toList()
    ..sort((a, b) {
      final byScore = a.value.compareTo(b.value);
      if (byScore != 0) return byScore;
      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
    });

  return ordered.first.key;
}
