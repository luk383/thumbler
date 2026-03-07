import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thumbler/app/l10n/app_localizations.dart';
import 'package:thumbler/features/feed/domain/lesson.dart';
import 'package:thumbler/features/feed/presentation/widgets/feed_overlay.dart';
import 'package:thumbler/features/growth/daily_quest/daily_quest_state.dart';
import 'package:thumbler/features/growth/streak/streak_state.dart';

void main() {
  const l10n = AppLocalizations(Locale('en'));
  const sampleLesson = Lesson(
    id: 'q1',
    hook: 'Question',
    explanation: 'Explanation',
    quizQuestion: 'Question',
    options: ['A', 'B', 'C', 'D'],
    correctAnswerIndex: 0,
    category: 'Weak Domain',
  );

  test('prioritizes streak cue when one answer remains today', () {
    final cue = buildFeedMotivationCue(
      l10n: l10n,
      streak: const StreakState(currentStreak: 4, answeredToday: 2),
      quest: const DailyQuestState(
        questType: QuestType.answerQuizzes,
        questTarget: 5,
        questProgress: 4,
        questCompleted: false,
        totalCompleted: 0,
        lastCompletedDate: null,
        xpBoostActive: false,
        modalShownToday: false,
      ),
      weakCount: 1,
      weakestDomains: const ['Weak Domain'],
      currentIndex: 8,
      total: 10,
      currentLesson: sampleLesson,
    );

    expect(cue?.message, '1 more to keep your streak');
  });

  test('shows daily goal cue when quiz quest is nearly done', () {
    final cue = buildFeedMotivationCue(
      l10n: l10n,
      streak: const StreakState(currentStreak: 1, answeredToday: 0),
      quest: const DailyQuestState(
        questType: QuestType.answerQuizzes,
        questTarget: 5,
        questProgress: 3,
        questCompleted: false,
        totalCompleted: 0,
        lastCompletedDate: null,
        xpBoostActive: false,
        modalShownToday: false,
      ),
      weakCount: 5,
      weakestDomains: const ['Weak Domain'],
      currentIndex: 4,
      total: 10,
      currentLesson: sampleLesson,
    );

    expect(cue?.message, '2 more to finish today\'s goal');
  });

  test('shows weak review cue when only a few weak cards remain', () {
    final cue = buildFeedMotivationCue(
      l10n: l10n,
      streak: const StreakState(currentStreak: 1, answeredToday: 0),
      quest: const DailyQuestState(
        questType: QuestType.earnXp,
        questTarget: 10,
        questProgress: 1,
        questCompleted: false,
        totalCompleted: 0,
        lastCompletedDate: null,
        xpBoostActive: false,
        modalShownToday: false,
      ),
      weakCount: 1,
      weakestDomains: const ['Weak Domain'],
      currentIndex: 4,
      total: 10,
      currentLesson: sampleLesson,
    );

    expect(cue?.message, '1 more to clear weak questions');
  });

  test('falls back to quick run cue near the end of the loaded feed', () {
    final cue = buildFeedMotivationCue(
      l10n: l10n,
      streak: const StreakState(currentStreak: 1, answeredToday: 0),
      quest: const DailyQuestState(
        questType: QuestType.earnXp,
        questTarget: 10,
        questProgress: 1,
        questCompleted: false,
        totalCompleted: 0,
        lastCompletedDate: null,
        xpBoostActive: false,
        modalShownToday: false,
      ),
      weakCount: 4,
      weakestDomains: const ['Other Domain'],
      currentIndex: 8,
      total: 10,
      currentLesson: sampleLesson,
    );

    expect(cue?.message, '1 more to finish this quick run');
  });

  test('returns null when no retention cue is available', () {
    final cue = buildFeedMotivationCue(
      l10n: l10n,
      streak: const StreakState(currentStreak: 1, answeredToday: 0),
      quest: const DailyQuestState(
        questType: QuestType.earnXp,
        questTarget: 10,
        questProgress: 1,
        questCompleted: false,
        totalCompleted: 0,
        lastCompletedDate: null,
        xpBoostActive: false,
        modalShownToday: false,
      ),
      weakCount: 4,
      weakestDomains: const ['Other Domain'],
      currentIndex: 2,
      total: 10,
      currentLesson: sampleLesson,
    );

    expect(cue, isNull);
  });
}
