import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/ui/app_surfaces.dart';
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
