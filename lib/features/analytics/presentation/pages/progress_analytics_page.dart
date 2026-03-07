import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_surfaces.dart';
import '../../../study/presentation/controllers/deck_library_controller.dart';
import '../../domain/progress_analytics.dart';
import '../providers/progress_analytics_provider.dart';

class ProgressAnalyticsPage extends ConsumerWidget {
  const ProgressAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(progressAnalyticsProvider);
    final activeDeck = ref.watch(activeDeckMetaProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const AppPageIntro(
            title: 'Progress',
            subtitle:
                'A lightweight read of what is improving, what is weak, and how active you have been lately.',
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
            const AppSectionHeader('By Domain'),
            const SizedBox(height: 10),
            if (analytics.domainSummaries.isEmpty)
              const _InfoCard(
                message:
                    'Answer study cards or exam questions to unlock domain analytics.',
              )
            else
              ...analytics.domainSummaries.map(
                (summary) => _DomainRow(summary: summary),
              ),
            const SizedBox(height: 24),
            const AppSectionHeader('Weakest Domains'),
            const SizedBox(height: 10),
            if (analytics.weakestDomains.isEmpty)
              const _InfoCard(
                message:
                    'Weakest domains will appear after you answer enough questions.',
              )
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
                const Text(
                  'Active Deck Scope',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  deckTitle ?? 'Legacy / unscoped local data',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (deckTitle == null) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'These metrics only reflect local items and results without an active deck binding.',
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
    return AppGlassCard(
      padding: const EdgeInsets.all(18),
      tint: const Color(0xFF6C63FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
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
                  label: 'Answered',
                  value: '${analytics.totalAnswered}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Accuracy',
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
                  label: 'Cards Reviewed',
                  value:
                      '${analytics.reviewedCards}/${analytics.totalTrackedCards}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Completed Exams',
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
                'Last exam: ${analytics.lastExamScore ?? 0}%  •  Average exam: ${analytics.averageExamScore}%',
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
          const Text(
            'Recent Activity',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cards reviewed and exams completed in the last 7 days',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (maxActivity == 0)
            const Text(
              'No recent local study or exam activity found.',
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
            '${summary.answered} answered  •  ${summary.correct} correct  •  ${summary.wrong} wrong',
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
              '${summary.domain}  •  ${summary.accuracy}% accuracy across ${summary.answered} answers',
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
    return const AppEmptyStateCard(
      icon: Icons.insights_outlined,
      title: 'No analytics yet',
      message:
          'Study cards or complete an exam to unlock local progress analytics.',
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
