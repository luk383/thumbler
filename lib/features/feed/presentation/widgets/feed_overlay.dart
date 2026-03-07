import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_surfaces.dart';
import '../../../growth/daily_quest/daily_quest_notifier.dart';
import '../../../growth/streak/streak_notifier.dart';

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
