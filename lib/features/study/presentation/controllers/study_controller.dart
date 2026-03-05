import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/feed/domain/lesson.dart';
import '../../data/study_storage.dart';
import '../../domain/study_item.dart';

// ---------------------------------------------------------------------------
// Study mode enum
// ---------------------------------------------------------------------------

enum StudyMode {
  random,
  weak,
  newOnly;

  String get label => switch (this) {
        StudyMode.random => 'Random',
        StudyMode.weak => 'Weak',
        StudyMode.newOnly => 'New',
      };

  IconData get icon => switch (this) {
        StudyMode.random => Icons.shuffle,
        StudyMode.weak => Icons.psychology_outlined,
        StudyMode.newOnly => Icons.fiber_new_outlined,
      };
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class StudyState {
  const StudyState({
    this.items = const [],
    this.selectedCategory,
    this.selectedMode = StudyMode.random,
    this.isStudying = false,
    this.sessionQueue = const [],
    this.currentIndex = 0,
    this.answeredInSession = 0,
    this.generation = 0,
  });

  final List<StudyItem> items;

  /// null = All categories.
  final String? selectedCategory;
  final StudyMode selectedMode;

  /// true = session screen is active.
  final bool isStudying;

  /// Ordered queue built at session start.
  final List<StudyItem> sessionQueue;
  final int currentIndex;

  /// How many cards have been rated in the current session.
  final int answeredInSession;

  /// Increments on every advance to force card widget rebuild via ValueKey.
  final int generation;

  // ── Derived ───────────────────────────────────────────────────────────────

  /// Candidates for the current category selection (setup screen).
  List<StudyItem> get filtered => selectedCategory == null
      ? items
      : items.where((i) => i.category == selectedCategory).toList();

  List<String> get categories =>
      ({for (final i in items) i.category}).toList()..sort();

  bool inDeck(String lessonId) => items.any((i) => i.lessonId == lessonId);

  StudyItem? get currentItem => sessionQueue.isEmpty
      ? null
      : sessionQueue[currentIndex.clamp(0, sessionQueue.length - 1)];

  bool get sessionComplete =>
      isStudying && answeredInSession >= sessionQueue.length;

  /// Estimated minutes at ~3 cards/min.
  int get estimatedMinutes => (filtered.length / 3).ceil().clamp(1, 999);
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
    StudyStorage().add(StudyItem(
      lessonId: lesson.id,
      category: lesson.category,
      addedAt: DateTime.now().toIso8601String().substring(0, 10),
    ));
    state = _copyWith(items: StudyStorage().all());
  }

  void removeLesson(String lessonId) {
    StudyStorage().remove(lessonId);
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
      isStudying: false,
      sessionQueue: const [],
      currentIndex: 0,
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

  // ── Session ───────────────────────────────────────────────────────────────

  void startSession() {
    final queue = _buildQueue(state.filtered, state.selectedMode);
    if (queue.isEmpty) return;
    state = StudyState(
      items: state.items,
      selectedCategory: state.selectedCategory,
      selectedMode: state.selectedMode,
      isStudying: true,
      sessionQueue: queue,
      currentIndex: 0,
      answeredInSession: 0,
      generation: state.generation + 1,
    );
  }

  void stopSession() {
    state = _copyWith(
      isStudying: false,
      sessionQueue: const [],
      currentIndex: 0,
      answeredInSession: 0,
    );
  }

  /// Mark current card as Again (needs review) or Good (learned).
  void rate(String lessonId, {required bool again}) {
    final storage = StudyStorage();
    final item = state.items.firstWhere(
      (i) => i.lessonId == lessonId,
      orElse: () => state.items.first,
    );
    storage.update(item.copyWith(
      againCount: again ? item.againCount + 1 : null,
      goodCount: again ? null : item.goodCount + 1,
    ));
    _advanceSession(storage);
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
      selectedMode: state.selectedMode,
      isStudying: true,
      sessionQueue: state.sessionQueue,
      currentIndex: nextIndex,
      answeredInSession: state.answeredInSession + 1,
      generation: state.generation + 1,
    );
  }

  // ── Queue builder ─────────────────────────────────────────────────────────

  static List<StudyItem> _buildQueue(
      List<StudyItem> candidates, StudyMode mode) {
    switch (mode) {
      case StudyMode.random:
        return [...candidates]..shuffle(_rng);

      case StudyMode.weak:
        // Highest againCount first; ties broken by fewest goods.
        return [...candidates]..sort((a, b) {
            final cmp = b.againCount.compareTo(a.againCount);
            return cmp != 0 ? cmp : a.goodCount.compareTo(b.goodCount);
          });

      case StudyMode.newOnly:
        final newItems = candidates
            .where((i) => i.againCount == 0 && i.goodCount == 0)
            .toList()
          ..shuffle(_rng);
        // Fallback to all if no truly-new items.
        return newItems.isNotEmpty ? newItems : ([...candidates]..shuffle(_rng));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Sentinel trick so copyWith can explicitly set nullable fields to null.
  static const Object _nil = Object();

  static Object _maybeNull(Object? v) => v ?? _nil;

  StudyState _copyWith({
    List<StudyItem>? items,
    Object selectedCategory = _nil,
    StudyMode? selectedMode,
    bool? isStudying,
    List<StudyItem>? sessionQueue,
    int? currentIndex,
    int? answeredInSession,
    int? generation,
  }) {
    return StudyState(
      items: items ?? state.items,
      selectedCategory: identical(selectedCategory, _nil)
          ? state.selectedCategory
          : selectedCategory as String?,
      selectedMode: selectedMode ?? state.selectedMode,
      isStudying: isStudying ?? state.isStudying,
      sessionQueue: sessionQueue ?? state.sessionQueue,
      currentIndex: currentIndex ?? state.currentIndex,
      answeredInSession: answeredInSession ?? state.answeredInSession,
      generation: generation ?? state.generation,
    );
  }
}

final studyProvider =
    NotifierProvider<StudyNotifier, StudyState>(StudyNotifier.new);
