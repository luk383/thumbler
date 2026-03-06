import 'package:hive/hive.dart';

import '../domain/exam_result.dart';

class ExamHistoryStorage {
  static const boxName = 'exam_box';
  static const _resultsKey = 'results';

  Box get _box => Hive.box(boxName);

  List<ExamResult> loadResults() {
    final list = _box.get(_resultsKey);
    if (list == null) return [];
    try {
      return (list as List)
          .map((item) => ExamResult.fromMap(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void addResult(ExamResult result) {
    final results = loadResults()
      ..removeWhere((existing) => existing.id == result.id)
      ..insert(0, result);
    _box.put(_resultsKey, results.take(50).map((e) => e.toMap()).toList());
  }

  void removeResult(String resultId) {
    final results = loadResults()..removeWhere((result) => result.id == resultId);
    _box.put(_resultsKey, results.map((e) => e.toMap()).toList());
  }

  void clearResultsForDeck(String? deckId) {
    final results = loadResults()
      ..removeWhere(
        (result) =>
            deckId == null ? result.deckId == null : result.deckId == deckId,
      );
    _box.put(_resultsKey, results.map((e) => e.toMap()).toList());
  }

  void replaceResults(List<ExamResult> results) {
    _box.put(_resultsKey, results.map((e) => e.toMap()).toList());
  }

  Future<void> clearResults() => _box.delete(_resultsKey);
}
