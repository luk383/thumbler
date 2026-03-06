import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/domain_analyzer.dart';
import '../../data/exam_history_storage.dart';
import '../../data/exam_attempt_storage.dart';
import '../../data/exam_question_repository.dart';
import '../../domain/exam_attempt.dart';
import '../../domain/exam_result.dart';
import '../../../study/domain/study_item.dart';
import 'exam_state.dart';

class ExamNotifier extends Notifier<ExamState> {
  static final _rng = Random();

  Timer? _timer;
  int _tickCount = 0;

  @override
  ExamState build() {
    ref.onDispose(_stopTimer);

    final questions = ExamQuestionRepository().loadAll();
    final storage = ExamAttemptStorage();
    final history = storage.loadHistory();
    final active = storage.loadActive();
    final results = ExamHistoryStorage().loadResults();

    return ExamState(
      availableQuestions: questions,
      history: history,
      results: results,
      activeAttempt: active,
      phase: active != null ? ExamPhase.paused : ExamPhase.home,
      // Restore session questions if there's an incomplete attempt.
      sessionQuestions: active != null
          ? _resolveQuestions(active.questionIds, questions)
          : const [],
    );
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  void setQuestionCount(int count) {
    state = state.copyWith(selectedCount: count);
  }

  /// Call after importing new packs to refresh available questions.
  void reload() {
    final questions = ExamQuestionRepository().loadAll();
    state = state.copyWith(availableQuestions: questions);
  }

  // ── Session lifecycle ─────────────────────────────────────────────────────

  void startExam(int questionCount) {
    _stopTimer();
    final available = state.availableQuestions;
    if (available.isEmpty) return;

    final count = min(questionCount, available.length);
    final shuffled = List.of(available)..shuffle(_rng);
    final sessionQuestions = shuffled.take(count).toList();

    final durationSeconds = count * 60; // 1 min per question

    final attempt = ExamAttempt(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      startedAt: DateTime.now(),
      totalQuestions: count,
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      questionIds: sessionQuestions.map((q) => q.id).toList(),
    );

    ExamAttemptStorage().saveActive(attempt);

    state = state.copyWith(
      phase: ExamPhase.active,
      activeAttempt: attempt,
      sessionQuestions: sessionQuestions,
      currentIndex: 0,
    );

    _startTimer();
  }

  void resumeExam() {
    final attempt = state.activeAttempt;
    if (attempt == null || attempt.isCompleted) return;

    final questions = _resolveQuestions(
      attempt.questionIds,
      state.availableQuestions,
    );

    state = state.copyWith(
      phase: ExamPhase.active,
      sessionQuestions: questions,
      currentIndex: 0,
    );

    _startTimer();
  }

  // ── Question actions ──────────────────────────────────────────────────────

  void selectAnswer(String questionId, int optionIndex) {
    final attempt = state.activeAttempt;
    if (attempt == null) return;

    final updated = attempt.copyWith(
      answers: Map.of(attempt.answers)..[questionId] = optionIndex,
    );

    // Persist every answer immediately (lightweight).
    ExamAttemptStorage().saveActive(updated);
    state = state.copyWith(activeAttempt: updated);
  }

  void toggleFlag(String questionId) {
    final attempt = state.activeAttempt;
    if (attempt == null) return;

    final flags = List.of(attempt.flaggedIds);
    if (flags.contains(questionId)) {
      flags.remove(questionId);
    } else {
      flags.add(questionId);
    }

    final updated = attempt.copyWith(flaggedIds: flags);
    ExamAttemptStorage().saveActive(updated);
    state = state.copyWith(activeAttempt: updated);
  }

  void next() {
    final max = state.phase == ExamPhase.reviewing
        ? state.reviewQuestions.length - 1
        : state.sessionQuestions.length - 1;
    if (state.currentIndex < max) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void goToQuestion(int index) {
    final max = state.sessionQuestions.length - 1;
    if (index >= 0 && index <= max) {
      state = state.copyWith(currentIndex: index);
    }
  }

  // ── Pause / Finish ────────────────────────────────────────────────────────

  void pause() {
    _stopTimer();
    final attempt = state.activeAttempt;
    if (attempt != null) {
      ExamAttemptStorage().saveActive(attempt);
    }
    state = state.copyWith(phase: ExamPhase.paused);
  }

  void finish() {
    _stopTimer();

    final attempt = state.activeAttempt;
    if (attempt == null) return;

    int scoreCorrect = 0;

    for (final q in state.sessionQuestions) {
      final selected = attempt.answers[q.id];
      final correct = selected != null && selected == q.correctAnswerIndex;
      if (correct) scoreCorrect++;
    }

    final domainBreakdown = calculateDomainStats(
      questions: state.sessionQuestions,
      answers: attempt.answers,
    );

    final completed = attempt.copyWith(
      finishedAt: DateTime.now(),
      isCompleted: true,
      scoreCorrect: scoreCorrect,
      domainBreakdown: domainBreakdown,
    );
    final result = ExamResult.fromAttempt(
      attempt: completed,
      questions: state.sessionQuestions,
    );

    ExamAttemptStorage().addToHistory(completed);
    ExamHistoryStorage().addResult(result);
    ExamAttemptStorage().clearActive();

    state = state.copyWith(
      phase: ExamPhase.results,
      activeAttempt: completed,
      history: ExamAttemptStorage().loadHistory(),
      results: ExamHistoryStorage().loadResults(),
      currentIndex: 0,
    );
  }

  // ── Review mode ───────────────────────────────────────────────────────────

  void startReview() {
    final attempt = state.activeAttempt;
    if (attempt == null) return;

    final wrongItems = state.sessionQuestions.where((q) {
      final selected = attempt.answers[q.id];
      return selected == null || selected != q.correctAnswerIndex;
    }).toList();

    state = state.copyWith(
      phase: ExamPhase.reviewing,
      reviewQuestions: wrongItems,
      currentIndex: 0,
    );
  }

  void backToResults() {
    state = state.copyWith(phase: ExamPhase.results, currentIndex: 0);
  }

  void backToHome() {
    final questions = ExamQuestionRepository().loadAll();
    final history = ExamAttemptStorage().loadHistory();
    final results = ExamHistoryStorage().loadResults();
    state = ExamState(
      phase: ExamPhase.home,
      availableQuestions: questions,
      history: history,
      results: results,
      selectedCount: state.selectedCount,
    );
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _tickCount = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTick(Timer t) {
    final attempt = state.activeAttempt;
    if (attempt == null || state.phase != ExamPhase.active) {
      t.cancel();
      return;
    }

    _tickCount++;
    final newRemaining = attempt.remainingSeconds - 1;

    if (newRemaining <= 0) {
      t.cancel();
      finish();
      return;
    }

    final updated = attempt.copyWith(remainingSeconds: newRemaining);

    // Persist every 10 seconds.
    if (_tickCount % 10 == 0) {
      ExamAttemptStorage().saveActive(updated);
    }

    state = state.copyWith(activeAttempt: updated);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<StudyItem> _resolveQuestions(
    List<String> ids,
    List<StudyItem> available,
  ) {
    final byId = {for (final q in available) q.id: q};
    return ids.map((id) => byId[id]).whereType<StudyItem>().toList();
  }
}

final examProvider = NotifierProvider<ExamNotifier, ExamState>(
  ExamNotifier.new,
);
