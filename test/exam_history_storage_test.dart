import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wolf_lab/features/exam/data/exam_attempt_storage.dart';
import 'package:wolf_lab/features/exam/data/exam_history_storage.dart';
import 'package:wolf_lab/features/exam/domain/exam_attempt.dart';
import 'package:wolf_lab/features/exam/domain/exam_result.dart';

void main() {
  late Directory hiveDir;
  late Box examBox;
  late ExamAttemptStorage attemptStorage;
  late ExamHistoryStorage resultStorage;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('wolf_lab_exam_history');
    Hive.init(hiveDir.path);
    examBox = await Hive.openBox(ExamAttemptStorage.boxName);
    attemptStorage = ExamAttemptStorage();
    resultStorage = ExamHistoryStorage();
  });

  tearDown(() async {
    await examBox.deleteFromDisk();
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('removes a single result and matching attempt by id', () {
    final attemptA = ExamAttempt(
      id: 'a1',
      startedAt: DateTime(2026, 3, 6, 10),
      finishedAt: DateTime(2026, 3, 6, 10, 30),
      deckId: 'aws_certified_security_specialty_scs_c02',
      deckTitle: 'AWS Certified Security - Specialty',
      totalQuestions: 30,
      durationSeconds: 1800,
      remainingSeconds: 0,
      questionIds: const ['q1'],
      isCompleted: true,
      scoreCorrect: 20,
    );
    final attemptB = ExamAttempt(
      id: 'b1',
      startedAt: DateTime(2026, 3, 6, 11),
      finishedAt: DateTime(2026, 3, 6, 11, 30),
      deckId: 'aws_certified_solutions_architect_associate_saa_c03',
      deckTitle: 'AWS Certified Solutions Architect - Associate',
      totalQuestions: 30,
      durationSeconds: 1800,
      remainingSeconds: 0,
      questionIds: const ['q2'],
      isCompleted: true,
      scoreCorrect: 18,
    );

    attemptStorage.addToHistory(attemptA);
    attemptStorage.addToHistory(attemptB);
    resultStorage.addResult(
      ExamResult(
        id: 'a1',
        completedAt: DateTime(2026, 3, 6, 10, 30),
        deckId: 'aws_certified_security_specialty_scs_c02',
        deckTitle: 'AWS Certified Security - Specialty',
        durationSeconds: 1800,
        totalQuestions: 30,
        correctAnswers: 20,
        wrongAnswers: 10,
        percentageScore: 67,
        domainScores: {'Threat Detection and Monitoring': 67},
      ),
    );
    resultStorage.addResult(
      ExamResult(
        id: 'b1',
        completedAt: DateTime(2026, 3, 6, 11, 30),
        deckId: 'aws_certified_solutions_architect_associate_saa_c03',
        deckTitle: 'AWS Certified Solutions Architect - Associate',
        durationSeconds: 1800,
        totalQuestions: 30,
        correctAnswers: 18,
        wrongAnswers: 12,
        percentageScore: 60,
        domainScores: {'Design Secure Architectures': 60},
      ),
    );

    attemptStorage.removeFromHistory('a1');
    resultStorage.removeResult('a1');

    expect(attemptStorage.loadHistory().map((a) => a.id), ['b1']);
    expect(resultStorage.loadResults().map((r) => r.id), ['b1']);
  });

  test('clears history only for the selected deck', () {
    attemptStorage.replaceHistory([
      ExamAttempt(
        id: 'a1',
        startedAt: DateTime(2026, 3, 6, 10),
        finishedAt: DateTime(2026, 3, 6, 10, 30),
        deckId: 'aws_certified_security_specialty_scs_c02',
        deckTitle: 'AWS Certified Security - Specialty',
        totalQuestions: 30,
        durationSeconds: 1800,
        remainingSeconds: 0,
        questionIds: const ['q1'],
        isCompleted: true,
        scoreCorrect: 20,
      ),
      ExamAttempt(
        id: 'b1',
        startedAt: DateTime(2026, 3, 6, 11),
        finishedAt: DateTime(2026, 3, 6, 11, 30),
        deckId: 'aws_certified_solutions_architect_associate_saa_c03',
        deckTitle: 'AWS Certified Solutions Architect - Associate',
        totalQuestions: 30,
        durationSeconds: 1800,
        remainingSeconds: 0,
        questionIds: const ['q2'],
        isCompleted: true,
        scoreCorrect: 18,
      ),
    ]);
    resultStorage.replaceResults([
      ExamResult(
        id: 'a1',
        completedAt: DateTime(2026, 3, 6, 10, 30),
        deckId: 'aws_certified_security_specialty_scs_c02',
        deckTitle: 'AWS Certified Security - Specialty',
        durationSeconds: 1800,
        totalQuestions: 30,
        correctAnswers: 20,
        wrongAnswers: 10,
        percentageScore: 67,
        domainScores: {'Threat Detection and Monitoring': 67},
      ),
      ExamResult(
        id: 'b1',
        completedAt: DateTime(2026, 3, 6, 11, 30),
        deckId: 'aws_certified_solutions_architect_associate_saa_c03',
        deckTitle: 'AWS Certified Solutions Architect - Associate',
        durationSeconds: 1800,
        totalQuestions: 30,
        correctAnswers: 18,
        wrongAnswers: 12,
        percentageScore: 60,
        domainScores: {'Design Secure Architectures': 60},
      ),
    ]);

    attemptStorage.clearHistoryForDeck(
      'aws_certified_security_specialty_scs_c02',
    );
    resultStorage.clearResultsForDeck(
      'aws_certified_security_specialty_scs_c02',
    );

    expect(attemptStorage.loadHistory().map((a) => a.id), ['b1']);
    expect(resultStorage.loadResults().map((r) => r.id), ['b1']);
  });
}
