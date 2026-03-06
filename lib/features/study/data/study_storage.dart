import 'package:hive/hive.dart';

import '../domain/study_item.dart';

class StudyStorage {
  static const boxName = 'study_box';

  Box get _box => Hive.box(boxName);

  List<StudyItem> all() =>
      _box.values.map((v) => StudyItem.fromMap(v as Map)).toList();

  bool contains(String id) => _box.containsKey(id);

  void add(StudyItem item) => _box.put(item.id, item.toMap());

  void update(StudyItem item) => _box.put(item.id, item.toMap());

  void remove(String id) => _box.delete(id);

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
        ),
      );
    }
  }
}
