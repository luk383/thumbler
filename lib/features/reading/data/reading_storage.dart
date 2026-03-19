import 'package:hive/hive.dart';

import '../domain/reading_item.dart';

class ReadingStorage {
  static const boxName = 'reading_box';

  Box get _box => Hive.box(boxName);

  List<ReadingItem> all() => _box.values
      .whereType<Map>()
      .map((v) => ReadingItem.fromMap(v))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void save(ReadingItem item) => _box.put(item.id, item.toMap());

  void delete(String id) => _box.delete(id);
}
