import 'package:flutter_test/flutter_test.dart';
import 'package:thumbler/features/feed/data/feed_selection_service.dart';
import 'package:thumbler/features/feed/data/lesson_repository.dart';
import 'package:thumbler/features/study/domain/study_item.dart';

void main() {
  const service = SmartFeedSelectionService();

  StudyItem makeItem({
    required String id,
    required String category,
    String deckId = 'deck',
    String? promptText,
    int timesSeen = 0,
    int correctCount = 0,
    int wrongCount = 0,
    int againCount = 0,
    int? difficulty,
    DateTime? lastReviewedAt,
  }) {
    return StudyItem(
      id: id,
      deckId: deckId,
      contentType: ContentType.examQuestion,
      category: category,
      promptText: promptText ?? 'Question $id',
      explanationText: 'Explanation $id',
      options: const ['A', 'B', 'C', 'D'],
      correctAnswerIndex: 0,
      timesSeen: timesSeen,
      correctCount: correctCount,
      wrongCount: wrongCount,
      againCount: againCount,
      difficulty: difficulty,
      lastReviewedAt: lastReviewedAt,
    );
  }

  test('prioritizes unseen before wrong before weakest before fallback', () {
    final now = DateTime(2026, 3, 6, 12);
    final lessons = service.selectLessons(
      now: now,
      weakestDomains: const ['Weak Domain'],
      items: [
        makeItem(
          id: 'fallback',
          category: 'Strong Domain',
          timesSeen: 3,
          correctCount: 3,
        ),
        makeItem(
          id: 'weak',
          category: 'Weak Domain',
          timesSeen: 2,
          correctCount: 2,
        ),
        makeItem(
          id: 'wrong',
          category: 'Strong Domain',
          timesSeen: 3,
          correctCount: 1,
          wrongCount: 2,
        ),
        makeItem(
          id: 'unseen',
          category: 'Strong Domain',
          timesSeen: 0,
        ),
      ],
    );

    expect(lessons.map((lesson) => lesson.id).toList(), [
      'unseen',
      'wrong',
      'weak',
      'fallback',
    ]);
  });

  test('deprioritizes recently reviewed items when enough alternatives exist', () {
    final now = DateTime(2026, 3, 6, 12);
    final lessons = service.selectLessons(
      now: now,
      weakestDomains: const [],
      items: [
        makeItem(
          id: 'recent',
          category: 'Domain A',
          timesSeen: 4,
          correctCount: 4,
          lastReviewedAt: now.subtract(const Duration(hours: 1)),
        ),
        makeItem(
          id: 'older',
          category: 'Domain B',
          timesSeen: 4,
          correctCount: 4,
          lastReviewedAt: now.subtract(const Duration(days: 5)),
        ),
      ],
    );

    expect(lessons.first.id, 'older');
  });

  test('deduplicates repeated prompts to reduce short-term repetition', () {
    final lessons = service.selectLessons(
      weakestDomains: const [],
      items: [
        makeItem(id: 'one', category: 'Domain A', promptText: 'Question one'),
        makeItem(id: 'two', category: 'Domain B', promptText: 'Question one'),
        makeItem(
          id: 'three',
          category: 'Domain C',
        ),
      ],
    );

    expect(lessons.map((lesson) => lesson.id).toSet(), {'one', 'three'});
    expect(lessons, hasLength(2));
  });

  test('repository filters to active deck and ignores invalid feed items', () async {
    final repository = LocalDeckLessonRepository(
      activeDeckId: 'deck-a',
      weakestDomains: const [],
      items: [
        makeItem(id: 'valid', category: 'Domain A', deckId: 'deck-a'),
        makeItem(id: 'other-deck', category: 'Domain B', deckId: 'deck-b'),
        StudyItem(
          id: 'invalid-options',
          deckId: 'deck-a',
          contentType: ContentType.examQuestion,
          category: 'Domain C',
          promptText: 'Broken item',
          explanationText: 'Broken',
          options: const ['Only one'],
          correctAnswerIndex: 0,
        ),
      ],
    );

    final lessons = await repository.fetchLessons();

    expect(lessons.map((lesson) => lesson.id).toList(), ['valid']);
  });
}
