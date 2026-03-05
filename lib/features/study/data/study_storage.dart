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
}
