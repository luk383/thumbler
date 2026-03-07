import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/lesson.dart';
import 'lesson_repository.dart';
import 'feed_session_memory.dart';
import '../../analytics/presentation/providers/progress_analytics_provider.dart';
import '../../study/data/deck_pack.dart';
import '../../study/domain/study_item.dart';
import '../../study/data/study_storage.dart';
import '../../study/presentation/controllers/study_controller.dart';
import '../../study/presentation/controllers/deck_library_controller.dart';

final feedSessionMemoryProvider = Provider<FeedSessionMemory>(
  (ref) => FeedSessionMemory(),
);

final feedDeckMetaProvider = Provider<DeckPackMeta?>((ref) {
  final library = ref.watch(deckLibraryProvider);
  return resolveFeedDeckMeta(
    packs: library.packs,
    activeDeckId: library.activeDeckId,
  );
});

final feedSourceItemsProvider = FutureProvider<List<StudyItem>>((ref) async {
  final meta = ref.watch(feedDeckMetaProvider);
  if (meta == null) return const [];

  final pack = await DeckPack.load(meta);
  return pack.items
      .map((item) => item.toStudyItem(meta.id))
      .toList(growable: false);
});

final feedProgressItemsProvider = Provider<List<StudyItem>>((ref) {
  ref.watch(studyProvider.select((state) => state.items));
  final deckId = ref.watch(feedDeckMetaProvider.select((meta) => meta?.id));
  if (deckId == null) return const [];
  return StudyStorage().allForDeck(deckId);
});

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LocalDeckLessonRepository(
    deckId: ref.watch(feedDeckMetaProvider.select((meta) => meta?.id)),
    sourceItems: ref
        .watch(feedSourceItemsProvider)
        .maybeWhen(data: (items) => items, orElse: () => const []),
    progressItems: ref.watch(feedProgressItemsProvider),
    weakestDomains: ref.watch(
      progressAnalyticsProvider.select(
        (analytics) =>
            analytics.weakestDomains.map((summary) => summary.domain).toList(),
      ),
    ),
    sessionMemory: ref.watch(feedSessionMemoryProvider),
  ),
);

final lessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  await ref.watch(feedSourceItemsProvider.future);
  return ref.watch(lessonRepositoryProvider).fetchLessons();
});
