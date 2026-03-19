import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/ui/app_surfaces.dart';
import '../../../analytics/presentation/providers/progress_analytics_provider.dart';
import '../../../analytics/domain/progress_analytics.dart';
import '../../../../features/paywall/pro_guard.dart';
import '../../../../features/paywall/presentation/paywall_page.dart';
import '../controllers/deck_library_controller.dart';
import '../controllers/study_controller.dart';
import '../widgets/deck_library_sheet.dart';

// ============================================================================
// Study Launcher Page
// Always shows: header, category chips, topic chips, preview, start buttons,
// and the Library card — regardless of whether the deck is empty.
// ============================================================================

class StudyLauncherPage extends ConsumerWidget {
  const StudyLauncherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(studyProvider);
    final n = ref.read(studyProvider.notifier);
    final activeDeck = ref.watch(activeDeckMetaProvider);
    final analytics = ref.watch(progressAnalyticsProvider);
    final showCategoryFilters = s.items.length >= 20 && s.categories.length > 1;
    final showTopicFilters =
        showCategoryFilters &&
        s.selectedCategory != null &&
        s.topics.length > 1 &&
        s.filtered.length >= 12;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
          children: [
            // ── Header ──────────────────────────────────────────────────
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.studyTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => context.push('/study/history'),
                  icon: const Icon(Icons.history_outlined),
                  tooltip: 'Storico sessioni',
                  color: Colors.white54,
                ),
                IconButton(
                  onPressed: () => context.push('/deck-management'),
                  icon: const Icon(Icons.tune_outlined),
                  tooltip: 'Gestisci deck',
                  color: Colors.white54,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              activeDeck == null
                  ? l10n.cardsInDeck(s.items.length)
                  : l10n.activeDeckCards(activeDeck.title, s.items.length),
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _StudySnapshot(state: s),
            const SizedBox(height: 18),

            // ── Empty banner (deck empty) ────────────────────────────────
            if (s.items.isEmpty) ...[
              _EmptyBanner(onSeed: n.seedStarterCards),
              const SizedBox(height: 28),
            ] else ...[
              _PrimaryStudyCard(state: s, notifier: n),
              const SizedBox(height: 16),
              _SessionSettingsCard(
                state: s,
                notifier: n,
                showCategoryFilters: showCategoryFilters,
                showTopicFilters: showTopicFilters,
                canUseTopicSelection: ref
                    .read(proGuardProvider)
                    .canUseTopicSelection(),
                canRunLongSession: ref
                    .read(proGuardProvider)
                    .canRunLongSpeedDrill(),
                onProGate: (label) => openPaywall(context, featureName: label),
              ),
              const SizedBox(height: 20),
              _WeakAreasSummaryCard(
                analytics: analytics,
                onTrainWeakAreas: analytics.weakestDomains.isEmpty
                    ? null
                    : () => n.startWeakAreasSession(
                        categories: analytics.weakestDomains
                            .map((summary) => summary.domain)
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: 24),
            ],

            if (s.items.isEmpty) ...[
              _DisabledStartButton(
                icon: Icons.psychology_outlined,
                label: l10n.studyStartSession,
                reason: l10n.studyImportCardsFirst,
              ),
              const SizedBox(height: 10),
              _DisabledStartButton(
                icon: Icons.bolt,
                label: l10n.studyStartSpeed,
                reason: l10n.studyImportCardsFirst,
              ),
            ] else if (s.availableCount == 0) ...[
              _EmptyFilterResult(),
            ],

            const SizedBox(height: 32),

            // ── Library card ─────────────────────────────────────────────
            _LibraryCard(
              onOpen: () => showDeckLibrary(context),
              deckTitle: activeDeck?.title,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Section wrapper
// ============================================================================

class _LauncherSection extends StatelessWidget {
  const _LauncherSection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}

// ============================================================================
// Empty banner
// ============================================================================

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.onSeed});
  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        children: [
          const Text('📚', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          Text(
            l10n.studyEmptyTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.studyEmptyMessage,
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withAlpha(40)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onSeed,
              icon: const Icon(Icons.auto_awesome, size: 15),
              label: Text(l10n.studySeedStarter),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakAreasSummaryCard extends StatelessWidget {
  const _WeakAreasSummaryCard({
    required this.analytics,
    required this.onTrainWeakAreas,
  });

  final ProgressAnalytics analytics;
  final VoidCallback? onTrainWeakAreas;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_down_rounded,
                  color: Colors.orangeAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weakAreasTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      l10n.weakAreasSubtitle,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (analytics.weakestDomains.isEmpty)
            Text(
              l10n.weakAreasHint,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.4,
              ),
            )
          else ...[
            ...analytics.weakestDomains.map(
              (summary) => _WeakAreaRow(summary: summary),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D8B5F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: onTrainWeakAreas,
                icon: const Icon(Icons.school_outlined, size: 18),
                label: Text(l10n.weakAreasTrain),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeakAreaRow extends StatelessWidget {
  const _WeakAreaRow({required this.summary});

  final DomainAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = (summary.accuracy / 100).clamp(0.0, 1.0);
    final tint = summary.accuracy >= 70
        ? Colors.tealAccent
        : summary.accuracy >= 50
        ? Colors.orangeAccent
        : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.domain,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${summary.accuracy}%',
                style: TextStyle(
                  color: tint,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(tint),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.answersWrong(summary.answered, summary.wrong),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StudySnapshot extends StatelessWidget {
  const _StudySnapshot({required this.state});

  final StudyState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (state.items.isEmpty) return const SizedBox.shrink();

    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SnapshotStat(
              label: l10n.snapshotReviewed,
              value:
                  '${state.items.where((item) => item.timesSeen > 0).length}',
            ),
          ),
          Expanded(
            child: _SnapshotStat(
              label: l10n.snapshotDueNow,
              value: '${state.dueCount}',
            ),
          ),
          Expanded(
            child: _SnapshotStat(
              label: l10n.snapshotWeak,
              value: '${state.weakCount}',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryStudyCard extends StatelessWidget {
  const _PrimaryStudyCard({required this.state, required this.notifier});

  final StudyState state;
  final StudyNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final queueCount = state.queueCount;
    final hasPreferredQueue = queueCount > 0;
    final startLabel = hasPreferredQueue
        ? l10n.studyStartWithQueue(state.selectedQueueType.label, queueCount)
        : l10n.studyStart;
    final supporting = hasPreferredQueue
        ? l10n.focusedRunMinutes(state.estimatedMinutes)
        : l10n.studyRandomFallback;

    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      radius: 22,
      tint: const Color(0xFF6C63FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.focusedPractice,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            supporting,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                notifier.setMode(StudyMode.srs);
                if (hasPreferredQueue) {
                  notifier.startSession();
                } else {
                  notifier.setQueueType(SessionQueueType.random);
                  notifier.startSession(reviewAnyway: true);
                }
              },
              icon: const Icon(Icons.psychology_outlined),
              label: Text(startLabel),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                notifier.setMode(StudyMode.speed);
                if (hasPreferredQueue) {
                  notifier.startSession();
                } else {
                  notifier.setQueueType(SessionQueueType.random);
                  notifier.startSession(reviewAnyway: true);
                }
              },
              icon: const Icon(Icons.bolt),
              label: Text(l10n.speedDrill),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSettingsCard extends StatelessWidget {
  const _SessionSettingsCard({
    required this.state,
    required this.notifier,
    required this.showCategoryFilters,
    required this.showTopicFilters,
    required this.canUseTopicSelection,
    required this.canRunLongSession,
    required this.onProGate,
  });

  final StudyState state;
  final StudyNotifier notifier;
  final bool showCategoryFilters;
  final bool showTopicFilters;
  final bool canUseTopicSelection;
  final bool canRunLongSession;
  final void Function(String label) onProGate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      padding: EdgeInsets.zero,
      radius: 22,
      tint: const Color(0xFF12B981),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Text(
            l10n.sessionSettings,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            l10n.sessionSettingsSummary(
              state.selectedQueueType.label,
              state.sessionLength,
              state.timerSeconds,
            ),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          children: [
            if (showCategoryFilters)
              _LauncherSection(
                label: 'Category',
                child: _ChipRow(
                  chips: ['All', ...state.categories],
                  selected: state.selectedCategory ?? 'All',
                  onSelect: (value) {
                    if (value != 'All' && !canUseTopicSelection) {
                      onProGate('Category filtering');
                      return;
                    }
                    notifier.setCategory(value == 'All' ? null : value);
                  },
                ),
              ),
            if (showTopicFilters)
              _LauncherSection(
                label: 'Topic',
                child: _ChipRow(
                  chips: ['All topics', ...state.topics],
                  selected: state.selectedTopic ?? 'All topics',
                  onSelect: (value) {
                    if (value != 'All topics' && !canUseTopicSelection) {
                      onProGate('Topic filtering');
                      return;
                    }
                    notifier.setTopic(value == 'All topics' ? null : value);
                  },
                ),
              ),
            _LauncherSection(
              label: 'Session Type',
              child: _QueueTypeChipRow(
                selected: state.selectedQueueType,
                state: state,
                onSelect: notifier.setQueueType,
              ),
            ),
            _LauncherSection(
              label: 'Questions',
              child: _ChipRow(
                chips: const ['5', '10', '20'],
                selected: '${state.sessionLength}',
                onSelect: (value) {
                  final length = int.parse(value);
                  if (length > 10 && !canRunLongSession) {
                    onProGate('Sessions with 20 questions');
                    return;
                  }
                  notifier.setSessionLength(length);
                },
              ),
            ),
            _LauncherSection(
              label: 'Timer',
              child: _ChipRow(
                chips: const ['5s', '8s', '12s'],
                selected: '${state.timerSeconds}s',
                onSelect: (value) => notifier.setTimerSeconds(
                  int.parse(value.replaceAll('s', '')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotStat extends StatelessWidget {
  const _SnapshotStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

// ============================================================================
// Preview pill
// ============================================================================

// ignore: unused_element
class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.state});
  final StudyState state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) return const SizedBox.shrink();

    final String label;
    if (state.selectedCategory == null) {
      label = 'All topics';
    } else if (state.selectedTopic != null) {
      label = '${state.selectedCategory} › ${state.selectedTopic}';
    } else {
      label = state.selectedCategory!;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withAlpha(22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(55)),
      ),
      child: Text(
        '$label  ·  Total: ${state.availableCount}  ·  Due: ${state.dueCount}  ·  Weak: ${state.weakCount}  ·  New: ${state.newCount}',
        style: const TextStyle(
          color: Color(0xFFADA8FF),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ============================================================================
// Start buttons
// ============================================================================

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.accentColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentColor ?? Colors.white70,
            side: BorderSide(
              color: accentColor ?? Colors.white.withAlpha(50),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _DisabledStartButton extends StatelessWidget {
  const _DisabledStartButton({
    required this.icon,
    required this.label,
    required this.reason,
  });
  final IconData icon;
  final String label;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.35,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 18),
            const SizedBox(width: 8),
            Text(
              '$label  ($reason)',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Library card
// ============================================================================

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.onOpen, this.deckTitle});
  final VoidCallback onOpen;
  final String? deckTitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withAlpha(18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C63FF).withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.library_books_outlined,
                color: Color(0xFFADA8FF),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deckTitle ?? 'Library / Import Packs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    deckTitle == null
                        ? 'Browse and import any JSON pack found in assets/decks/.'
                        : 'This is the active deck for Feed, Study and Exam.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Empty filter result
// ============================================================================

class _EmptyFilterResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: const Text(
        'No cards match the current category/topic selection.',
        style: TextStyle(color: Colors.white54, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ============================================================================
// Shared chip widgets
// ============================================================================

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.chips,
    required this.selected,
    required this.onSelect,
  });
  final List<String> chips;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map(
              (c) => _Chip(
                label: c,
                selected: c == selected,
                onTap: () => onSelect(c),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF)
              : Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : Colors.white.withAlpha(30),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Queue type chip row
// ============================================================================

class _QueueTypeChipRow extends StatelessWidget {
  const _QueueTypeChipRow({
    required this.selected,
    required this.state,
    required this.onSelect,
  });
  final SessionQueueType selected;
  final StudyState state;
  final void Function(SessionQueueType) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SessionQueueType.values.map((type) {
          final count = switch (type) {
            SessionQueueType.due => state.dueCount,
            SessionQueueType.weak => state.weakCount,
            SessionQueueType.newCards => state.newCount,
            SessionQueueType.random => state.availableCount,
          };
          final isSelected = type == selected;
          return GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withAlpha(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 13,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${type.label} $count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// Start buttons — queue-type aware
// ============================================================================

// ignore: unused_element
class _QueueStartButtons extends StatelessWidget {
  const _QueueStartButtons({required this.state, required this.notifier});
  final StudyState state;
  final StudyNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final queueCount = state.queueCount;
    final queueLabel = state.selectedQueueType.label;
    final hasCards = queueCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary SRS start button
        if (!hasCards) ...[
          _EmptyQueueBanner(queueType: state.selectedQueueType),
          const SizedBox(height: 10),
          _StartButton(
            icon: Icons.psychology_outlined,
            label: 'Review Random instead',
            outlined: true,
            onPressed: () {
              notifier.setQueueType(SessionQueueType.random);
              notifier.setMode(StudyMode.srs);
              notifier.startSession();
            },
          ),
        ] else
          _StartButton(
            icon: Icons.psychology_outlined,
            label: 'Study $queueLabel  ($queueCount cards)',
            onPressed: () {
              notifier.setMode(StudyMode.srs);
              notifier.startSession();
            },
          ),
        const SizedBox(height: 10),
        // Speed Drill always available if cards exist
        _StartButton(
          icon: Icons.bolt,
          label: hasCards
              ? 'Speed Drill  ($queueLabel · $queueCount cards)'
              : 'Speed Drill  (all ${state.availableCount} cards)',
          outlined: true,
          accentColor: const Color(0xFF6C63FF),
          onPressed: () {
            notifier.setMode(StudyMode.speed);
            if (!hasCards) {
              notifier.startSession(reviewAnyway: true);
            } else {
              notifier.startSession();
            }
          },
        ),
      ],
    );
  }
}

// ============================================================================
// Empty queue banner (per queue type)
// ============================================================================

class _EmptyQueueBanner extends StatelessWidget {
  const _EmptyQueueBanner({required this.queueType});
  final SessionQueueType queueType;

  @override
  Widget build(BuildContext context) {
    final (emoji, message) = switch (queueType) {
      SessionQueueType.due => (
        '🎉',
        'No cards due for review. Great job!\nCome back later, or switch to Random.',
      ),
      SessionQueueType.weak => (
        '💪',
        'No weak cards found.\nKeep studying to track your mistakes.',
      ),
      SessionQueueType.newCards => (
        '📭',
        'No new cards left.\nImport a deck pack or add from Feed.',
      ),
      SessionQueueType.random => ('🃏', 'No cards available.'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Pro dialog
// ============================================================================
