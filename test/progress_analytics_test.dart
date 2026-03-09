import 'package:flutter_test/flutter_test.dart';

import 'package:wolf_lab/features/analytics/domain/progress_analytics.dart';
import 'package:wolf_lab/features/exam/domain/exam_result.dart';
import 'package:wolf_lab/features/study/domain/study_item.dart';

void main() {
  test('buildProgressAnalytics aggregates study stats, domains, and exams', () {
    final analytics = buildProgressAnalytics(
      now: DateTime(2026, 3, 6, 12),
      studyItems: [
        StudyItem(
          id: 'a',
          contentType: ContentType.examQuestion,
          category: 'Security',
          promptText: 'A',
          options: const ['1', '2'],
          correctAnswerIndex: 0,
          timesSeen: 5,
          correctCount: 4,
          wrongCount: 1,
          lastReviewedAt: DateTime(2026, 3, 6, 9),
        ),
        StudyItem(
          id: 'b',
          contentType: ContentType.examQuestion,
          category: 'Networking',
          promptText: 'B',
          options: const ['1', '2'],
          correctAnswerIndex: 0,
          timesSeen: 3,
          correctCount: 1,
          wrongCount: 2,
          lastReviewedAt: DateTime(2026, 3, 5, 9),
        ),
      ],
      examResults: [
        ExamResult(
          id: 'r1',
          completedAt: DateTime(2026, 3, 6, 10),
          totalQuestions: 10,
          correctAnswers: 8,
          wrongAnswers: 2,
          percentageScore: 80,
          domainScores: const {'Security': 90, 'Networking': 60},
          weakestDomain: 'Networking',
        ),
      ],
    );

    expect(analytics.totalAnswered, 8);
    expect(analytics.totalCorrect, 5);
    expect(analytics.totalWrong, 3);
    expect(analytics.correctRate, 63);
    expect(analytics.reviewedCards, 2);
    expect(analytics.totalCompletedExams, 1);
    expect(analytics.averageExamScore, 80);
    expect(analytics.lastExamScore, 80);
    expect(analytics.domainSummaries.first.domain, 'Security');
    expect(analytics.weakestDomains.first.domain, 'Networking');
    expect(
      analytics.recentActivity.lastWhere((point) => point.label == 'Fri').totalActivity,
      2,
    );
  });
}
