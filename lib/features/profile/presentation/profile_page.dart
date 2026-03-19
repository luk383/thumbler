import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../features/notifications/state/notification_settings_notifier.dart';
import '../../../app/settings/app_settings.dart';
import '../../../core/data/reset_service.dart';
import '../../../core/ui/app_surfaces.dart';
import '../../bookmarks/presentation/bookmarks_notifier.dart';
import '../../goals/ui/goals_page.dart';
import '../../habits/ui/habits_page.dart';
import '../../habits/state/habits_notifier.dart';
import '../../journal/ui/journal_page.dart';
import '../../reading/ui/reading_page.dart';
import '../../reflection/ui/reflection_page.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/state/achievements_notifier.dart';
import '../../achievements/ui/achievements_page.dart';
import '../../backup/backup_service.dart';
import '../../study/data/study_session_storage.dart';
import '../../study/presentation/controllers/deck_library_controller.dart';
import '../../growth/streak/streak_notifier.dart';
import '../../growth/daily_quest/daily_quest_notifier.dart';
import '../../growth/xp/xp_notifier.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(appSettingsProvider);
    final xp = ref.watch(xpProvider);
    final streak = ref.watch(streakProvider);
    final bookmarkCount = ref.watch(bookmarksProvider).length;
    final quest = ref.watch(dailyQuestProvider);
    final activeDeck = ref.watch(activeDeckMetaProvider);
    final unlockedCount = ref.watch(achievementsProvider).length;
    final totalAchievements = allAchievements.length;

    final dailyProgress = (xp.dailyXp / dailyGoal).clamp(0.0, 1.0);
    final goalReached = dailyProgress >= 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C11),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            collapsedHeight: 80,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0A0C11).withAlpha(200),
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white70),
                tooltip: 'Condividi progresso',
                onPressed: () => context.push('/share'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              title: Text(
                l10n.profileTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF6C63FF).withAlpha(30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileSubtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  _DailyGoalCard(
                    dailyXp: xp.dailyXp,
                    progress: dailyProgress,
                    goalReached: goalReached,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          emoji: '🔥',
                          value: '${streak.currentStreak}',
                          label: 'Day Streak',
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          emoji: '🔖',
                          value: '$bookmarkCount',
                          label: 'Bookmarks',
                          color: const Color(0xFFADA8FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _YearlyHeatmapSection(),
                  const SizedBox(height: 28),
                  _SectionTitle(l10n.todaysQuest),
                  const SizedBox(height: 12),
                  _DailyQuestCard(quest: quest, l10n: l10n),
                  const SizedBox(height: 12),
                  _QuestStatsRow(quest: quest, l10n: l10n),
                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    _DevResetButton(
                      onReset: () {
                        ref.read(dailyQuestProvider.notifier).devResetQuest();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.questResetSuccess)),
                        );
                      },
                      l10n: l10n,
                    ),
                  ],
                  const SizedBox(height: 32),
                  _SectionTitle(l10n.overview),
                  const SizedBox(height: 12),
                  _AnalyticsEntryCard(
                    onOpen: () => context.push('/profile/analytics'),
                    deckTitle: activeDeck?.title,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 32),
                  _SectionTitle('🏆 Badge'),
                  const SizedBox(height: 12),
                  _AchievementsEntryCard(
                    unlocked: unlockedCount,
                    total: totalAchievements,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AchievementsPage()),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _SectionTitle('🌱 Crescita Personale'),
                  const SizedBox(height: 12),
                  _GrowthHubCard(),
                  const SizedBox(height: 20),
                  _SectionTitle(l10n.xpLegendTitle),
                  const SizedBox(height: 12),
                  _XpLegendCard(l10n: l10n),
                  const SizedBox(height: 32),
                  _NotificationsCard(),
                  const SizedBox(height: 32),
                  _SettingsCard(
                    settings: settings,
                    onLanguageChanged: (lang) => ref
                        .read(appSettingsProvider.notifier)
                        .setLanguage(lang),
                    onThemeModeChanged: (mode) => ref
                        .read(appSettingsProvider.notifier)
                        .setThemeMode(mode),
                  ),
                  const SizedBox(height: 32),
                  _SectionTitle('Data Management'),
                  const SizedBox(height: 12),
                  _DataManagementCard(
                    onResetStudyDeck: () => _handleReset(
                      context,
                      ref,
                      title: 'Reset Study Deck',
                      message:
                          'This will remove all cards from your study pool. Your bookmarks and exam history remain safe.',
                      confirmLabel: 'Reset Deck',
                      resetAction: () => ref
                          .read(resetServiceProvider)
                          .resetStudyDeck(context: context, ref: ref),
                      l10n: l10n,
                    ),
                    onResetProgress: () => _handleReset(
                      context,
                      ref,
                      title: 'Reset Progress',
                      message:
                          'This will reset your XP, streaks, and current daily quest. This cannot be undone.',
                      confirmLabel: 'Reset Progress',
                      resetAction: () => ref
                          .read(resetServiceProvider)
                          .resetProgress(context: context, ref: ref),
                      l10n: l10n,
                    ),
                    onResetExamHistory: () => _handleReset(
                      context,
                      ref,
                      title: 'Reset Exam History',
                      message:
                          'This will permanently delete all your previous exam results.',
                      confirmLabel: 'Reset History',
                      resetAction: () => ref
                          .read(resetServiceProvider)
                          .resetExamHistory(context: context, ref: ref),
                      l10n: l10n,
                    ),
                    onResetAllAppData: () => _handleReset(
                      context,
                      ref,
                      title: 'Reset All App Data',
                      message:
                          'WARNING: This will wipe everything—bookmarks, study cards, progress, and history. The app will return to its initial state.',
                      confirmLabel: 'Wipe Everything',
                      resetAction: () => ref
                          .read(resetServiceProvider)
                          .resetAllData(context: context, ref: ref),
                      l10n: l10n,
                    ),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 20),
                  const _BackupCard(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReset(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required String confirmLabel,
    required AsyncCallback resetAction,
    required AppLocalizations l10n,
  }) async {
    final confirmed = await _showResetConfirmationDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: l10n.cancelLabel,
    );

    if (confirmed != true || !context.mounted) return;

    await resetAction();
  }
}

Future<bool?> _showResetConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
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
            child: Text(cancelLabel),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.settings,
    required this.onLanguageChanged,
    required this.onThemeModeChanged,
  });

  final AppSettingsState settings;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsSection,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.languageLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<AppLanguage>(
            segments: [
              ButtonSegment<AppLanguage>(
                value: AppLanguage.italian,
                label: Text(l10n.italianLabel),
              ),
              ButtonSegment<AppLanguage>(
                value: AppLanguage.english,
                label: Text(l10n.englishLabel),
              ),
            ],
            selected: {settings.language},
            onSelectionChanged: (selection) {
              onLanguageChanged(selection.first);
            },
          ),
          const SizedBox(height: 8),
          Text(
            l10n.languageHelp,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.appearanceLabel,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined, size: 16),
                label: Text('Auto'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 16),
                label: Text('Chiaro'),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 16),
                label: Text('Scuro'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                onThemeModeChanged(selection.first),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/privacy'),
            child: Row(
              children: [
                const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.white38,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.privacyPolicyLink,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.dailyXp,
    required this.progress,
    required this.goalReached,
    required this.l10n,
  });

  final int dailyXp;
  final double progress;
  final bool goalReached;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
      tint: const Color(0xFF6C63FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dailyGoal,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
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
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFADA8FF)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goalReached
                ? l10n.goalReachedKeepGoing
                : l10n.xpLeftToDailyGoal(((1 - progress) * dailyGoal).ceil()),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard({required this.quest, required this.l10n});

  final DailyQuestState quest;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      tint: quest.questCompleted ? Colors.green : const Color(0xFF6C63FF),
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
                  l10n.questDescription(
                    quest.questType == QuestType.earnXp,
                    quest.questTarget,
                  ),
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
                  child: Text(
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
                ? l10n.done
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
  const _QuestStatsRow({required this.quest, required this.l10n});

  final DailyQuestState quest;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final lastDate = quest.lastCompletedDate;

    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            emoji: '🏆',
            value: '${quest.totalCompleted}',
            label: l10n.questsDone,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            emoji: '📅',
            value: lastDate != null ? lastDate.substring(5) : '—',
            label: l10n.lastCompleted,
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
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      tint: Colors.white,
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
  const _DevResetButton({required this.onReset, required this.l10n});

  final VoidCallback onReset;
  final AppLocalizations l10n;

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
      label: Text(l10n.resetQuestDev, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  const _DataManagementCard({
    required this.onResetStudyDeck,
    required this.onResetProgress,
    required this.onResetExamHistory,
    required this.onResetAllAppData,
    required this.l10n,
  });

  final Future<void> Function() onResetStudyDeck;
  final Future<void> Function() onResetProgress;
  final Future<void> Function() onResetExamHistory;
  final Future<void> Function() onResetAllAppData;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      tint: Colors.redAccent,
      child: Column(
        children: [
          _DangerActionButton(
            icon: Icons.school_outlined,
            label: l10n.resetStudyDeck,
            onPressed: onResetStudyDeck,
          ),
          const SizedBox(height: 10),
          _DangerActionButton(
            icon: Icons.insights_outlined,
            label: l10n.resetProgress,
            onPressed: onResetProgress,
          ),
          const SizedBox(height: 10),
          _DangerActionButton(
            icon: Icons.history_toggle_off,
            label: l10n.resetExamHistory,
            onPressed: onResetExamHistory,
          ),
          const SizedBox(height: 10),
          _DangerActionButton(
            icon: Icons.delete_forever_outlined,
            label: l10n.resetAllAppData,
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
      tint: color,
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
  const _XpLegendCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _XpRow(
            icon: Icons.visibility_outlined,
            label: l10n.xpLegendViewCard,
            xp: '+1 XP',
          ),
          Divider(color: Colors.white12, height: 24),
          _XpRow(
            icon: Icons.lightbulb_outline,
            label: l10n.xpLegendRevealExplanation,
            xp: '+1 XP',
          ),
          Divider(color: Colors.white12, height: 24),
          _XpRow(
            icon: Icons.check_circle_outline,
            label: l10n.xpLegendCorrectAnswer,
            xp: '+3 XP',
          ),
        ],
      ),
    );
  }
}

class _AnalyticsEntryCard extends StatelessWidget {
  const _AnalyticsEntryCard({
    required this.onOpen,
    this.deckTitle,
    required this.l10n,
  });

  final VoidCallback onOpen;
  final String? deckTitle;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      tint: const Color(0xFF6C63FF),
      child: Row(
        children: [
          const AppSurfaceIcon(
            icon: Icons.insights_outlined,
            tint: Color(0xFFADA8FF),
            size: 42,
            iconSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.progressAnalyticsTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.progressAnalyticsSubtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (deckTitle != null) ...[
                  SizedBox(height: 4),
                  Text(
                    '${l10n.currentScopePrefix}$deckTitle',
                    style: TextStyle(color: Color(0xFFADA8FF), fontSize: 11),
                  ),
                ],
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

// ── Growth hub card ──────────────────────────────────────────────────────────

class _GrowthHubCard extends StatelessWidget {
  const _GrowthHubCard();

  static const _items = [
    _GrowthItem('🎯', 'Obiettivi', GoalsPage()),
    _GrowthItem('🌱', 'Abitudini', HabitsPage()),
    _GrowthItem('📅', 'Riflessione', ReflectionPage()),
    _GrowthItem('✍️', 'Diario', JournalPage()),
    _GrowthItem('📚', 'Letture', ReadingPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: _items.map((item) => ListTile(
          leading: Text(item.emoji, style: const TextStyle(fontSize: 22)),
          title: Text(item.label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => item.page),
          ),
        )).toList(),
      ),
    );
  }
}

class _GrowthItem {
  const _GrowthItem(this.emoji, this.label, this.page);
  final String emoji;
  final String label;
  final Widget page;
}

// ── Notifications card ───────────────────────────────────────────────────────

class _NotificationsCard extends ConsumerWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final anyEnabled =
        settings.studyReminderEnabled || settings.streakProtectionEnabled;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: const Text(
          'Notifiche e promemoria',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(anyEnabled ? 'Attive' : 'Disattivate'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/notifications'),
      ),
    );
  }
}

// ── Achievements entry card ───────────────────────────────────────────────────

class _AchievementsEntryCard extends StatelessWidget {
  const _AchievementsEntryCard({
    required this.unlocked,
    required this.total,
    required this.onOpen,
  });

  final int unlocked;
  final int total;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      tint: Colors.amber,
      child: InkWell(
        onTap: onOpen,
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'I tuoi badge',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '$unlocked / $total sbloccati',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : unlocked / total,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.amberAccent),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

// ── Yearly heatmap ────────────────────────────────────────────────────────────

class _YearlyHeatmapSection extends ConsumerWidget {
  const _YearlyHeatmapSection();

  static const _italianMonths = [
    'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final habits = ref.watch(habitsProvider);
    final now = DateTime.now();
    final year = now.year;

    // Build activity map: dateKey -> count
    final activityMap = <String, int>{};

    // Count study sessions (cardCount per day)
    try {
      final sessions = StudySessionStorage().getAll();
      for (final s in sessions) {
        final key = _dateKey(s.date);
        activityMap[key] = (activityMap[key] ?? 0) + s.cardCount;
      }
    } catch (_) {}

    // Count habit completions per day
    for (final habit in habits) {
      for (final dateStr in habit.completedDates) {
        activityMap[dateStr] = (activityMap[dateStr] ?? 0) + 1;
      }
    }

    // Build 365-day grid starting from 52 weeks ago (Sunday-aligned)
    final today = DateTime(now.year, now.month, now.day);
    // Find start: go back 364 days from today
    final startRaw = today.subtract(const Duration(days: 364));
    // Align to Sunday (weekday 7 = Sunday in Dart)
    final startOffset = startRaw.weekday % 7; // 0=Sun,1=Mon...
    final start = startRaw.subtract(Duration(days: startOffset));

    // Build list of weeks (each week = 7 days)
    final weeks = <List<DateTime?>>[];
    var cursor = start;
    while (cursor.isBefore(today) || cursor.isAtSameMomentAs(today)) {
      final week = <DateTime?>[];
      for (var d = 0; d < 7; d++) {
        final day = cursor.add(Duration(days: d));
        // Only show days up to today, and within current year context
        if (day.isAfter(today)) {
          week.add(null);
        } else {
          week.add(day);
        }
      }
      weeks.add(week);
      cursor = cursor.add(const Duration(days: 7));
    }

    // Build month label positions
    final monthLabels = <int, String>{}; // weekIndex -> month label
    for (var wi = 0; wi < weeks.length; wi++) {
      final week = weeks[wi];
      for (final day in week) {
        if (day != null && day.day == 1) {
          monthLabels[wi] = _italianMonths[day.month - 1];
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attività $year',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels row
              Row(
                children: List.generate(weeks.length, (wi) {
                  return SizedBox(
                    width: 12,
                    child: monthLabels.containsKey(wi)
                        ? Text(
                            monthLabels[wi]!,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 8,
                            ),
                          )
                        : null,
                  );
                }),
              ),
              const SizedBox(height: 3),
              // Heatmap grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: weeks.map((week) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Column(
                      children: week.map((day) {
                        if (day == null) {
                          return const SizedBox(width: 10, height: 12);
                        }
                        final key = _dateKey(day);
                        final count = activityMap[key] ?? 0;
                        final color = _cellColor(cs, count);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _cellColor(ColorScheme cs, int count) {
    if (count == 0) return cs.surfaceContainerHighest.withAlpha(120);
    if (count <= 2) return cs.primary.withAlpha(80);
    if (count <= 5) return cs.primary.withAlpha(150);
    return cs.primary;
  }
}

// ── Backup card ───────────────────────────────────────────────────────────────

class _BackupCard extends StatelessWidget {
  const _BackupCard();

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      tint: Colors.blueAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💾 Backup dati',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Esporta o ripristina goals, abitudini, diario, letture e riflessioni.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  icon: const Icon(Icons.upload_outlined, size: 18),
                  label: const Text('Esporta'),
                  onPressed: () => BackupService.exportAndShare(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Importa'),
                  onPressed: () async {
                    final ok = await BackupService.importFromFile(context);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup ripristinato!'),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
