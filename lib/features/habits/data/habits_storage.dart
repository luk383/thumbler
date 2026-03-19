import 'package:hive/hive.dart';

import '../domain/habit.dart';

class HabitsStorage {
  static const boxName = 'habits_box';

  Box get _box => Hive.box(boxName);

  List<Habit> all() => _box.values
      .whereType<Map>()
      .map((v) => Habit.fromMap(v))
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  void save(Habit habit) => _box.put(habit.id, habit.toMap());

  void delete(String id) => _box.delete(id);
}
