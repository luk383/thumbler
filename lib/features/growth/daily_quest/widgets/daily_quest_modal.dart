import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../daily_quest_notifier.dart';

class DailyQuestModal extends ConsumerWidget {
  const DailyQuestModal({super.key});

  /// Show the once-per-day quest announcement dialog.
  static Future<void> show(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: const DailyQuestModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quest = ref.watch(dailyQuestProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF12101F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF6C63FF).withAlpha(80)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              l10n.todaysQuest,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.questDescription(
                quest.questType == QuestType.earnXp,
                quest.questTarget,
              ),
              style: const TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: quest.progress,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${quest.questProgress} / ${quest.questTarget}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // CTA button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.letsGo),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.notNow, style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }
}
