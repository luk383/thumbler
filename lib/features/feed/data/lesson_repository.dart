import '../domain/lesson.dart';
import 'mock_lessons.dart';
import '../../study/domain/study_item.dart';
import '../../study/data/deck_pack.dart';
import 'feed_selection_service.dart';
import 'feed_session_memory.dart';

abstract interface class LessonRepository {
  Future<List<Lesson>> fetchLessons();
}

class MockLessonRepository implements LessonRepository {
  @override
  Future<List<Lesson>> fetchLessons() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return mockLessons;
  }
}

class LocalDeckLessonRepository implements LessonRepository {
  const LocalDeckLessonRepository({
    required this.deckId,
    required this.sourceItems,
    required this.progressItems,
    required this.weakestDomains,
    required this.sessionMemory,
  });

  final String? deckId;
  final List<StudyItem> sourceItems;
  final List<StudyItem> progressItems;
  final List<String> weakestDomains;
  final FeedSessionMemory sessionMemory;

  @override
  Future<List<Lesson>> fetchLessons() async {
    final eligibleItems = _mergeSourceWithProgress()
        .where(_isFeedReady)
        .toList(growable: false);
    if (eligibleItems.isEmpty) return const [];

    final lessons = const SmartFeedSelectionService().selectLessons(
      items: eligibleItems,
      weakestDomains: weakestDomains,
      recentLessonIds: sessionMemory.recentIdsForDeck(deckId),
    );
    sessionMemory.rememberSelection(
      deckId,
      lessons.map((lesson) => lesson.id).toList(growable: false),
    );
    return lessons;
  }

  List<StudyItem> _mergeSourceWithProgress() {
    final progressById = <String, StudyItem>{
      for (final item in progressItems) item.id: item,
    };

    if (sourceItems.isNotEmpty) {
      return sourceItems
          .where((item) => deckId == null || item.deckId == deckId)
          .map((item) {
            final progress = progressById[item.id];
            if (progress == null) return item;
            return item.copyWith(
              againCount: progress.againCount,
              goodCount: progress.goodCount,
              timesSeen: progress.timesSeen,
              correctCount: progress.correctCount,
              wrongCount: progress.wrongCount,
              avgTimeMs: progress.avgTimeMs,
              nextReviewAt: progress.nextReviewAt,
              lastReviewedAt: progress.lastReviewedAt,
            );
          })
          .toList(growable: false);
    }

    return progressItems
        .where((item) => deckId == null || item.deckId == deckId)
        .toList(growable: false);
  }

  bool _isFeedReady(StudyItem item) {
    if (item.promptText.trim().isEmpty) return false;
    if (item.options.length < 2) return false;
    return item.correctAnswerIndex >= 0 &&
        item.correctAnswerIndex < item.options.length;
  }
}

DeckPackMeta? resolveFeedDeckMeta({
  required List<DeckPackMeta> packs,
  required String? activeDeckId,
}) {
  DeckPackMeta? findById(String? id) {
    if (id == null) return null;
    return packs.cast<DeckPackMeta?>().firstWhere(
      (pack) => pack?.id == id,
      orElse: () => null,
    );
  }

  final activeDeck = findById(activeDeckId);
  if (_isFeedCapable(activeDeck)) return activeDeck;

  final candidates = packs
      .where((pack) => _isFeedCapable(pack))
      .toList(growable: false);
  if (candidates.isEmpty) return null;

  final securityDecks =
      candidates
          .where(
            (pack) =>
                pack.id.toLowerCase().contains('sec701') ||
                pack.assetPath.toLowerCase().contains('sec701') ||
                pack.examCode == 'SY0-701',
          )
          .toList()
        ..sort((a, b) => b.questionCount.compareTo(a.questionCount));
  if (securityDecks.isNotEmpty) return securityDecks.first;
  return candidates.first;
}

bool _isFeedCapable(DeckPackMeta? pack) =>
    pack != null && pack.isImportable && pack.hasQuestions;
