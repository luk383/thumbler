import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/lesson.dart';
import '../../../study/presentation/controllers/deck_library_controller.dart';

const _kInitialFeedBatchSize = 12;
const _kAppendFeedBatchSize = 10;
const _kPrefetchThreshold = 4;
const _kRecentTailWindow = 6;

class FeedQueueNotifier extends AsyncNotifier<List<Lesson>> {
  bool _isAppending = false;

  @override
  Future<List<Lesson>> build() async {
    ref.watch(activeDeckIdProvider);
    ref.watch(deckLibraryDataVersionProvider);
    final lessons = await ref.read(lessonRepositoryProvider).fetchLessons();
    return _takeBatch(
      current: const [],
      candidates: lessons,
      desiredCount: _kInitialFeedBatchSize,
    );
  }

  Future<void> ensureNextPageAvailable(int currentIndex) async {
    final lessons = state.asData?.value;
    if (lessons == null || lessons.isEmpty) return;
    if (currentIndex < lessons.length - _kPrefetchThreshold) return;
    await _appendMore();
  }

  Future<void> _appendMore() async {
    if (_isAppending) return;
    final current = state.asData?.value;
    if (current == null || current.isEmpty) return;

    _isAppending = true;
    try {
      final candidates = await ref
          .read(lessonRepositoryProvider)
          .fetchLessons();
      if (candidates.isEmpty) return;

      final batch = _takeBatch(
        current: current,
        candidates: candidates,
        desiredCount: _kAppendFeedBatchSize,
      );
      if (batch.isEmpty) return;

      state = AsyncData([...current, ...batch]);
    } finally {
      _isAppending = false;
    }
  }

  List<Lesson> _takeBatch({
    required List<Lesson> current,
    required List<Lesson> candidates,
    required int desiredCount,
  }) {
    if (candidates.isEmpty || desiredCount <= 0) return const [];

    final batch = <Lesson>[];
    final recentTailIds = current.reversed
        .take(_kRecentTailWindow)
        .map((lesson) => lesson.id)
        .toSet();

    for (final lesson in candidates) {
      if (recentTailIds.contains(lesson.id)) continue;
      if (batch.any((item) => item.id == lesson.id)) continue;
      batch.add(lesson);
      if (batch.length >= desiredCount) return batch;
    }

    for (final lesson in candidates) {
      if (batch.any((item) => item.id == lesson.id)) continue;
      batch.add(lesson);
      if (batch.length >= desiredCount) return batch;
    }

    return batch;
  }
}

final feedQueueProvider =
    AsyncNotifierProvider<FeedQueueNotifier, List<Lesson>>(
      FeedQueueNotifier.new,
    );
