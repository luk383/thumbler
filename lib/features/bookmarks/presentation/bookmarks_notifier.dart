import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../feed/data/providers.dart';
import '../../feed/domain/lesson.dart';
import '../data/bookmarks_repository.dart';

final bookmarksRepositoryProvider = Provider<BookmarksRepository>(
  (_) => HiveBookmarksRepository(Hive.box('bookmarks_box')),
);

class BookmarksNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ref.read(bookmarksRepositoryProvider).getBookmarkedIds();
  }

  Future<void> toggle(String lessonId) async {
    await ref.read(bookmarksRepositoryProvider).toggleBookmark(lessonId);
    state = ref.read(bookmarksRepositoryProvider).getBookmarkedIds();
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
