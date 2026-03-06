import 'package:hive/hive.dart';

import '../domain/exam_attempt.dart';

class ExamAttemptStorage {
  static const boxName = 'exam_box';
  static const _activeKey = 'active';
  static const _historyKey = 'history';

  Box get _box => Hive.box(boxName);

  // ── Active attempt ────────────────────────────────────────────────────────

  ExamAttempt? loadActive() {
    final m = _box.get(_activeKey);
    if (m == null) return null;
    try {
      return ExamAttempt.fromMap(m as Map);
    } catch (_) {
      return null;
    }
  }

  void saveActive(ExamAttempt attempt) => _box.put(_activeKey, attempt.toMap());

  void clearActive() => _box.delete(_activeKey);

  // ── History ───────────────────────────────────────────────────────────────

  List<ExamAttempt> loadHistory() {
    final list = _box.get(_historyKey);
    if (list == null) return [];
    try {
      return (list as List).map((m) => ExamAttempt.fromMap(m as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Prepends attempt to history; keeps last 10.
  void addToHistory(ExamAttempt attempt) {
    final history = loadHistory()..insert(0, attempt);
    _box.put(_historyKey, history.take(10).map((a) => a.toMap()).toList());
  }

  Future<void> clearHistory() => _box.delete(_historyKey);

  Future<void> clearAll() => _box.clear();
}
