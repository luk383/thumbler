import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_surfaces.dart';
import '../../../analytics/presentation/providers/progress_analytics_provider.dart';
import '../../../growth/daily_quest/daily_quest_notifier.dart';
import '../../../growth/streak/streak_notifier.dart';
import '../../../study/presentation/controllers/study_controller.dart';
import '../../domain/lesson.dart';

class FeedMotivationCue {
  const FeedMotivationCue({
    required this.message,
    required this.icon,
    required this.tint,
  });

  final String message;
  final IconData icon;
  final Color tint;
}

FeedMotivationCue? buildFeedMotivationCue({
  required StreakState streak,
  required DailyQuestState quest,
  required int weakCount,
  required List<String> weakestDomains,
  required int currentIndex,
  required int total,
  Lesson? currentLesson,
}) {
  final streakRemaining = streak.remainingToday;
  if (!streak.completedToday && streakRemaining == 1) {
    return const FeedMotivationCue(
      message: '1 more to keep your streak',
      icon: Icons.local_fire_department_rounded,
      tint: Color(0xFFFF8A4C),
    );
  }

  final questRemaining = quest.questTarget - quest.questProgress;
  if (!quest.questCompleted &&
      quest.questType == QuestType.answerQuizzes &&
      questRemaining >= 1 &&
      questRemaining <= 2) {
    return FeedMotivationCue(
      message: '$questRemaining more to finish today\'s goal',
      icon: Icons.flag_rounded,
      tint: const Color(0xFF6C63FF),
    );
  }

  final isWeakCard =
      currentLesson != null && weakestDomains.contains(currentLesson.category);
  if (isWeakCard && weakCount >= 1 && weakCount <= 2) {
    return FeedMotivationCue(
      message: '$weakCount more to clear weak questions',
      icon: Icons.trending_up_rounded,
      tint: const Color(0xFF12B981),
    );
  }

  final remainingInRun = total - currentIndex - 1;
  if (remainingInRun >= 1 && remainingInRun <= 2) {
    return FeedMotivationCue(
      message: '$remainingInRun more to finish this quick run',
      icon: Icons.playlist_play_rounded,
      tint: const Color(0xFF22C55E),
    );
  }

  return null;
}

class FeedMotivationBanner extends ConsumerWidget {
  const FeedMotivationBanner({
    super.key,
    required this.currentIndex,
    required this.total,
    this.currentLesson,
  });

  final int currentIndex;
  final int total;
  final Lesson? currentLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final quest = ref.watch(dailyQuestProvider);
    final weakCount = ref.watch(
      studyProvider.select((state) => state.weakCount),
    );
    final weakestDomains = ref.watch(
      progressAnalyticsProvider.select(
        (analytics) =>
            analytics.weakestDomains.map((summary) => summary.domain).toList(),
      ),
    );

    final cue = buildFeedMotivationCue(
      streak: streak,
      quest: quest,
      weakCount: weakCount,
      weakestDomains: weakestDomains,
      currentIndex: currentIndex,
      total: total,
      currentLesson: currentLesson,
    );
    if (cue == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cue.tint.withAlpha(56), const Color(0xE611131A)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cue.icon, color: cue.tint, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                cue.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating overlay shown over the feed at top-right.
/// Displays card progress and daily quest pill.
class FeedOverlay extends ConsumerWidget {
  const FeedOverlay({
    super.key,
    required this.currentIndex,
    required this.total,
  });

  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quest = ref.watch(dailyQuestProvider);
    final streak = ref.watch(streakProvider);
    final goalReached = quest.questCompleted;
    final progress = total == 0 ? 0.0 : (currentIndex + 1) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pill(
          color: const Color(0xCC11131A),
          child: SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentIndex + 1} / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        AppStatusBadge(
          label: total == 0
              ? 'Empty deck'
              : '${(progress * 100).round()}% through',
          icon: Icons.flash_on_rounded,
          tint: const Color(0xFFADA8FF),
        ),
        const SizedBox(height: 6),
        _Pill(
          color: const Color(0xCC2A180F),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 4),
              Text(
                streak.completedToday
                    ? '${streak.currentStreak} day streak'
                    : '${streak.currentStreak} streak • ${streak.answeredToday}/3 today',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Quest progress pill: "🎯 0/3" or "🎉 Done!"
        _Pill(
          color: goalReached
              ? const Color(0xCC198754)
              : const Color(0xCC6C63FF),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                goalReached ? '🎉' : '🎯',
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 4),
              Text(
                goalReached
                    ? 'Done!'
                    : 'Quest ${quest.questProgress}/${quest.questTarget}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: child,
    );
  }
}
