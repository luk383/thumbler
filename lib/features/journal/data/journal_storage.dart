import 'package:hive/hive.dart';

import '../domain/journal_entry.dart';

class JournalStorage {
  static const boxName = 'journal_box';

  Box get _box => Hive.box(boxName);

  List<JournalEntry> all() => _box.values
      .whereType<Map>()
      .map((v) => JournalEntry.fromMap(v))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void save(JournalEntry entry) => _box.put(entry.id, entry.toMap());

  void delete(String id) => _box.delete(id);
}
