import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/feed/data/mock_lessons.dart';
import '../../../../features/feed/domain/lesson.dart';
import '../../data/study_storage.dart';
import '../../domain/study_item.dart';

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
    this.selectedCategory,
    this.selectedTopic,
    this.selectedMode = StudyMode.srs,
    this.sessionLength = 10,
    this.timerSeconds = 8,
    this.isStudying = false,
    this.sessionQueue = const [],
    this.currentIndex = 0,
    this.answeredInSession = 0,
    this.generation = 0,
    this.speedResults = const [],
    this.wrongItemIds = const [],
  });

  final List<StudyItem> items;

  /// null = All categories.
  final String? selectedCategory;

  /// null = All topics within the selected category.
  final String? selectedTopic;

  final StudyMode selectedMode;

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
    return ({for (final i in byCategory) if (i.topic != null) i.topic!})
        .toList()
      ..sort();
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
        .where((i) =>
            i.nextReviewAt == null || !i.nextReviewAt!.isAfter(now))
        .length;
  }

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
  int get speedCorrect =>
      speedResults.where((r) => r.correct).length;
  int get speedWrong =>
      speedResults.where((r) => !r.correct).length;
  int get speedAvgMs {
    if (speedResults.isEmpty) return 0;
    return speedResults.map((r) => r.timeMs).reduce((a, b) => a + b) ~/
        speedResults.length;
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class StudyNotifier extends Notifier<StudyState> {
  static final _rng = Random();

  @override
  StudyState build() => StudyState(items: StudyStorage().all());

  // ── Deck management ───────────────────────────────────────────────────────

  void addLesson(Lesson lesson) {
    if (state.inDeck(lesson.id)) return;
    StudyStorage().add(StudyItem.fromLesson(
      id: lesson.id,
      category: lesson.category,
      hook: lesson.hook,
      explanation: lesson.explanation,
      options: lesson.options,
      correctAnswerIndex: lesson.correctAnswerIndex,
    ));
    state = _copyWith(items: StudyStorage().all());
  }

  /// Seeds the deck with up to 5 starter cards from mockLessons (no duplicates).
  void seedStarterCards() {
    final storage = StudyStorage();
    var added = 0;
    for (final lesson in mockLessons) {
      if (added >= 5) break;
      if (!state.inDeck(lesson.id)) {
        storage.add(StudyItem.fromLesson(
          id: lesson.id,
          category: lesson.category,
          hook: lesson.hook,
          explanation: lesson.explanation,
          options: lesson.options,
          correctAnswerIndex: lesson.correctAnswerIndex,
        ));
        added++;
      }
    }
    state = _copyWith(items: storage.all());
  }

  void removeItem(String id) {
    StudyStorage().remove(id);
    state = _copyWith(
      items: StudyStorage().all(),
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
    state = _copyWith(items: StudyStorage().all());
  }

  void setMode(StudyMode mode) {
    state = _copyWith(
      selectedMode: mode,
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

  // ── Session ───────────────────────────────────────────────────────────────

  void startSession({bool reviewAnyway = false, List<String>? retryIds}) {
    final candidates = retryIds != null
        ? state.items.where((i) => retryIds.contains(i.id)).toList()
        : state.filtered;

    // SRS: by default only show cards that are due; reviewAnyway bypasses filter.
    final pool = (state.selectedMode == StudyMode.srs && !reviewAnyway)
        ? _dueCards(candidates)
        : candidates;

    final queue = _buildQueue(pool, state.selectedMode, state.sessionLength);
    if (queue.isEmpty) return;
    state = StudyState(
      items: state.items,
      selectedCategory: state.selectedCategory,
      selectedTopic: state.selectedTopic,
      selectedMode: state.selectedMode,
      sessionLength: state.sessionLength,
      timerSeconds: state.timerSeconds,
      isStudying: true,
      sessionQueue: queue,
      currentIndex: 0,
      answeredInSession: 0,
      generation: state.generation + 1,
      speedResults: const [],
      wrongItemIds: const [],
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
    );
  }

  /// SRS: rate the current card and schedule next review.
  /// TODO: replace interval logic with SM-2 algorithm (SRS v2)
  void rate(String id, {required SrsRating rating}) {
    final storage = StudyStorage();
    final item = state.items.firstWhere(
      (i) => i.id == id,
      orElse: () => state.items.first,
    );
    final wrong = rating == SrsRating.again;
    storage.update(item.copyWith(
      againCount: wrong ? item.againCount + 1 : null,
      goodCount: wrong ? null : item.goodCount + 1,
      timesSeen: item.timesSeen + 1,
      correctCount: wrong ? null : item.correctCount + 1,
      wrongCount: wrong ? item.wrongCount + 1 : null,
      lastReviewedAt: DateTime.now(),
      nextReviewAt: _nextReview(rating),
    ));
    _advanceSession(storage);
  }

  /// Computes the next review timestamp from the given SRS rating.
  static DateTime _nextReview(SrsRating rating) {
    final now = DateTime.now();
    return switch (rating) {
      SrsRating.again => now.add(const Duration(minutes: 10)),
      SrsRating.good  => now.add(const Duration(days: 2)),
      SrsRating.easy  => now.add(const Duration(days: 7)),
    };
  }

  /// Returns only items whose nextReviewAt is null or in the past.
  static List<StudyItem> _dueCards(List<StudyItem> items) {
    final now = DateTime.now();
    return items
        .where((i) => i.nextReviewAt == null || !i.nextReviewAt!.isAfter(now))
        .toList();
  }

  /// Speed: record result, persist stats, advance.
  void recordSpeedAnswer(
      String id, {required bool correct, required int timeMs, required bool timedOut}) {
    final storage = StudyStorage();
    final item = state.items.firstWhere(
      (i) => i.id == id,
      orElse: () => state.items.first,
    );

    // Update running avgTimeMs
    final newAvg = item.avgTimeMs == null
        ? timeMs
        : ((item.avgTimeMs! * item.timesSeen + timeMs) ~/
            (item.timesSeen + 1));

    storage.update(item.copyWith(
      timesSeen: item.timesSeen + 1,
      correctCount: correct ? item.correctCount + 1 : null,
      wrongCount: correct ? null : item.wrongCount + 1,
      avgTimeMs: newAvg,
      lastReviewedAt: DateTime.now(),
    ));

    final newResult = SpeedResult(
      itemId: id,
      correct: correct,
      timeMs: timeMs,
      timedOut: timedOut,
    );
    final newResults = [...state.speedResults, newResult];
    final newWrong = correct
        ? state.wrongItemIds
        : [...state.wrongItemIds, id];

    final items = storage.all();
    final nextIndex = state.sessionQueue.isEmpty
        ? 0
        : (state.currentIndex + 1) % state.sessionQueue.length;

    state = StudyState(
      items: items,
      selectedCategory: state.selectedCategory,
      selectedTopic: state.selectedTopic,
      selectedMode: state.selectedMode,
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

  void _advanceSession(StudyStorage storage) {
    final items = storage.all();
    final nextIndex = state.sessionQueue.isEmpty
        ? 0
        : (state.currentIndex + 1) % state.sessionQueue.length;
    state = StudyState(
      items: items,
      selectedCategory: state.selectedCategory,
      selectedTopic: state.selectedTopic,
      selectedMode: state.selectedMode,
      sessionLength: state.sessionLength,
      timerSeconds: state.timerSeconds,
      isStudying: true,
      sessionQueue: state.sessionQueue,
      currentIndex: nextIndex,
      answeredInSession: state.answeredInSession + 1,
      generation: state.generation + 1,
      speedResults: state.speedResults,
      wrongItemIds: state.wrongItemIds,
    );
  }

  // ── Queue builder ─────────────────────────────────────────────────────────

  static List<StudyItem> _buildQueue(
      List<StudyItem> candidates, StudyMode mode, int maxLength) {
    List<StudyItem> ordered;
    switch (mode) {
      case StudyMode.srs:
        // Prioritise: never seen > high againCount > low goodCount
        ordered = [...candidates]..sort((a, b) {
            if (a.timesSeen == 0 && b.timesSeen > 0) return -1;
            if (b.timesSeen == 0 && a.timesSeen > 0) return 1;
            final cmp = b.againCount.compareTo(a.againCount);
            return cmp != 0 ? cmp : a.goodCount.compareTo(b.goodCount);
          });
      case StudyMode.speed:
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
    Object selectedCategory = _nil,
    Object selectedTopic = _nil,
    StudyMode? selectedMode,
    int? sessionLength,
    int? timerSeconds,
    bool? isStudying,
    List<StudyItem>? sessionQueue,
    int? currentIndex,
    int? answeredInSession,
    int? generation,
    List<SpeedResult>? speedResults,
    List<String>? wrongItemIds,
  }) {
    return StudyState(
      items: items ?? state.items,
      selectedCategory: identical(selectedCategory, _nil)
          ? state.selectedCategory
          : selectedCategory as String?,
      selectedTopic: identical(selectedTopic, _nil)
          ? state.selectedTopic
          : selectedTopic as String?,
      selectedMode: selectedMode ?? state.selectedMode,
      sessionLength: sessionLength ?? state.sessionLength,
      timerSeconds: timerSeconds ?? state.timerSeconds,
      isStudying: isStudying ?? state.isStudying,
      sessionQueue: sessionQueue ?? state.sessionQueue,
      currentIndex: currentIndex ?? state.currentIndex,
      answeredInSession: answeredInSession ?? state.answeredInSession,
      generation: generation ?? state.generation,
      speedResults: speedResults ?? state.speedResults,
      wrongItemIds: wrongItemIds ?? state.wrongItemIds,
    );
  }
}

final studyProvider =
    NotifierProvider<StudyNotifier, StudyState>(StudyNotifier.new);
