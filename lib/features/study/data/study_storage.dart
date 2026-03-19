import 'package:hive/hive.dart';

import '../domain/study_item.dart';

class StudyStorage {
  static const boxName = 'study_box';

  Box get _box => Hive.box(boxName);

  String _storageKey(String id, String? deckId) =>
      deckId == null ? id : '$deckId::$id';

  dynamic _findBoxKey(String id, {String? deckId}) {
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is! Map) continue;
      final item = StudyItem.fromMap(value);
      final sameDeck = deckId == null
          ? item.deckId == null
          : item.deckId == deckId;
      if (item.id == id && sameDeck) return key;
    }
    return null;
  }

  List<StudyItem> all() =>
      _box.values.whereType<Map>().map((v) => StudyItem.fromMap(v)).toList();

  List<StudyItem> allForDeck(String? deckId) => all()
      .where(
        (item) => deckId == null ? item.deckId == null : item.deckId == deckId,
      )
      .toList();

  bool contains(String id, {String? deckId}) =>
      _findBoxKey(id, deckId: deckId) != null;

  StudyItem? getById(String id, {String? deckId}) {
    final key = _findBoxKey(id, deckId: deckId);
    if (key == null) return null;
    final value = _box.get(key);
    if (value is Map) return StudyItem.fromMap(value);
    return null;
  }

  void add(StudyItem item) =>
      _box.put(_storageKey(item.id, item.deckId), item.toMap());

  void update(StudyItem item) {
    final preferredKey = _storageKey(item.id, item.deckId);
    final existingKey =
        _findBoxKey(item.id, deckId: item.deckId) ??
        (item.deckId != null ? _findBoxKey(item.id, deckId: null) : null);
    _box.put(existingKey ?? preferredKey, item.toMap());
    if (existingKey != null && existingKey != preferredKey) {
      _box.delete(existingKey);
      _box.put(preferredKey, item.toMap());
    }
  }

  void remove(String id, {String? deckId}) {
    final key = _findBoxKey(id, deckId: deckId);
    if (key != null) {
      _box.delete(key);
    }
  }

  Future<void> clearAll() => _box.clear();

  Future<void> resetProgress() async {
    for (final item in all()) {
      update(
        item.copyWith(
          againCount: 0,
          goodCount: 0,
          timesSeen: 0,
          correctCount: 0,
          wrongCount: 0,
          avgTimeMs: null,
          nextReviewAt: null,
          lastReviewedAt: null,
          easeFactor: 2.5,
          srsInterval: 0,
          srsRepetitions: 0,
        ),
      );
    }
  }
}
