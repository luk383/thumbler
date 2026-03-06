import 'package:flutter_test/flutter_test.dart';

import 'package:thumbler/features/exam/domain/exam_attempt.dart';
import 'package:thumbler/features/exam/domain/exam_result.dart';
import 'package:thumbler/features/study/domain/study_item.dart';

void main() {
  test('ExamResult.fromAttempt computes score, wrong ids, and weakest domain', () {
    final attempt = ExamAttempt(
      id: 'attempt-1',
      startedAt: DateTime(2026, 3, 6, 10),
      finishedAt: DateTime(2026, 3, 6, 10, 30),
      totalQuestions: 3,
      durationSeconds: 1800,
      remainingSeconds: 0,
      questionIds: const ['q1', 'q2', 'q3'],
      answers: const {'q1': 1, 'q2': 0, 'q3': 0},
      scoreCorrect: 2,
      isCompleted: true,
    );

    const questions = [
      StudyItem(
        id: 'q1',
        contentType: ContentType.examQuestion,
        category: 'Security',
        promptText: 'Question 1',
        options: ['A', 'B'],
        correctAnswerIndex: 1,
      ),
      StudyItem(
        id: 'q2',
        contentType: ContentType.examQuestion,
        category: 'Networking',
        promptText: 'Question 2',
        options: ['A', 'B'],
        correctAnswerIndex: 1,
      ),
      StudyItem(
        id: 'q3',
        contentType: ContentType.examQuestion,
        category: 'Security',
        promptText: 'Question 3',
        options: ['A', 'B'],
        correctAnswerIndex: 0,
      ),
    ];

    final result = ExamResult.fromAttempt(
      attempt: attempt,
      questions: questions,
    );

    expect(result.correctAnswers, 2);
    expect(result.wrongAnswers, 1);
    expect(result.percentageScore, 67);
    expect(result.wrongQuestionIds, ['q2']);
    expect(result.domainScores, {'Security': 100.0, 'Networking': 0.0});
    expect(result.weakestDomain, 'Networking');
  });

  test('ExamResult.fromMap migrates integer domain scores and infers weakest domain', () {
    final result = ExamResult.fromMap({
      'id': 'attempt-2',
      'completedAt': '2026-03-06T12:00:00.000',
      'totalQuestions': 2,
      'correctAnswers': 1,
      'wrongAnswers': 1,
      'percentageScore': 50,
      'domainScores': {'Security': 40, 'Networking': 70},
      'wrongQuestionIds': ['q1'],
    });

    expect(result.domainScores, {'Security': 40.0, 'Networking': 70.0});
    expect(result.weakestDomain, 'Security');
  });
}
