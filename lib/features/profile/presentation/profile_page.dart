import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/reset_service.dart';
import '../../../core/ui/app_surfaces.dart';
import '../../bookmarks/presentation/bookmarks_notifier.dart';
import '../../growth/streak/streak_notifier.dart';
import '../../growth/daily_quest/daily_quest_notifier.dart';
import '../../growth/xp/xp_notifier.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(xpProvider);
    final streak = ref.watch(streakProvider);
    final bookmarkCount = ref.watch(bookmarksProvider).length;
    final quest = ref.watch(dailyQuestProvider);

    final dailyProgress = (xp.dailyXp / dailyGoal).clamp(0.0, 1.0);
    final goalReached = dailyProgress >= 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppPageIntro(
              title: 'Profile',
              subtitle:
                  'Track momentum, manage local data, and keep your study setup clean.',
            ),
            const SizedBox(height: 20),
            // ── Daily goal card ──────────────────────────────────────────
            _DailyGoalCard(
              dailyXp: xp.dailyXp,
              progress: dailyProgress,
              goalReached: goalReached,
            ),
            const SizedBox(height: 16),

            // ── Stats row ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    emoji: '⚡',
                    value: '${xp.totalXp}',
                    label: 'Total XP',
                    color: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    emoji: '🔥',
                    value: '${streak.currentStreak}',
                    label: 'Day Streak',
                    color: Colors.deepOrangeAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    emoji: '🔖',
                    value: '$bookmarkCount',
                    label: 'Saved',
                    color: Colors.tealAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Daily quest section ──────────────────────────────────────
            const _SectionTitle('Daily Quest'),
            const SizedBox(height: 12),
            _DailyQuestCard(quest: quest),
            const SizedBox(height: 8),
            _QuestStatsRow(quest: quest),
            const SizedBox(height: 24),

            // ── XP legend ────────────────────────────────────────────────
            const _SectionTitle('How XP works'),
            const SizedBox(height: 12),
            const _XpLegendCard(),
            const SizedBox(height: 24),

            const _SectionTitle('Analytics'),
            const SizedBox(height: 12),
            _AnalyticsEntryCard(
              onOpen: () => context.push('/profile/analytics'),
            ),
            const SizedBox(height: 24),

            const _SectionTitle('Data Management'),
            const SizedBox(height: 12),
            _DataManagementCard(
              onResetStudyDeck: () => _runResetAction(
                context,
                dialogMessage:
                    'This will delete all study cards saved on this device. '
                    'Imported exam questions in the local deck will also be removed.',
                successAction: () => const ResetService().resetStudyDeck(
                  context: context,
                  ref: ref,
                ),
              ),
              onResetProgress: () => _runResetAction(
                context,
                dialogMessage:
                    'This will reset XP, streak, daily quest state, and study statistics, '
                    'but keep your local deck content.',
                successAction: () => const ResetService().resetProgress(
                  context: context,
                  ref: ref,
                ),
              ),
              onResetExamHistory: () => _runResetAction(
                context,
                dialogMessage:
                    'This will delete saved exam attempts and any paused exam.',
                successAction: () => const ResetService().resetExamHistory(
                  context: context,
                  ref: ref,
                ),
              ),
              onResetAllAppData: () => _runResetAction(
                context,
                dialogTitle: 'Reset all local data',
                dialogMessage:
                    'This permanently deletes every local deck, exam result, bookmark, '
                    'XP record, streak, and quest state on this device. '
                    'This action cannot be undone.',
                confirmLabel: 'Delete all local data',
                successAction: () => const ResetService().resetAllData(
                  context: context,
                  ref: ref,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Dev tools ────────────────────────────────────────────────
            _DevResetButton(
              onReset: () {
                ref.read(dailyQuestProvider.notifier).devResetQuest();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quest reset for testing'),
                    backgroundColor: Colors.deepOrange,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _runResetAction(
  BuildContext context, {
  String dialogTitle = 'Are you sure?',
  required String dialogMessage,
  String confirmLabel = 'Confirm',
  required Future<void> Function() successAction,
}) async {
  final confirmed = await _showResetConfirmationDialog(
    context,
    title: dialogTitle,
    message: dialogMessage,
    confirmLabel: confirmLabel,
  );
  if (confirmed != true || !context.mounted) return;

  await successAction();
}

Future<bool?> _showResetConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.dailyXp,
    required this.progress,
    required this.goalReached,
  });

  final int dailyXp;
  final double progress;
  final bool goalReached;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3B37C8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Goal',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '$dailyXp / $dailyGoal XP',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goalReached
                ? '🎉 Goal reached! Keep going!'
                : '${((1 - progress) * dailyGoal).ceil()} XP left to daily goal',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard({required this.quest});

  final DailyQuestState quest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quest.questCompleted
              ? Colors.green.withAlpha(100)
              : const Color(0xFF6C63FF).withAlpha(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                quest.questCompleted ? '✅' : '🎯',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quest.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (quest.xpBoostActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withAlpha(100)),
                  ),
                  child: const Text(
                    '⚡ +20% XP',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: quest.progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(
                quest.questCompleted ? Colors.green : const Color(0xFF6C63FF),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            quest.questCompleted
                ? 'Completed! 🎉'
                : '${quest.questProgress} / ${quest.questTarget}',
            style: TextStyle(
              color: quest.questCompleted ? Colors.green : Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestStatsRow extends StatelessWidget {
  const _QuestStatsRow({required this.quest});

  final DailyQuestState quest;

  @override
  Widget build(BuildContext context) {
    final lastDate = quest.lastCompletedDate;

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            emoji: '🏆',
            value: '${quest.totalCompleted}',
            label: 'Quests Done',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            emoji: '📅',
            value: lastDate != null ? lastDate.substring(5) : '—',
            label: 'Last Completed',
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DevResetButton extends StatelessWidget {
  const _DevResetButton({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white38,
        side: const BorderSide(color: Colors.white12),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onReset,
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text('Reset Quest (dev)', style: TextStyle(fontSize: 13)),
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  const _DataManagementCard({
    required this.onResetStudyDeck,
    required this.onResetProgress,
    required this.onResetExamHistory,
    required this.onResetAllAppData,
  });

  final Future<void> Function() onResetStudyDeck;
  final Future<void> Function() onResetProgress;
  final Future<void> Function() onResetExamHistory;
  final Future<void> Function() onResetAllAppData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withAlpha(64)),
      ),
      child: Column(
        children: [
          _DangerActionButton(
            icon: Icons.school_outlined,
            label: 'Reset Study Deck',
            onPressed: onResetStudyDeck,
          ),
          const SizedBox(height: 10),
          _DangerActionButton(
            icon: Icons.insights_outlined,
            label: 'Reset Progress',
            onPressed: onResetProgress,
          ),
          const SizedBox(height: 10),
          _DangerActionButton(
            icon: Icons.history_toggle_off,
            label: 'Reset Exam History',
            onPressed: onResetExamHistory,
          ),
          const SizedBox(height: 10),
          _DangerActionButton(
            icon: Icons.delete_forever_outlined,
            label: 'Reset All App Data',
            onPressed: onResetAllAppData,
            isPrimaryDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _DangerActionButton extends StatelessWidget {
  const _DangerActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimaryDestructive = false,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onPressed;
  final bool isPrimaryDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground = isPrimaryDestructive
        ? Colors.white
        : Colors.redAccent.shade100;
    final background = isPrimaryDestructive
        ? Colors.redAccent
        : Colors.redAccent.withAlpha(26);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.redAccent.withAlpha(90)),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  final String emoji;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(title);
  }
}

class _XpLegendCard extends StatelessWidget {
  const _XpLegendCard();

  @override
  Widget build(BuildContext context) {
    return const AppGlassCard(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _XpRow(
            icon: Icons.visibility_outlined,
            label: 'View a card',
            xp: '+1 XP',
          ),
          Divider(color: Colors.white12, height: 24),
          _XpRow(
            icon: Icons.lightbulb_outline,
            label: 'Reveal explanation',
            xp: '+1 XP',
          ),
          Divider(color: Colors.white12, height: 24),
          _XpRow(
            icon: Icons.check_circle_outline,
            label: 'Correct answer',
            xp: '+3 XP',
          ),
        ],
      ),
    );
  }
}

class _AnalyticsEntryCard extends StatelessWidget {
  const _AnalyticsEntryCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insights_outlined,
              color: Color(0xFFADA8FF),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'See answered questions, deck-scoped accuracy, domain performance, and recent activity.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onOpen,
            icon: const Icon(Icons.chevron_right, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _XpRow extends StatelessWidget {
  const _XpRow({required this.icon, required this.label, required this.xp});

  final IconData icon;
  final String label;
  final String xp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Text(
          xp,
          style: const TextStyle(
            color: Color(0xFFADA8FF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
