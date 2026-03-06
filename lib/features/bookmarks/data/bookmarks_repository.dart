import 'package:hive_flutter/hive_flutter.dart';

// TODO: Replace HiveBookmarksRepository with SupabaseBookmarksRepository
abstract interface class BookmarksRepository {
  List<String> getBookmarkedIds({String? deckId, bool includeLegacy});
  List<String> getAllBookmarkedIds();
  Future<void> toggleBookmark(String lessonId, {String? deckId});
  bool isBookmarked(String lessonId, {String? deckId, bool includeLegacy});
}

class HiveBookmarksRepository implements BookmarksRepository {
  HiveBookmarksRepository(this._box);

  final Box _box;

  static const _key = 'ids';

  @override
  List<String> getBookmarkedIds({
    String? deckId,
    bool includeLegacy = false,
  }) {
    final raw = _box.get(_key, defaultValue: <dynamic>[]);
    final ids = List<String>.from(raw as List);
    return ids
        .where(
          (value) => _belongsToDeck(
            value,
            deckId: deckId,
            includeLegacy: includeLegacy,
          ),
        )
        .map(_lessonIdFromStoredValue)
        .toList();
  }

  @override
  List<String> getAllBookmarkedIds() {
    final raw = _box.get(_key, defaultValue: <dynamic>[]);
    final ids = List<String>.from(raw as List);
    return ids.map(_lessonIdFromStoredValue).toSet().toList()..sort();
  }

  @override
  Future<void> toggleBookmark(String lessonId, {String? deckId}) async {
    final raw = _box.get(_key, defaultValue: <dynamic>[]);
    final ids = List<String>.from(raw as List);
    final scopedId = _storageKey(lessonId, deckId: deckId);

    if (ids.contains(scopedId)) {
      ids.remove(scopedId);
    } else if (deckId == null && ids.contains(lessonId)) {
      ids.remove(lessonId);
    } else {
      ids.add(scopedId);
    }
    await _box.put(_key, ids);
  }

  @override
  bool isBookmarked(
    String lessonId, {
    String? deckId,
    bool includeLegacy = false,
  }) => getBookmarkedIds(
    deckId: deckId,
    includeLegacy: includeLegacy,
  ).contains(lessonId);

  String _storageKey(String lessonId, {String? deckId}) =>
      deckId == null ? lessonId : '$deckId::$lessonId';

  bool _belongsToDeck(
    String value, {
    String? deckId,
    required bool includeLegacy,
  }) {
    if (!value.contains('::')) return deckId == null || includeLegacy;
    final splitIndex = value.indexOf('::');
    final storedDeckId = value.substring(0, splitIndex);
    return storedDeckId == deckId;
  }

  String _lessonIdFromStoredValue(String value) {
    if (!value.contains('::')) return value;
    final splitIndex = value.indexOf('::');
    return value.substring(splitIndex + 2);
  }
}
