import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../growth/daily_quest/daily_quest_notifier.dart';

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
    final goalReached = quest.questCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card counter: "3 / 10"
        _Pill(
          color: Colors.black.withAlpha(140),
          child: Text(
            '${currentIndex + 1} / $total',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Quest progress pill: "🎯 0/3" or "🎉 Done!"
        _Pill(
          color: goalReached
              ? Colors.green.withAlpha(200)
              : const Color(0xFF6C63FF).withAlpha(210),
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
                    : '${quest.questProgress} / ${quest.questTarget}',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
