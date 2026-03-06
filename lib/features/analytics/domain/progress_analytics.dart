import '../../exam/domain/exam_result.dart';
import '../../study/domain/study_item.dart';

class ProgressAnalytics {
  const ProgressAnalytics({
    required this.totalAnswered,
    required this.totalCorrect,
    required this.totalWrong,
    required this.correctRate,
    required this.reviewedCards,
    required this.totalTrackedCards,
    required this.domainSummaries,
    required this.weakestDomains,
    required this.recentActivity,
    required this.totalCompletedExams,
    required this.averageExamScore,
    required this.lastExamScore,
  });

  final int totalAnswered;
  final int totalCorrect;
  final int totalWrong;
  final int correctRate;
  final int reviewedCards;
  final int totalTrackedCards;
  final List<DomainAnalyticsSummary> domainSummaries;
  final List<DomainAnalyticsSummary> weakestDomains;
  final List<RecentActivityPoint> recentActivity;
  final int totalCompletedExams;
  final int averageExamScore;
  final int? lastExamScore;

  bool get hasStudyData => totalAnswered > 0 || reviewedCards > 0;
  bool get hasAnyData => hasStudyData || totalCompletedExams > 0;
}

class DomainAnalyticsSummary {
  const DomainAnalyticsSummary({
    required this.domain,
    required this.answered,
    required this.correct,
    required this.wrong,
    required this.accuracy,
  });

  final String domain;
  final int answered;
  final int correct;
  final int wrong;
  final int accuracy;
}

class RecentActivityPoint {
  const RecentActivityPoint({
    required this.label,
    required this.reviewedCards,
    required this.completedExams,
  });

  final String label;
  final int reviewedCards;
  final int completedExams;

  int get totalActivity => reviewedCards + completedExams;
}

ProgressAnalytics buildProgressAnalytics({
  required List<StudyItem> studyItems,
  required List<ExamResult> examResults,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final totalCorrect = studyItems.fold<int>(0, (sum, item) => sum + item.correctCount);
  final totalWrong = studyItems.fold<int>(0, (sum, item) => sum + item.wrongCount);
  final totalAnswered = totalCorrect + totalWrong;
  final reviewedCards = studyItems.where((item) => item.timesSeen > 0).length;

  final byDomain = <String, DomainAnalyticsSummary>{};
  for (final item in studyItems) {
    final answered = item.correctCount + item.wrongCount;
    if (answered == 0) continue;
    final previous = byDomain[item.category];
    byDomain[item.category] = DomainAnalyticsSummary(
      domain: item.category,
      answered: (previous?.answered ?? 0) + answered,
      correct: (previous?.correct ?? 0) + item.correctCount,
      wrong: (previous?.wrong ?? 0) + item.wrongCount,
      accuracy: 0,
    );
  }

  final domainSummaries = byDomain.values
      .map(
        (summary) => DomainAnalyticsSummary(
          domain: summary.domain,
          answered: summary.answered,
          correct: summary.correct,
          wrong: summary.wrong,
          accuracy: summary.answered == 0
              ? 0
              : ((summary.correct / summary.answered) * 100).round(),
        ),
      )
      .toList()
    ..sort((a, b) {
      final byAnswered = b.answered.compareTo(a.answered);
      if (byAnswered != 0) return byAnswered;
      return a.domain.toLowerCase().compareTo(b.domain.toLowerCase());
    });

  final weakestDomains = [...domainSummaries]
    ..sort((a, b) {
      final byAccuracy = a.accuracy.compareTo(b.accuracy);
      if (byAccuracy != 0) return byAccuracy;
      return b.answered.compareTo(a.answered);
    });

  final recentActivity = List.generate(7, (index) {
    final day = DateTime(current.year, current.month, current.day)
        .subtract(Duration(days: 6 - index));
    final dayKey = _dayKey(day);

    final reviewed = studyItems.where((item) {
      final reviewedAt = item.lastReviewedAt;
      return reviewedAt != null && _dayKey(reviewedAt) == dayKey;
    }).length;

    final exams = examResults.where((result) => _dayKey(result.completedAt) == dayKey).length;

    return RecentActivityPoint(
      label: _weekdayLabel(day.weekday),
      reviewedCards: reviewed,
      completedExams: exams,
    );
  });

  final averageExamScore = examResults.isEmpty
      ? 0
      : (examResults
                    .map((result) => result.percentageScore)
                    .reduce((a, b) => a + b) /
                examResults.length)
            .round();

  return ProgressAnalytics(
    totalAnswered: totalAnswered,
    totalCorrect: totalCorrect,
    totalWrong: totalWrong,
    correctRate: totalAnswered == 0
        ? 0
        : ((totalCorrect / totalAnswered) * 100).round(),
    reviewedCards: reviewedCards,
    totalTrackedCards: studyItems.length,
    domainSummaries: domainSummaries,
    weakestDomains: weakestDomains.take(3).toList(),
    recentActivity: recentActivity,
    totalCompletedExams: examResults.length,
    averageExamScore: averageExamScore,
    lastExamScore: examResults.isEmpty ? null : examResults.first.percentageScore,
  );
}

String _dayKey(DateTime dateTime) =>
    '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

String _weekdayLabel(int weekday) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[(weekday - 1).clamp(0, labels.length - 1)];
}
