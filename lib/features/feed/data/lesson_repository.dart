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
  if (_isPreferredFeedDeck(activeDeck)) return activeDeck;

  final preferredCandidates = packs
      .where((pack) => _isPreferredFeedDeck(pack))
      .toList(growable: false);
  if (preferredCandidates.isNotEmpty) {
    preferredCandidates.sort(_compareFeedPriority);
    return preferredCandidates.first;
  }

  if (_isFallbackFeedDeck(activeDeck)) return activeDeck;

  final fallbackCandidates = packs
      .where((pack) => _isFallbackFeedDeck(pack))
      .toList(growable: false);
  if (fallbackCandidates.isEmpty) return null;
  fallbackCandidates.sort(_compareFeedPriority);
  return fallbackCandidates.first;
}

bool _isPreferredFeedDeck(DeckPackMeta? pack) =>
    pack != null && (pack.isImportable || pack.isStarter) && pack.supportsFeed;

bool _isFallbackFeedDeck(DeckPackMeta? pack) =>
    pack != null && (pack.isImportable || pack.isStarter) && pack.hasQuestions;

int _compareFeedPriority(DeckPackMeta a, DeckPackMeta b) {
  final sectionScoreA = (a.supportsFeed ? 1 : 0) + (a.supportsExam ? 1 : 0);
  final sectionScoreB = (b.supportsFeed ? 1 : 0) + (b.supportsExam ? 1 : 0);
  final bySection = sectionScoreB.compareTo(sectionScoreA);
  if (bySection != 0) return bySection;

  final byQuestions = b.questionCount.compareTo(a.questionCount);
  if (byQuestions != 0) return byQuestions;

  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}
