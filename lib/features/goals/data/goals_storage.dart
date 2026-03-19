import 'package:hive/hive.dart';

import '../domain/goal.dart';

class GoalsStorage {
  static const boxName = 'goals_box';

  Box get _box => Hive.box(boxName);

  List<Goal> all() => _box.values
      .whereType<Map>()
      .map((v) => Goal.fromMap(v))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void save(Goal goal) => _box.put(goal.id, goal.toMap());

  void delete(String id) => _box.delete(id);
}
