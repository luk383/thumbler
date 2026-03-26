import 'package:flutter_test/flutter_test.dart';
import 'package:wolf_lab/features/feed/data/feed_selection_service.dart';
import 'package:wolf_lab/features/feed/data/feed_session_memory.dart';
import 'package:wolf_lab/features/feed/data/lesson_repository.dart';
import 'package:wolf_lab/features/study/data/deck_pack.dart';
import 'package:wolf_lab/features/study/domain/study_item.dart';

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
        makeItem(id: 'unseen', category: 'Strong Domain', timesSeen: 0),
      ],
    );

    expect(lessons.map((lesson) => lesson.id).toList(), [
      'unseen',
      'wrong',
      'weak',
      'fallback',
    ]);
  });

  test(
    'deprioritizes recently reviewed items when enough alternatives exist',
    () {
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
    },
  );

  test('deduplicates repeated prompts to reduce short-term repetition', () {
    final lessons = service.selectLessons(
      weakestDomains: const [],
      items: [
        makeItem(id: 'one', category: 'Domain A', promptText: 'Question one'),
        makeItem(id: 'two', category: 'Domain B', promptText: 'Question one'),
        makeItem(id: 'three', category: 'Domain C'),
      ],
    );

    expect(lessons.map((lesson) => lesson.id).toSet(), {'one', 'three'});
    expect(lessons, hasLength(2));
  });

  test('uses recent lesson memory to avoid repeating the same top card', () {
    final lessons = service.selectLessons(
      weakestDomains: const [],
      recentLessonIds: const ['recent-top'],
      items: [
        makeItem(
          id: 'recent-top',
          category: 'Domain A',
          timesSeen: 4,
          correctCount: 4,
          difficulty: 3,
        ),
        makeItem(
          id: 'fresh-fallback',
          category: 'Domain B',
          timesSeen: 4,
          correctCount: 4,
          difficulty: 1,
        ),
      ],
    );

    expect(lessons.first.id, 'fresh-fallback');
  });

  test(
    'repository filters to active deck and ignores invalid feed items',
    () async {
      final repository = LocalDeckLessonRepository(
        deckId: 'deck-a',
        weakestDomains: const [],
        sessionMemory: FeedSessionMemory(),
        sourceItems: [
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
        progressItems: const [],
      );

      final lessons = await repository.fetchLessons();

      expect(lessons.map((lesson) => lesson.id).toList(), ['valid']);
    },
  );

  test(
    'repository uses deck source items even when progress has been reset',
    () async {
      final repository = LocalDeckLessonRepository(
        deckId: 'deck-a',
        weakestDomains: const [],
        sessionMemory: FeedSessionMemory(),
        sourceItems: [
          makeItem(id: 'deck-question', category: 'Domain A', deckId: 'deck-a'),
        ],
        progressItems: const [],
      );

      final lessons = await repository.fetchLessons();

      expect(lessons.map((lesson) => lesson.id).toList(), ['deck-question']);
    },
  );

  test(
    'repository overlays progress stats onto the local deck source',
    () async {
      final repository = LocalDeckLessonRepository(
        deckId: 'deck-a',
        weakestDomains: const [],
        sessionMemory: FeedSessionMemory(),
        sourceItems: [
          makeItem(id: 'question', category: 'Domain A', deckId: 'deck-a'),
        ],
        progressItems: [
          makeItem(
            id: 'question',
            category: 'Domain A',
            deckId: 'deck-a',
            timesSeen: 4,
            wrongCount: 2,
          ),
        ],
      );

      final lessons = await repository.fetchLessons();

      expect(lessons.single.id, 'question');
    },
  );

  test('feed deck resolution falls back to the first valid local deck', () {
    final resolved = resolveFeedDeckMeta(
      packs: const [
        DeckPackMeta(
          id: 'placeholder',
          title: 'Placeholder',
          assetPath: 'assets/decks/placeholder.json',
          questionCount: 0,
          microCardCount: 0,
          examQuestionCount: 0,
          isStarter: true,
          availabilityNote: 'Soon',
        ),
        DeckPackMeta(
          id: 'aws_certified_security_specialty_scs_c02',
          title: 'AWS Certified Security - Specialty',
          assetPath:
              'assets/decks/aws_certified_security_specialty_scs_c02.json',
          questionCount: 100,
          microCardCount: 60,
          examQuestionCount: 40,
          examCode: 'SCS-C02',
        ),
      ],
      activeDeckId: 'missing-deck',
    );

    expect(resolved?.id, 'aws_certified_security_specialty_scs_c02');
  });

  test(
    'feed deck resolution prefers decks with feed and exam support over exam-only decks',
    () {
      final resolved = resolveFeedDeckMeta(
        packs: const [
          DeckPackMeta(
            id: 'exam-only',
            title: 'Certification Exam',
            assetPath: 'assets/decks/exam_only.json',
            questionCount: 90,
            microCardCount: 0,
            examQuestionCount: 90,
            examCode: 'SAA-C03',
          ),
          DeckPackMeta(
            id: 'aws_certified_solutions_architect_associate_saa_c03',
            title: 'AWS Certified Solutions Architect - Associate',
            assetPath:
                'assets/decks/aws_certified_solutions_architect_associate_saa_c03.json',
            questionCount: 100,
            microCardCount: 60,
            examQuestionCount: 40,
            examCode: 'SAA-C03',
            category: 'AWS Architecture',
          ),
        ],
        activeDeckId: 'exam-only',
      );

      expect(
        resolved?.id,
        'aws_certified_solutions_architect_associate_saa_c03',
      );
    },
  );
}
