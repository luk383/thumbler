import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/feed/data/mock_lessons.dart';
import '../../../../features/feed/domain/lesson.dart';
import '../../../../features/growth/streak/streak_notifier.dart';
import '../../data/study_storage.dart';
import '../../domain/study_item.dart';
import 'deck_library_controller.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// SRS self-rating after answering a card.
enum SrsRating {
  /// Card not known — review again in 10 minutes.
  again,

  /// Card known reasonably well — review in 2 days.
  good,

  /// Card very easy — review in 7 days.
  easy;

  String get label => switch (this) {
    SrsRating.again => 'Again',
    SrsRating.good => 'Good',
    SrsRating.easy => 'Easy',
  };
}

enum StudyMode {
  srs,
  speed;

  String get label => switch (this) {
    StudyMode.srs => 'SRS',
    StudyMode.speed => 'Speed',
  };

  IconData get icon => switch (this) {
    StudyMode.srs => Icons.psychology_outlined,
    StudyMode.speed => Icons.bolt,
  };
}

/// Controls which cards go into the next session queue.
enum SessionQueueType {
  due,
  weak,
  newCards,
  random;

  String get label => switch (this) {
    SessionQueueType.due => 'Due',
    SessionQueueType.weak => 'Weak',
    SessionQueueType.newCards => 'New',
    SessionQueueType.random => 'Random',
  };

  IconData get icon => switch (this) {
    SessionQueueType.due => Icons.schedule_outlined,
    SessionQueueType.weak => Icons.trending_down_outlined,
    SessionQueueType.newCards => Icons.fiber_new_outlined,
    SessionQueueType.random => Icons.shuffle_outlined,
  };
}

class StudyExternalSessionRequest {
  const StudyExternalSessionRequest({
    this.category,
    this.topic,
    this.mode = StudyMode.srs,
    this.source,
    this.autostart = false,
    this.questionIds,
    this.sessionLength = 10,
    this.lastExamAttemptId,
  });

  final String? category;
  final String? topic;
  final StudyMode mode;
  final String? source; // e.g. exam_bridge
  final bool autostart;
  final List<String>? questionIds;
  final int sessionLength;
  final String? lastExamAttemptId;
}

// ---------------------------------------------------------------------------
// SpeedResult — per-question result in a Speed session
// ---------------------------------------------------------------------------

class SpeedResult {
  const SpeedResult({
    required this.itemId,
    required this.correct,
    required this.timeMs,
    required this.timedOut,
  });
  final String itemId;
  final bool correct;
  final int timeMs;
  final bool timedOut;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class StudyState {
  const StudyState({
    this.items = const [],
    this.activeDeckId,
    this.selectedCategory,
    this.selectedTopic,
    this.selectedMode = StudyMode.srs,
    this.selectedQueueType = SessionQueueType.due,
    this.sessionLength = 10,
    this.timerSeconds = 8,
    this.isStudying = false,
    this.sessionQueue = const [],
    this.currentIndex = 0,
    this.answeredInSession = 0,
    this.generation = 0,
    this.speedResults = const [],
    this.wrongItemIds = const [],
    this.startedFromExamBridge = false,
    this.lastTrainedArea,
    this.lastExamAttemptId,
  });

  final List<StudyItem> items;
  final String? activeDeckId;

  /// null = All categories.
  final String? selectedCategory;

  /// null = All topics within the selected category.
  final String? selectedTopic;

  final StudyMode selectedMode;
  final SessionQueueType selectedQueueType;

  /// Number of questions per session (5 / 10 / 20).
  final int sessionLength;

  /// Seconds per question for Speed mode (5 / 8 / 12).
  final int timerSeconds;

  final bool isStudying;
  final List<StudyItem> sessionQueue;
  final int currentIndex;
  final int answeredInSession;

  /// Increments on every advance to force card widget rebuild via ValueKey.
  final int generation;

  /// Per-question results accumulated during a Speed session.
  final List<SpeedResult> speedResults;

  /// IDs of items answered wrong — used for "Retry wrong" button.
  final List<String> wrongItemIds;

  /// True when the current session was launched from Exam results.
  final bool startedFromExamBridge;

  /// Minimal analytics metadata (in-memory for now).
  final String? lastTrainedArea;
  final String? lastExamAttemptId;

  // ── Derived ───────────────────────────────────────────────────────────────

  List<StudyItem> get filtered {
    var list = selectedCategory == null
        ? items
        : items.where((i) => i.category == selectedCategory).toList();
    if (selectedTopic != null) {
      list = list.where((i) => i.topic == selectedTopic).toList();
    }
    return list;
  }

  List<String> get categories =>
      ({for (final i in items) i.category}).toList()..sort();

  /// Distinct topics within the currently selected category (empty if none).
  List<String> get topics {
    final byCategory = selectedCategory == null
        ? items
        : items.where((i) => i.category == selectedCategory).toList();
    return ({
      for (final i in byCategory)
        if (i.topic != null) i.topic!,
    }).toList()..sort();
  }

  bool inDeck(String id) => items.any((i) => i.id == id);

  StudyItem? get currentItem => sessionQueue.isEmpty
      ? null
      : sessionQueue[currentIndex.clamp(0, sessionQueue.length - 1)];

  bool get sessionComplete =>
      isStudying && answeredInSession >= sessionQueue.length;

  int get availableCount => filtered.length;

  /// Cards due for SRS review right now (nextReviewAt == null OR <= now).
  int get dueCount {
    final now = DateTime.now();
    return filtered
        .where((i) => i.nextReviewAt == null || !i.nextReviewAt!.isAfter(now))
        .length;
  }

  /// Cards with wrong answers (wrongCount > 0), sorted by difficulty.
  int get weakCount =>
      filtered.where((i) => i.wrongCount > 0 || i.againCount > 0).length;

  /// Cards never seen before (timesSeen == 0).
  int get newCount => filtered.where((i) => i.timesSeen == 0).length;

  /// Count for the currently selected queue type.
  int get queueCount => switch (selectedQueueType) {
    SessionQueueType.due => dueCount,
    SessionQueueType.weak => weakCount,
    SessionQueueType.newCards => newCount,
    SessionQueueType.random => availableCount,
  };

  /// Estimated minutes: SRS ~3 cards/min, Speed ~30s/card.
  int get estimatedMinutes {
    final count = sessionQueue.isNotEmpty
        ? sessionQueue.length
        : min(sessionLength, filtered.length);
    return selectedMode == StudyMode.speed
        ? ((count * (timerSeconds + 1)) / 60).ceil().clamp(1, 99)
        : (count / 3).ceil().clamp(1, 99);
  }

  // Speed session stats
  int get speedCorrect => speedResults.where((r) => r.correct).length;
  int get speedWrong => speedResults.where((r) => !r.correct).length;
  int get speedAvgMs {
    if (speedResults.isEmpty) return 0;
    return speedResults.map((r) => r.timeMs).reduce((a, b) => a + b) ~/
        speedResults.length;
  }

  int get speedAccuracyPct {
    if (speedResults.isEmpty) return 0;
    return ((speedCorrect / speedResults.length) * 100).round();
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class StudyNotifier extends Notifier<StudyState> {
  static final _rng = Random();

  @override
  StudyState build() {
    final activeDeckId = ref.watch(activeDeckIdProvider);
    ref.watch(deckLibraryDataVersionProvider);
    return StudyState(
      items: StudyStorage().allForDeck(activeDeckId),
      activeDeckId: activeDeckId,
    );
  }

  // ── Deck management ───────────────────────────────────────────────────────

  /// Adds a fully custom StudyItem (user-created card).
  void addCustomItem(StudyItem item) {
    StudyStorage().add(item);
    state = _copyWith(items: StudyStorage().allForDeck(state.activeDeckId));
  }

  void addLesson(Lesson lesson) {
    if (state.inDeck(lesson.id)) return;
    StudyStorage().add(
      StudyItem.fromLesson(
        id: lesson.id,
        deckId: state.activeDeckId,
        category: lesson.category,
        hook: lesson.hook,
        explanation: lesson.explanation,
        options: lesson.options,
        correctAnswerIndex: lesson.correctAnswerIndex,
      ),
    );
    state = _copyWith(items: StudyStorage().allForDeck(state.activeDeckId));
  }

  /// Seeds the deck with up to 5 starter cards from mockLessons (no duplicates).
  void seedStarterCards() {
    final storage = StudyStorage();
    var added = 0;
    for (final lesson in mockLessons) {
      if (added >= 5) break;
      if (!state.inDeck(lesson.id)) {
        storage.add(
          StudyItem.fromLesson(
            id: lesson.id,
            deckId: state.activeDeckId,
            category: lesson.category,
            hook: lesson.hook,
            explanation: lesson.explanation,
            options: lesson.options,
            correctAnswerIndex: lesson.correctAnswerIndex,
          ),
        );
        added++;
      }
    }
    state = _copyWith(items: storage.allForDeck(state.activeDeckId));
  }

  void removeItem(String id) {
    StudyStorage().remove(id, deckId: state.activeDeckId);
    state = _copyWith(
      items: StudyStorage().allForDeck(state.activeDeckId),
      isStudying: false,
      sessionQueue: const [],
      currentIndex: 0,
    );
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  void setCategory(String? category) {
    state = _copyWith(
      selectedCategory: _maybeNull(category),
      // Reset topic whenever category changes
      selectedTopic: _nil,
      isStudying: false,
      sessionQueue: const [],
      currentIndex: 0,
    );
  }

  void setTopic(String? topic) {
    state = _copyWith(
      selectedTopic: _maybeNull(topic),
      isStudying: false,
      sessionQueue: const [],
      currentIndex: 0,
    );
  }

  /// Reloads items from Hive without resetting session settings.
  void reloadFromStorage() {
    state = _copyWith(items: StudyStorage().allForDeck(state.activeDeckId));
  }

  void resetAfterDataChange({bool clearSelections = false}) {
    final items = StudyStorage().allForDeck(state.activeDeckId);
    final nextCategory = clearSelections || state.selectedCategory == null
        ? null
        : items.any((item) => item.category == state.selectedCategory)
        ? state.selectedCategory
        : null;
    final nextTopic =
        clearSelections || nextCategory == null || state.selectedTopic == null
        ? null
        : items.any(
            (item) =>
                item.category == nextCategory &&
                item.topic == state.selectedTopic,
          )
        ? state.selectedTopic
        : null;

    state = StudyState(
      items: items,
      activeDeckId: state.activeDeckId,
      selectedCategory: nextCategory,
      selectedTopic: nextTopic,
      selectedMode: state.selectedMode,
      selectedQueueType: state.selectedQueueType,
      sessionLength: state.sessionLength,
      timerSeconds: state.timerSeconds,
      isStudying: false,
      sessionQueue: const [],
      currentIndex: 0,
      answeredInSession: 0,
      generation: state.generation + 1,
      speedResults: const [],
      wrongItemIds: const [],
      startedFromExamBridge: false,
      lastTrainedArea: clearSelections ? null : state.lastTrainedArea,
      lastExamAttemptId: clearSelections ? null : state.lastExamAttemptId,
    );
  }

  void setMode(StudyMode mode) {
    state = _copyWith(
      selectedMode: mode,
      isStudying: false,
      sessionQueue: const [],
      currentIndex: 0,
    );
  }

  void setQueueType(SessionQueueType type) {
    state = _copyWith(
      selectedQueueType: type,
      isStudying: false,
      sessionQueue: const [],
      currentIndex: 0,
    );
  }

  void setSessionLength(int length) {
    state = _copyWith(sessionLength: length);
  }

  void setTimerSeconds(int seconds) {
    state = _copyWith(timerSeconds: seconds);
  }

  void applyExternalRequest(StudyExternalSessionRequest request) {
    if (request.source == 'exam_bridge' &&
        (request.category != null ||
            request.topic != null ||
            request.questionIds != null)) {
      startSessionFromExamBridge(
        category: request.category,
        topic: request.topic,
        questionIds: request.questionIds,
        sessionLength: request.sessionLength,
        lastExamAttemptId: request.lastExamAttemptId,
      );
      return;
    }

    setCategory(request.category);
    setTopic(request.topic);
    setMode(request.mode);
    setSessionLength(request.sessionLength);
    if (request.autostart) {
      startSession();
    }
  }

  // ── Session ───────────────────────────────────────────────────────────────

  void startSession({bool reviewAnyway = false, List<String>? retryIds}) {
    final candidates = retryIds != null
        ? state.items.where((i) => retryIds.contains(i.id)).toList()
        : state.filtered;

    final pool = reviewAnyway
        ? candidates
        : _poolForQueueType(candidates, state.selectedQueueType);

    final queue = _buildQueue(
      pool,
      state.selectedMode,
      state.selectedQueueType,
      state.sessionLength,
    );
    if (queue.isEmpty) return;
    state = StudyState(
      items: state.items,
      activeDeckId: state.activeDeckId,
      selectedCategory: state.selectedCategory,
      selectedTopic: state.selectedTopic,
      selectedMode: state.selectedMode,
      selectedQueueType: state.selectedQueueType,
      sessionLength: state.sessionLength,
      timerSeconds: state.timerSeconds,
      isStudying: true,
      sessionQueue: queue,
      currentIndex: 0,
      answeredInSession: 0,
      generation: state.generation + 1,
      speedResults: const [],
      wrongItemIds: const [],
      startedFromExamBridge: false,
      lastTrainedArea: state.lastTrainedArea,
      lastExamAttemptId: state.lastExamAttemptId,
    );
  }

  void stopSession() {
    state = _copyWith(
      isStudying: false,
      sessionQueue: const [],
      currentIndex: 0,
      answeredInSession: 0,
      speedResults: const [],
      wrongItemIds: const [],
      startedFromExamBridge: false,
    );
  }

  /// SRS: rate the current card using SM-2 algorithm and schedule next review.
  void rate(String id, {required SrsRating rating}) {
    final storage = StudyStorage();
    final item = state.items.firstWhere(
      (i) => i.id == id,
      orElse: () => state.items.first,
    );
    final wrong = rating == SrsRating.again;
    storage.update(_applySm2(item, rating).copyWith(
      againCount: wrong ? item.againCount + 1 : null,
      goodCount: wrong ? null : item.goodCount + 1,
      timesSeen: item.timesSeen + 1,
      correctCount: wrong ? null : item.correctCount + 1,
      wrongCount: wrong ? item.wrongCount + 1 : null,
      lastReviewedAt: DateTime.now(),
    ));
    ref.read(streakProvider.notifier).recordStudyQuestion();
    _advanceSession(storage);
  }

  /// SM-2 algorithm — updates easeFactor, srsInterval, srsRepetitions,
  /// and sets nextReviewAt accordingly.
  ///
  /// Quality mapping: again=0, good=3, easy=5
  static StudyItem _applySm2(StudyItem item, SrsRating rating) {
    final q = switch (rating) {
      SrsRating.again => 0,
      SrsRating.good => 3,
      SrsRating.easy => 5,
    };

    // Update ease factor: EF' = max(1.3, EF + 0.1 - (5-q)*(0.08 + (5-q)*0.02))
    final delta = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
    final newEF = (item.easeFactor + delta).clamp(1.3, 5.0);

    int newRepetitions;
    int newInterval;

    if (q < 3) {
      // Failed: reset schedule, review again in 1 day
      newRepetitions = 0;
      newInterval = 1;
    } else {
      // Passed: apply SM-2 interval progression
      newRepetitions = item.srsRepetitions + 1;
      newInterval = switch (item.srsRepetitions) {
        0 => 1,
        1 => 6,
        _ => (item.srsInterval * newEF).round().clamp(1, 365),
      };
    }

    final nextReview = DateTime.now().add(Duration(days: newInterval));

    return item.copyWith(
      easeFactor: newEF,
      srsInterval: newInterval,
      srsRepetitions: newRepetitions,
      nextReviewAt: nextReview,
    );
  }

  /// Speed: record result, persist stats, advance.
  void recordSpeedAnswer(
    String id, {
    required bool correct,
    required int timeMs,
    required bool timedOut,
  }) {
    final storage = StudyStorage();
    final item = state.items.firstWhere(
      (i) => i.id == id,
      orElse: () => state.items.first,
    );

    // Update running avgTimeMs
    final newAvg = item.avgTimeMs == null
        ? timeMs
        : ((item.avgTimeMs! * item.timesSeen + timeMs) ~/ (item.timesSeen + 1));

    storage.update(
      item.copyWith(
        timesSeen: item.timesSeen + 1,
        correctCount: correct ? item.correctCount + 1 : null,
        wrongCount: correct ? null : item.wrongCount + 1,
        avgTimeMs: newAvg,
        lastReviewedAt: DateTime.now(),
      ),
    );
    ref.read(streakProvider.notifier).recordStudyQuestion();

    final newResult = SpeedResult(
      itemId: id,
      correct: correct,
      timeMs: timeMs,
      timedOut: timedOut,
    );
    final newResults = [...state.speedResults, newResult];
    final newWrong = correct ? state.wrongItemIds : [...state.wrongItemIds, id];
    debugPrint('Study: recording speed answer for $id, moving to index ${state.currentIndex + 1}');

    final items = storage.all();
    final activeItems = items
        .where((item) => item.deckId == state.activeDeckId)
        .toList();
    final nextIndex = state.sessionQueue.isEmpty
        ? 0
        : (state.currentIndex + 1) % state.sessionQueue.length;

    state = StudyState(
      items: activeItems,
      activeDeckId: state.activeDeckId,
      selectedCategory: state.selectedCategory,
      selectedTopic: state.selectedTopic,
      selectedMode: state.selectedMode,
      selectedQueueType: state.selectedQueueType,
      sessionLength: state.sessionLength,
      timerSeconds: state.timerSeconds,
      isStudying: true,
      sessionQueue: state.sessionQueue,
      currentIndex: nextIndex,
      answeredInSession: state.answeredInSession + 1,
      generation: state.generation + 1,
      speedResults: newResults,
      wrongItemIds: newWrong,
    );
  }

  void nextCard() => _advanceSession(StudyStorage());

  void recordFeedAnswer(Lesson lesson, {required bool correct}) {
    final storage = StudyStorage();
    final item =
        storage.getById(lesson.id, deckId: state.activeDeckId) ??
        StudyItem.fromLesson(
          id: lesson.id,
          deckId: state.activeDeckId,
          category: lesson.category,
          hook: lesson.hook,
          explanation: lesson.explanation,
          options: lesson.options,
          correctAnswerIndex: lesson.correctAnswerIndex,
        );

    storage.update(
      item.copyWith(
        timesSeen: item.timesSeen + 1,
        correctCount: correct ? item.correctCount + 1 : null,
        wrongCount: correct ? null : item.wrongCount + 1,
        lastReviewedAt: DateTime.now(),
      ),
    );

    state = _copyWith(items: storage.allForDeck(state.activeDeckId));
  }

  /// Starts a targeted SRS session from Exam results (Train Weakest bridge).
  ///
  /// Pass either [category]/[topic] for area-based filtering,
  /// or [questionIds] for a wrong-answers session.
  /// Items are sorted: most errors first, then least seen.
  void startSessionFromExamBridge({
    String? category,
    String? topic,
    List<String>? questionIds,
    int sessionLength = 10,
    String? lastExamAttemptId,
  }) {
    List<StudyItem> candidates;
    if (questionIds != null) {
      candidates = state.items
          .where(
            (i) =>
                i.contentType == ContentType.examQuestion &&
                questionIds.contains(i.id),
          )
          .toList();
    } else {
      candidates = state.items.where((i) {
        if (i.contentType != ContentType.examQuestion) return false;
        if (category != null && i.category != category) return false;
        if (topic != null && i.topic != topic) return false;
        return true;
      }).toList();
    }
    if (candidates.isEmpty) return;

    // Sort: highest error count first, then least seen.
    candidates.sort((a, b) {
      final cmp = (b.wrongCount + b.againCount).compareTo(
        a.wrongCount + a.againCount,
      );
      return cmp != 0 ? cmp : a.timesSeen.compareTo(b.timesSeen);
    });

    final queue = candidates.take(sessionLength).toList();

    state = StudyState(
      items: state.items,
      activeDeckId: state.activeDeckId,
      selectedCategory: category,
      selectedTopic: topic,
      selectedMode: StudyMode.srs,
      selectedQueueType: state.selectedQueueType,
      sessionLength: sessionLength,
      timerSeconds: state.timerSeconds,
      isStudying: true,
      sessionQueue: queue,
      currentIndex: 0,
      answeredInSession: 0,
      generation: state.generation + 1,
      speedResults: const [],
      wrongItemIds: const [],
      startedFromExamBridge: true,
      lastTrainedArea: questionIds != null
          ? 'wrong_answers'
          : topic != null
          ? '$category / $topic'
          : category,
      lastExamAttemptId: lastExamAttemptId,
    );
  }

  void startWeakAreasSession({
    required List<String> categories,
    int? sessionLength,
  }) {
    final normalized = {
      for (final category in categories)
        if (category.trim().isNotEmpty) category.trim(),
    }.toList(growable: false);
    if (normalized.isEmpty) return;

    final candidates = state.items.where((item) {
      if (item.contentType != ContentType.examQuestion) return false;
      return normalized.contains(item.category);
    }).toList();
    if (candidates.isEmpty) return;

    candidates.sort((a, b) {
      final totalA = a.timesSeen > 0 ? a.timesSeen : 1;
      final totalB = b.timesSeen > 0 ? b.timesSeen : 1;
      final wrongRateA = (a.wrongCount + a.againCount) / totalA;
      final wrongRateB = (b.wrongCount + b.againCount) / totalB;

      final byWrongRate = wrongRateB.compareTo(wrongRateA);
      if (byWrongRate != 0) return byWrongRate;

      final byWrongCount = (b.wrongCount + b.againCount).compareTo(
        a.wrongCount + a.againCount,
      );
      if (byWrongCount != 0) return byWrongCount;

      return a.timesSeen.compareTo(b.timesSeen);
    });

    final queueLength = min(
      sessionLength ?? state.sessionLength,
      candidates.length,
    );
    final queue = candidates.take(queueLength).toList(growable: false);
    if (queue.isEmpty) return;

    state = StudyState(
      items: state.items,
      activeDeckId: state.activeDeckId,
      selectedCategory: null,
      selectedTopic: null,
      selectedMode: StudyMode.srs,
      selectedQueueType: SessionQueueType.weak,
      sessionLength: queueLength,
      timerSeconds: state.timerSeconds,
      isStudying: true,
      sessionQueue: queue,
      currentIndex: 0,
      answeredInSession: 0,
      generation: state.generation + 1,
      speedResults: const [],
      wrongItemIds: const [],
      startedFromExamBridge: false,
      lastTrainedArea: normalized.join(', '),
      lastExamAttemptId: state.lastExamAttemptId,
    );
  }

  void _advanceSession(StudyStorage storage) {
    final items = storage.allForDeck(state.activeDeckId);
    final nextIndex = state.sessionQueue.isEmpty
        ? 0
        : (state.currentIndex + 1) % state.sessionQueue.length;
    state = StudyState(
      items: items,
      activeDeckId: state.activeDeckId,
      selectedCategory: state.selectedCategory,
      selectedTopic: state.selectedTopic,
      selectedMode: state.selectedMode,
      selectedQueueType: state.selectedQueueType,
      sessionLength: state.sessionLength,
      timerSeconds: state.timerSeconds,
      isStudying: true,
      sessionQueue: state.sessionQueue,
      currentIndex: nextIndex,
      answeredInSession: state.answeredInSession + 1,
      generation: state.generation + 1,
      speedResults: state.speedResults,
      wrongItemIds: state.wrongItemIds,
      startedFromExamBridge: state.startedFromExamBridge,
      lastTrainedArea: state.lastTrainedArea,
      lastExamAttemptId: state.lastExamAttemptId,
    );
  }

  // ── Queue builder ─────────────────────────────────────────────────────────

  /// Filters candidates to the pool appropriate for the queue type.
  static List<StudyItem> _poolForQueueType(
    List<StudyItem> candidates,
    SessionQueueType type,
  ) {
    final now = DateTime.now();
    return switch (type) {
      SessionQueueType.due =>
        candidates
            .where(
              (i) => i.nextReviewAt == null || !i.nextReviewAt!.isAfter(now),
            )
            .toList(),
      SessionQueueType.weak =>
        candidates.where((i) => i.wrongCount > 0 || i.againCount > 0).toList(),
      SessionQueueType.newCards =>
        candidates.where((i) => i.timesSeen == 0).toList(),
      SessionQueueType.random => candidates,
    };
  }

  static List<StudyItem> _buildQueue(
    List<StudyItem> candidates,
    StudyMode mode,
    SessionQueueType queueType,
    int maxLength,
  ) {
    List<StudyItem> ordered;
    switch (queueType) {
      case SessionQueueType.due:
        // For SRS: prioritise never seen > high againCount > low goodCount
        // For Speed: shuffle
        if (mode == StudyMode.speed) {
          ordered = [...candidates]..shuffle(_rng);
        } else {
          ordered = [...candidates]
            ..sort((a, b) {
              if (a.timesSeen == 0 && b.timesSeen > 0) return -1;
              if (b.timesSeen == 0 && a.timesSeen > 0) return 1;
              final cmp = b.againCount.compareTo(a.againCount);
              return cmp != 0 ? cmp : a.goodCount.compareTo(b.goodCount);
            });
        }
      case SessionQueueType.weak:
        // Sort by most wrong / most again / worst correct rate
        ordered = [...candidates]
          ..sort((a, b) {
            final totalA = a.timesSeen > 0 ? a.timesSeen : 1;
            final totalB = b.timesSeen > 0 ? b.timesSeen : 1;
            final rateA = (a.wrongCount + a.againCount) / totalA;
            final rateB = (b.wrongCount + b.againCount) / totalB;
            return rateB.compareTo(rateA); // descending: worst first
          });
      case SessionQueueType.newCards:
        ordered = [...candidates]..shuffle(_rng);
      case SessionQueueType.random:
        ordered = [...candidates]..shuffle(_rng);
    }
    final count = min(maxLength, ordered.length);
    return ordered.take(count).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static const Object _nil = Object();
  static Object _maybeNull(Object? v) => v ?? _nil;

  StudyState _copyWith({
    List<StudyItem>? items,
    Object activeDeckId = _nil,
    Object selectedCategory = _nil,
    Object selectedTopic = _nil,
    StudyMode? selectedMode,
    SessionQueueType? selectedQueueType,
    int? sessionLength,
    int? timerSeconds,
    bool? isStudying,
    List<StudyItem>? sessionQueue,
    int? currentIndex,
    int? answeredInSession,
    int? generation,
    List<SpeedResult>? speedResults,
    List<String>? wrongItemIds,
    bool? startedFromExamBridge,
    Object lastTrainedArea = _nil,
    Object lastExamAttemptId = _nil,
  }) {
    return StudyState(
      items: items ?? state.items,
      activeDeckId: identical(activeDeckId, _nil)
          ? state.activeDeckId
          : activeDeckId as String?,
      selectedCategory: identical(selectedCategory, _nil)
          ? state.selectedCategory
          : selectedCategory as String?,
      selectedTopic: identical(selectedTopic, _nil)
          ? state.selectedTopic
          : selectedTopic as String?,
      selectedMode: selectedMode ?? state.selectedMode,
      selectedQueueType: selectedQueueType ?? state.selectedQueueType,
      sessionLength: sessionLength ?? state.sessionLength,
      timerSeconds: timerSeconds ?? state.timerSeconds,
      isStudying: isStudying ?? state.isStudying,
      sessionQueue: sessionQueue ?? state.sessionQueue,
      currentIndex: currentIndex ?? state.currentIndex,
      answeredInSession: answeredInSession ?? state.answeredInSession,
      generation: generation ?? state.generation,
      speedResults: speedResults ?? state.speedResults,
      wrongItemIds: wrongItemIds ?? state.wrongItemIds,
      startedFromExamBridge:
          startedFromExamBridge ?? state.startedFromExamBridge,
      lastTrainedArea: identical(lastTrainedArea, _nil)
          ? state.lastTrainedArea
          : lastTrainedArea as String?,
      lastExamAttemptId: identical(lastExamAttemptId, _nil)
          ? state.lastExamAttemptId
          : lastExamAttemptId as String?,
    );
  }
}

final studyProvider = NotifierProvider<StudyNotifier, StudyState>(
  StudyNotifier.new,
);
