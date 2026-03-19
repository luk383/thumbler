import 'package:hive/hive.dart';

import '../domain/study_session.dart';

class StudySessionStorage {
  static const boxName = 'study_sessions_box';

  Box get _box => Hive.box(boxName);

  Future<void> save(StudySession session) =>
      _box.put(session.id, session.toMap());

  List<StudySession> getAll() {
    return _box.values
        .whereType<Map>()
        .map((v) => StudySession.fromMap(v))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<StudySession> getLast7Days() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return getAll()
        .where((s) => s.date.isAfter(cutoff))
        .toList();
  }

  Future<void> clearAll() => _box.clear();
}
