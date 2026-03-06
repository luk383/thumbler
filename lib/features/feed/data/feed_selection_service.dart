import '../../study/domain/study_item.dart';
import '../domain/lesson.dart';

class SmartFeedSelectionService {
  const SmartFeedSelectionService();

  List<Lesson> selectLessons({
    required List<StudyItem> items,
    required List<String> weakestDomains,
    DateTime? now,
  }) {
    final uniqueItems = _dedupeItems(items);
    if (uniqueItems.isEmpty) return const [];

    final current = now ?? DateTime.now();
    final normalizedWeakestDomains = {
      for (final domain in weakestDomains)
        if (domain.trim().isNotEmpty) domain.trim(),
    }.toList(growable: false);
    final weakestRank = <String, int>{
      for (var i = 0; i < normalizedWeakestDomains.length; i++)
        normalizedWeakestDomains[i]: i,
    };

    final scored = uniqueItems
        .map(
          (item) => _ScoredFeedItem(
            item: item,
            bucket: _bucketFor(item, weakestRank),
            priorityScore: _priorityScore(item, weakestRank, current),
            stableJitter: _stableJitter(item.id, current, item.deckId),
          ),
        )
        .toList()
      ..sort((a, b) {
        final byBucket = a.bucket.compareTo(b.bucket);
        if (byBucket != 0) return byBucket;

        final byPriority = b.priorityScore.compareTo(a.priorityScore);
        if (byPriority != 0) return byPriority;

        final byJitter = a.stableJitter.compareTo(b.stableJitter);
        if (byJitter != 0) return byJitter;

        return a.item.id.compareTo(b.item.id);
      });

    final diversified = _diversifyAcrossBuckets(scored);
    return diversified.map(_toLesson).toList();
  }

  int _bucketFor(StudyItem item, Map<String, int> weakestRank) {
    if (item.timesSeen == 0) return 0;
    if (item.wrongCount > 0 || item.againCount > 0) return 1;
    if (weakestRank.containsKey(item.category)) return 2;
    return 3;
  }

  double _priorityScore(
    StudyItem item,
    Map<String, int> weakestRank,
    DateTime now,
  ) {
    final totalSeen = item.timesSeen <= 0 ? 1 : item.timesSeen;
    final wrongPressure = (item.wrongCount + item.againCount) / totalSeen;
    final weakestBoost = weakestRank[item.category] == null
        ? 0.0
        : (weakestRank.length - weakestRank[item.category]!) * 4.0;
    final difficultyBoost = (item.difficulty ?? 1).toDouble();
    final recencyPenalty = _recentPenalty(item.lastReviewedAt, now);
    final seenPenalty = item.timesSeen * 1.5;

    if (item.timesSeen == 0) {
      return 1000 + difficultyBoost + weakestBoost;
    }

    if (item.wrongCount > 0 || item.againCount > 0) {
      return 700 +
          (item.wrongCount * 12) +
          (item.againCount * 8) +
          (wrongPressure * 100) +
          weakestBoost -
          recencyPenalty -
          seenPenalty;
    }

    if (weakestRank.containsKey(item.category)) {
      return 400 + weakestBoost + difficultyBoost - recencyPenalty - seenPenalty;
    }

    return 100 + difficultyBoost - recencyPenalty - seenPenalty;
  }

  double _recentPenalty(DateTime? lastReviewedAt, DateTime now) {
    if (lastReviewedAt == null) return 0;
    final ageHours = now.difference(lastReviewedAt).inHours;
    if (ageHours < 1) return 120;
    if (ageHours < 6) return 60;
    if (ageHours < 24) return 24;
    if (ageHours < 72) return 8;
    return 0;
  }

  int _stableJitter(String id, DateTime now, String? deckId) {
    final daySeed = '${now.year}-${now.month}-${now.day}:${deckId ?? 'none'}:$id';
    return daySeed.codeUnits.fold<int>(0, (sum, unit) => (sum * 31 + unit) & 0x7fffffff);
  }

  List<StudyItem> _diversifyAcrossBuckets(List<_ScoredFeedItem> scored) {
    final result = <StudyItem>[];

    var start = 0;
    while (start < scored.length) {
      final bucket = scored[start].bucket;
      var end = start;
      while (end < scored.length && scored[end].bucket == bucket) {
        end++;
      }
      result.addAll(_diversifyWithinBucket(scored.sublist(start, end)));
      start = end;
    }

    return result;
  }

  List<StudyItem> _diversifyWithinBucket(List<_ScoredFeedItem> bucketItems) {
    final remaining = [...bucketItems];
    final result = <StudyItem>[];
    final recentDomains = <String>[];

    while (remaining.isNotEmpty) {
      final pickedIndex = remaining.indexWhere(
        (candidate) => !recentDomains.contains(candidate.item.category),
      );
      final next = remaining.removeAt(pickedIndex == -1 ? 0 : pickedIndex);
      result.add(next.item);

      recentDomains.add(next.item.category);
      if (recentDomains.length > 2) {
        recentDomains.removeAt(0);
      }
    }

    return result;
  }

  List<StudyItem> _dedupeItems(List<StudyItem> items) {
    final seenIds = <String>{};
    final seenPrompts = <String>{};
    final unique = <StudyItem>[];

    for (final item in items) {
      final promptKey = item.promptText.trim().toLowerCase();
      if (!seenIds.add(item.id)) continue;
      if (promptKey.isNotEmpty && !seenPrompts.add(promptKey)) continue;
      unique.add(item);
    }

    return unique;
  }

  Lesson _toLesson(StudyItem item) => Lesson(
    id: item.id,
    hook: item.promptText,
    explanation:
        item.explanationText ??
        'Review the correct answer and keep practicing this topic.',
    quizQuestion: item.promptText,
    options: item.options,
    correctAnswerIndex: item.correctAnswerIndex,
    category: item.category,
  );
}

class _ScoredFeedItem {
  const _ScoredFeedItem({
    required this.item,
    required this.bucket,
    required this.priorityScore,
    required this.stableJitter,
  });

  final StudyItem item;
  final int bucket;
  final double priorityScore;
  final int stableJitter;
}
