import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../feed/data/providers.dart';
import '../../feed/domain/lesson.dart';
import '../../study/data/deck_pack.dart';
import '../../study/presentation/controllers/deck_library_controller.dart';
import '../data/bookmarks_repository.dart';

final bookmarksRepositoryProvider = Provider<BookmarksRepository>(
  (_) => HiveBookmarksRepository(Hive.box('bookmarks_box')),
);

class BookmarksNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final activeDeck = ref.watch(activeDeckMetaProvider);
    final activeDeckId = ref.watch(activeDeckIdProvider);
    return ref
        .read(bookmarksRepositoryProvider)
        .getBookmarkedIds(
          deckId: activeDeckId,
          includeLegacy: _shouldIncludeLegacyBookmarks(activeDeck),
        );
  }

  Future<void> toggle(String lessonId) async {
    final activeDeck = ref.read(activeDeckMetaProvider);
    final activeDeckId = ref.read(activeDeckIdProvider);
    await ref
        .read(bookmarksRepositoryProvider)
        .toggleBookmark(lessonId, deckId: activeDeckId);
    state = ref
        .read(bookmarksRepositoryProvider)
        .getBookmarkedIds(
          deckId: activeDeckId,
          includeLegacy: _shouldIncludeLegacyBookmarks(activeDeck),
        );
  }

  void reloadFromStorage() {
    final activeDeck = ref.read(activeDeckMetaProvider);
    final activeDeckId = ref.read(activeDeckIdProvider);
    state = ref
        .read(bookmarksRepositoryProvider)
        .getBookmarkedIds(
          deckId: activeDeckId,
          includeLegacy: _shouldIncludeLegacyBookmarks(activeDeck),
        );
  }

  bool isBookmarked(String lessonId) => state.contains(lessonId);
}

final bookmarksProvider =
    NotifierProvider<BookmarksNotifier, List<String>>(BookmarksNotifier.new);

/// Derived: full Lesson objects for bookmarked ids.
final bookmarkedLessonsProvider = Provider<AsyncValue<List<Lesson>>>((ref) {
  final bookmarkedIds = ref.watch(bookmarksProvider);
  return ref.watch(lessonsProvider).whenData(
    (lessons) => lessons.where((l) => bookmarkedIds.contains(l.id)).toList(),
  );
});

bool _shouldIncludeLegacyBookmarks(DeckPackMeta? activeDeck) {
  if (activeDeck == null) return true;
  return activeDeck.examCode == 'SY0-701' ||
      activeDeck.id.toLowerCase().contains('sec701') ||
      activeDeck.title.toLowerCase().contains('security+');
}
