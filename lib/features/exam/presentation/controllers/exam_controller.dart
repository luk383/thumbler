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
import '../../../study/presentation/controllers/deck_library_controller.dart';
import 'exam_state.dart';

final examAttemptStorageProvider = Provider<ExamAttemptStorage>(
  (_) => ExamAttemptStorage(),
);

final examHistoryStorageProvider = Provider<ExamHistoryStorage>(
  (_) => ExamHistoryStorage(),
);

class ExamNotifier extends Notifier<ExamState> {
  static final _rng = Random();

  Timer? _timer;
  int _tickCount = 0;

  @override
  ExamState build() {
    ref.onDispose(_stopTimer);
    final activeDeck = ref.watch(activeDeckMetaProvider);
    ref.watch(deckLibraryDataVersionProvider);

    final questions = ExamQuestionRepository().loadAll(deckId: activeDeck?.id);
    final storage = ref.read(examAttemptStorageProvider);
    final history = storage.loadHistory();
    final active = storage.loadActive();
    final results = ref.read(examHistoryStorageProvider).loadResults();
    final activeAttempt = active?.deckId == activeDeck?.id ? active : null;

    return ExamState(
      availableQuestions: questions,
      history: history,
      results: results,
      activeAttempt: activeAttempt,
      phase: activeAttempt != null ? ExamPhase.paused : ExamPhase.home,
      // Restore session questions if there's an incomplete attempt.
      sessionQuestions: activeAttempt != null
          ? _resolveQuestions(activeAttempt.questionIds, questions)
          : const [],
    );
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  void setQuestionCount(int count) {
    state = state.copyWith(selectedCount: count);
  }

  /// Call after importing new packs to refresh available questions.
  void reload() {
    final activeDeckId = ref.read(activeDeckIdProvider);
    final questions = ExamQuestionRepository().loadAll(deckId: activeDeckId);
    state = state.copyWith(availableQuestions: questions);
  }

  void resetAfterDataChange() {
    _stopTimer();

    final activeDeckId = ref.read(activeDeckIdProvider);
    final questions = ExamQuestionRepository().loadAll(deckId: activeDeckId);
    final storage = ref.read(examAttemptStorageProvider);
    final history = storage.loadHistory();
    final active = storage.loadActive();
    final results = ref.read(examHistoryStorageProvider).loadResults();
    final activeAttempt = active?.deckId == activeDeckId ? active : null;

    state = ExamState(
      phase: activeAttempt != null ? ExamPhase.paused : ExamPhase.home,
      availableQuestions: questions,
      activeAttempt: activeAttempt,
      sessionQuestions: activeAttempt != null
          ? _resolveQuestions(activeAttempt.questionIds, questions)
          : const [],
      history: history,
      results: results,
      selectedCount: state.selectedCount,
    );
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
    final activeDeck = ref.read(activeDeckMetaProvider);

    final attempt = ExamAttempt(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      startedAt: DateTime.now(),
      deckId: activeDeck?.id,
      deckTitle: activeDeck?.title,
      totalQuestions: count,
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      questionIds: sessionQuestions.map((q) => q.id).toList(),
    );

    ref.read(examAttemptStorageProvider).saveActive(attempt);

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
    ref.read(examAttemptStorageProvider).saveActive(updated);
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
    ref.read(examAttemptStorageProvider).saveActive(updated);
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
      ref.read(examAttemptStorageProvider).saveActive(attempt);
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

    ref.read(examAttemptStorageProvider).addToHistory(completed);
    ref.read(examHistoryStorageProvider).addResult(result);
    ref.read(examAttemptStorageProvider).clearActive();

    state = state.copyWith(
      phase: ExamPhase.results,
      activeAttempt: completed,
      history: ref.read(examAttemptStorageProvider).loadHistory(),
      results: ref.read(examHistoryStorageProvider).loadResults(),
      currentIndex: 0,
    );
  }

  void deleteHistoryEntry(String resultId) {
    final activeDeckId = ref.read(activeDeckIdProvider);
    ref.read(examAttemptStorageProvider).removeFromHistory(resultId);
    ref.read(examHistoryStorageProvider).removeResult(resultId);

    final nextResults = ref.read(examHistoryStorageProvider).loadResults();
    final nextHistory = ref.read(examAttemptStorageProvider).loadHistory();
    final deletingCurrent = state.activeAttempt?.id == resultId;
    final questions = ExamQuestionRepository().loadAll(deckId: activeDeckId);

    state = state.copyWith(
      phase: deletingCurrent ? ExamPhase.home : state.phase,
      activeAttempt: deletingCurrent ? null : state.activeAttempt,
      availableQuestions: questions,
      history: nextHistory,
      results: nextResults,
      sessionQuestions: deletingCurrent ? const [] : state.sessionQuestions,
      reviewQuestions: deletingCurrent ? const [] : state.reviewQuestions,
      currentIndex: 0,
    );
  }

  void clearHistoryForActiveDeck() {
    final activeDeckId = ref.read(activeDeckIdProvider);
    final activeDeck = ref.read(activeDeckMetaProvider);
    if (activeDeck == null) {
      ref.read(examAttemptStorageProvider).replaceHistory(const []);
      ref.read(examHistoryStorageProvider).replaceResults(const []);
    } else {
      ref.read(examAttemptStorageProvider).clearHistoryForDeck(activeDeckId);
      ref.read(examHistoryStorageProvider).clearResultsForDeck(activeDeckId);
    }

    final nextResults = ref.read(examHistoryStorageProvider).loadResults();
    final nextHistory = ref.read(examAttemptStorageProvider).loadHistory();
    final deletingCurrent = state.activeAttempt?.deckId == activeDeckId &&
        (state.phase == ExamPhase.results || state.phase == ExamPhase.reviewing);
    final questions = ExamQuestionRepository().loadAll(deckId: activeDeckId);

    state = state.copyWith(
      phase: deletingCurrent ? ExamPhase.home : state.phase,
      activeAttempt: deletingCurrent ? null : state.activeAttempt,
      availableQuestions: questions,
      history: nextHistory,
      results: nextResults,
      sessionQuestions: deletingCurrent ? const [] : state.sessionQuestions,
      reviewQuestions: deletingCurrent ? const [] : state.reviewQuestions,
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
    final activeDeckId = ref.read(activeDeckIdProvider);
    final questions = ExamQuestionRepository().loadAll(deckId: activeDeckId);
    final history = ref.read(examAttemptStorageProvider).loadHistory();
    final results = ref.read(examHistoryStorageProvider).loadResults();
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
      ref.read(examAttemptStorageProvider).saveActive(updated);
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
