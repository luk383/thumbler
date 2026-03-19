import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/ui/app_surfaces.dart';
import '../../../goals/state/goals_notifier.dart';
import '../../../habits/state/habits_notifier.dart';
import '../../../journal/domain/journal_entry.dart';
import '../../../journal/state/journal_notifier.dart';
import '../../../reflection/domain/reflection_entry.dart';
import '../../../reflection/state/reflection_notifier.dart';
import '../../../study/data/study_session_storage.dart';
import '../../../study/domain/study_session.dart';
import '../../../study/presentation/controllers/deck_library_controller.dart';
import '../../domain/progress_analytics.dart';
import '../providers/progress_analytics_provider.dart';

class ProgressAnalyticsPage extends ConsumerWidget {
  const ProgressAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final analytics = ref.watch(progressAnalyticsProvider);
    final activeDeck = ref.watch(activeDeckMetaProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          AppPageIntro(
            title: l10n.progressTitle,
            subtitle: l10n.progressSubtitle,
          ),
          const SizedBox(height: 16),
          _DeckScopeCard(deckTitle: activeDeck?.title),
          const SizedBox(height: 16),
          if (!analytics.hasAnyData) ...[
            const _EmptyAnalyticsCard(),
          ] else ...[
            _OverviewCard(analytics: analytics),
            const SizedBox(height: 16),
            _RecentActivityCard(points: analytics.recentActivity),
            const SizedBox(height: 24),
            AppSectionHeader(l10n.byDomain),
            const SizedBox(height: 10),
            if (analytics.domainSummaries.isEmpty)
              _InfoCard(message: l10n.domainAnalyticsHint)
            else
              ...analytics.domainSummaries.map(
                (summary) => _DomainRow(summary: summary),
              ),
            const SizedBox(height: 24),
            AppSectionHeader(l10n.weakestDomains),
            const SizedBox(height: 10),
            if (analytics.weakestDomains.isEmpty)
              _InfoCard(message: l10n.weakestDomainsHint)
            else
              ...analytics.weakestDomains.map(
                (summary) => _WeakDomainCard(summary: summary),
              ),
          ],
          const SizedBox(height: 24),
          const _SessionAccuracyTrendSection(),
          const SizedBox(height: 24),
          const _GrowthDashboardSection(),
        ],
      ),
    );
  }
}

class _DeckScopeCard extends StatelessWidget {
  const _DeckScopeCard({required this.deckTitle});

  final String? deckTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      padding: const EdgeInsets.all(14),
      tint: const Color(0xFF6C63FF),
      child: Row(
        children: [
          const AppSurfaceIcon(
            icon: Icons.layers_outlined,
            tint: Color(0xFFADA8FF),
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.activeDeckScope,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  deckTitle ?? l10n.legacyUnscopedData,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (deckTitle == null) ...[
                  const SizedBox(height: 3),
                  Text(
                    l10n.legacyUnscopedDataHelp,
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.analytics});

  final ProgressAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      tint: const Color(0xFF6C63FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.overview,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: l10n.answeredLabel,
                  value: '${analytics.totalAnswered}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: l10n.accuracyLabel,
                  value: '${analytics.correctRate}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: l10n.cardsReviewedLabel,
                  value:
                      '${analytics.reviewedCards}/${analytics.totalTrackedCards}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: l10n.completedExamsLabel,
                  value: '${analytics.totalCompletedExams}',
                ),
              ),
            ],
          ),
          if (analytics.totalCompletedExams > 0) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withAlpha(22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withAlpha(55),
                ),
              ),
              child: Text(
                l10n.examOverviewScores(
                  analytics.lastExamScore ?? 0,
                  analytics.averageExamScore,
                ),
                style: const TextStyle(
                  color: Color(0xFFADA8FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(6),
            const Color(0xFF6C63FF).withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.points});

  final List<RecentActivityPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxActivity = points.fold<int>(
      0,
      (max, point) => point.totalActivity > max ? point.totalActivity : max,
    );

    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      tint: const Color(0xFF6C63FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recentActivityTitle,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.recentActivitySubtitle,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (maxActivity == 0)
            Text(
              l10n.noRecentActivity,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.map((point) {
                  final height = (point.totalActivity / maxActivity) * 92;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${point.totalActivity}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: height.toDouble(),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF3B37C8)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            point.label,
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DomainRow extends StatelessWidget {
  const _DomainRow({required this.summary});

  final DomainAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      tint: summary.accuracy >= 70
          ? Colors.greenAccent
          : summary.accuracy >= 50
          ? Colors.orangeAccent
          : Colors.redAccent,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${summary.accuracy}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.accuracy / 100,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(
                summary.accuracy >= 70
                    ? Colors.greenAccent
                    : summary.accuracy >= 50
                    ? Colors.orangeAccent
                    : Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.domainStats(summary.answered, summary.correct, summary.wrong),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WeakDomainCard extends StatelessWidget {
  const _WeakDomainCard({required this.summary});

  final DomainAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      tint: Colors.orange,
      child: Row(
        children: [
          const AppSurfaceIcon(
            icon: Icons.trending_down_outlined,
            tint: Colors.orange,
            size: 34,
            iconSize: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.weakDomainSummary(
                summary.domain,
                summary.accuracy,
                summary.answered,
              ),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppEmptyStateCard(
      icon: Icons.insights_outlined,
      title: l10n.noAnalyticsYet,
      message: l10n.noAnalyticsYetMessage,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.all(14),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
    );
  }
}

// ── Session Accuracy Trend ────────────────────────────────────────────────────

class _SessionAccuracyTrendSection extends StatelessWidget {
  const _SessionAccuracyTrendSection();

  @override
  Widget build(BuildContext context) {
    final sessions = StudySessionStorage().getLast7Days();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader('Andamento sessioni (7 giorni)'),
        const SizedBox(height: 10),
        AppGlassCard(
          padding: const EdgeInsets.all(16),
          tint: const Color(0xFF6C63FF),
          child: sessions.isEmpty
              ? const Text(
                  'Nessuna sessione completata negli ultimi 7 giorni.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accuratezza per sessione',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: sessions.take(7).map((session) {
                          final acc = session.accuracyPct;
                          final height = (acc / 100) * 90;
                          final barColor = acc >= 80
                              ? Colors.greenAccent
                              : acc >= 60
                                  ? Colors.orangeAccent
                                  : Colors.redAccent;
                          final dateLabel = DateFormat('d/M').format(session.date);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '$acc%',
                                    style: TextStyle(
                                      color: barColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: height.toDouble().clamp(4.0, 90.0),
                                    decoration: BoxDecoration(
                                      color: barColor.withAlpha(180),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    dateLabel,
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SessionSummaryRow(sessions: sessions),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SessionSummaryRow extends StatelessWidget {
  const _SessionSummaryRow({required this.sessions});

  final List<StudySession> sessions;

  @override
  Widget build(BuildContext context) {
    final totalCards =
        sessions.fold<int>(0, (sum, s) => sum + s.cardCount);
    final totalCorrect =
        sessions.fold<int>(0, (sum, s) => sum + s.correctCount);
    final avgAccuracy = totalCards == 0
        ? 0
        : ((totalCorrect / totalCards) * 100).round();

    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            label: 'Sessioni',
            value: '${sessions.length}',
          ),
        ),
        Expanded(
          child: _MiniMetric(
            label: 'Carte tot.',
            value: '$totalCards',
          ),
        ),
        Expanded(
          child: _MiniMetric(
            label: 'Media acc.',
            value: '$avgAccuracy%',
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      );
}

// ── Growth Dashboard ──────────────────────────────────────────────────────────

class _GrowthDashboardSection extends ConsumerWidget {
  const _GrowthDashboardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final goals = ref.watch(goalsProvider);
    final journal = ref.watch(journalProvider);
    final reflections = ref.watch(reflectionProvider);

    // Habit completion rate — last 7 days
    final habitRate = _habitRate7Days(habits);

    // Goal progress — avg across active goals
    final activeGoals = goals.where((g) => !g.completed).toList();
    final goalProgress = activeGoals.isEmpty
        ? 0.0
        : activeGoals.fold<double>(0, (s, g) => s + g.progress) /
            activeGoals.length;

    // Mood trend — last 5 journal entries with mood
    final moodEntries = journal
        .where((e) => e.mood != null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentMoods = moodEntries.take(5).cast<JournalEntry>().toList();

    // Reflection completion — last 4 weeks
    final reflectionRate = _reflectionRate4Weeks(reflections);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader('Crescita Personale'),
        const SizedBox(height: 10),
        AppGlassCard(
          padding: const EdgeInsets.all(16),
          tint: Colors.tealAccent,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _GrowthMetric(
                      icon: '✅',
                      label: 'Abitudini\n(7 giorni)',
                      value: '${(habitRate * 100).round()}%',
                      color: habitRate >= 0.7
                          ? Colors.greenAccent
                          : habitRate >= 0.4
                              ? Colors.orangeAccent
                              : Colors.redAccent,
                    ),
                  ),
                  Expanded(
                    child: _GrowthMetric(
                      icon: '🎯',
                      label: 'Progressi\nobiettivi',
                      value: '${(goalProgress * 100).round()}%',
                      color: Colors.tealAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GrowthMetric(
                      icon: '📓',
                      label: 'Riflessioni\n(4 settimane)',
                      value: '${(reflectionRate * 100).round()}%',
                      color: Colors.purpleAccent,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('😊 Umore recente',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 6),
                        if (recentMoods.isEmpty)
                          const Text('—',
                              style: TextStyle(color: Colors.white54))
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: recentMoods
                                .map((e) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      child: Text(e.mood!.emoji,
                                          style: const TextStyle(fontSize: 18)),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _habitRate7Days(List habits) {
    if (habits.isEmpty) return 0;
    final now = DateTime.now();
    var total = 0;
    var done = 0;
    for (var i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      total += habits.length;
      done +=
          habits.where((h) => h.isDoneOn(d)).length;
    }
    return total == 0 ? 0 : done / total;
  }

  double _reflectionRate4Weeks(List reflections) {
    var done = 0;
    for (var i = 0; i < 4; i++) {
      final weekStart = ReflectionEntry.currentWeekStart()
          .subtract(Duration(days: 7 * i));
      final found = reflections.any(
        (r) => r.weekStart.isAtSameMomentAs(weekStart) && !r.isEmpty,
      );
      if (found) done++;
    }
    return done / 4;
  }
}

class _GrowthMetric extends StatelessWidget {
  const _GrowthMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('$icon $value',
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      );
}
