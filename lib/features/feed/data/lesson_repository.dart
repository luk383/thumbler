import '../domain/lesson.dart';
import 'mock_lessons.dart';
import '../../study/domain/study_item.dart';
import 'feed_selection_service.dart';

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
    required this.activeDeckId,
    required this.items,
    required this.weakestDomains,
  });

  final String? activeDeckId;
  final List<StudyItem> items;
  final List<String> weakestDomains;

  @override
  Future<List<Lesson>> fetchLessons() async {
    final eligibleItems = items
        .where(_belongsToActiveDeck)
        .where(_isFeedReady)
        .toList(growable: false);
    if (eligibleItems.isEmpty) return const [];

    return const SmartFeedSelectionService().selectLessons(
      items: eligibleItems,
      weakestDomains: weakestDomains,
    );
  }

  bool _belongsToActiveDeck(StudyItem item) {
    if (activeDeckId == null) return item.deckId == null;
    return item.deckId == activeDeckId;
  }

  bool _isFeedReady(StudyItem item) {
    if (item.promptText.trim().isEmpty) return false;
    if (item.options.length < 2) return false;
    return item.correctAnswerIndex >= 0 &&
        item.correctAnswerIndex < item.options.length;
  }
}
