import 'package:hive_flutter/hive_flutter.dart';

// TODO: Replace HiveBookmarksRepository with SupabaseBookmarksRepository
abstract interface class BookmarksRepository {
  List<String> getBookmarkedIds();
  Future<void> toggleBookmark(String lessonId);
  bool isBookmarked(String lessonId);
}

class HiveBookmarksRepository implements BookmarksRepository {
  HiveBookmarksRepository(this._box);

  final Box _box;

  static const _key = 'ids';

  @override
  List<String> getBookmarkedIds() {
    final raw = _box.get(_key, defaultValue: <dynamic>[]);
    return List<String>.from(raw as List);
  }

  @override
  Future<void> toggleBookmark(String lessonId) async {
    final ids = getBookmarkedIds();
    if (ids.contains(lessonId)) {
      ids.remove(lessonId);
    } else {
      ids.add(lessonId);
    }
    await _box.put(_key, ids);
  }

  @override
  bool isBookmarked(String lessonId) => getBookmarkedIds().contains(lessonId);
}
