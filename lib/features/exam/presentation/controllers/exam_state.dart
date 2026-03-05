import '../../domain/exam_attempt.dart';
import '../../../study/domain/study_item.dart';

enum ExamPhase {
  /// Setup / history screen.
  home,

  /// Timer running, answering questions.
  active,

  /// Timer paused; can be resumed.
  paused,

  /// Final results + domain breakdown.
  results,

  /// Reviewing wrong answers (read-only).
  reviewing,
}

class ExamState {
  const ExamState({
    this.phase = ExamPhase.home,
    this.availableQuestions = const [],
    this.activeAttempt,
    this.sessionQuestions = const [],
    this.currentIndex = 0,
    this.history = const [],
    this.selectedCount = 90,
    this.reviewQuestions = const [],
  });

  final ExamPhase phase;

  /// All imported items with contentType == examQuestion.
  final List<StudyItem> availableQuestions;

  /// The current (or most-recently-completed) attempt.
  final ExamAttempt? activeAttempt;

  /// Resolved question objects for the active session (in question order).
  final List<StudyItem> sessionQuestions;

  /// Index into sessionQuestions (or reviewQuestions in reviewing phase).
  final int currentIndex;

  /// Last 10 completed attempts (newest first).
  final List<ExamAttempt> history;

  /// Question count the user has selected (30 / 60 / 90).
  final int selectedCount;

  /// Wrong questions for review mode.
  final List<StudyItem> reviewQuestions;

  // ── Derived ───────────────────────────────────────────────────────────────

  bool get hasIncompleteAttempt =>
      activeAttempt != null && !activeAttempt!.isCompleted;

  StudyItem? get currentQuestion {
    if (phase == ExamPhase.reviewing) {
      return reviewQuestions.isEmpty || currentIndex >= reviewQuestions.length
          ? null
          : reviewQuestions[currentIndex];
    }
    return sessionQuestions.isEmpty || currentIndex >= sessionQuestions.length
        ? null
        : sessionQuestions[currentIndex];
  }

  int? get currentAnswer {
    final q = currentQuestion;
    if (q == null || activeAttempt == null) return null;
    return activeAttempt!.answers[q.id];
  }

  bool get currentFlagged {
    final q = currentQuestion;
    if (q == null || activeAttempt == null) return false;
    return activeAttempt!.flaggedIds.contains(q.id);
  }

  int get effectiveQuestionCount =>
      availableQuestions.length < selectedCount
          ? availableQuestions.length
          : selectedCount;

  // ── CopyWith ──────────────────────────────────────────────────────────────

  static const _nil = Object();

  ExamState copyWith({
    ExamPhase? phase,
    List<StudyItem>? availableQuestions,
    Object? activeAttempt = _nil,
    List<StudyItem>? sessionQuestions,
    int? currentIndex,
    List<ExamAttempt>? history,
    int? selectedCount,
    List<StudyItem>? reviewQuestions,
  }) =>
      ExamState(
        phase: phase ?? this.phase,
        availableQuestions: availableQuestions ?? this.availableQuestions,
        activeAttempt: identical(activeAttempt, _nil)
            ? this.activeAttempt
            : activeAttempt as ExamAttempt?,
        sessionQuestions: sessionQuestions ?? this.sessionQuestions,
        currentIndex: currentIndex ?? this.currentIndex,
        history: history ?? this.history,
        selectedCount: selectedCount ?? this.selectedCount,
        reviewQuestions: reviewQuestions ?? this.reviewQuestions,
      );
}
