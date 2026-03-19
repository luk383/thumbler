import 'package:hive/hive.dart';

import '../domain/reflection_entry.dart';

class ReflectionStorage {
  static const boxName = 'reflection_box';

  Box get _box => Hive.box(boxName);

  List<ReflectionEntry> all() => _box.values
      .whereType<Map>()
      .map((v) => ReflectionEntry.fromMap(v))
      .toList()
    ..sort((a, b) => b.weekStart.compareTo(a.weekStart));

  ReflectionEntry? forWeek(DateTime weekStart) {
    final key = weekStart.toIso8601String();
    final value = _box.get(key);
    if (value is Map) return ReflectionEntry.fromMap(value);
    return null;
  }

  void save(ReflectionEntry entry) =>
      _box.put(entry.weekStart.toIso8601String(), entry.toMap());
}
