import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/exam_result.dart';
import '../controllers/exam_controller.dart';

class ExamHistoryPage extends ConsumerWidget {
  const ExamHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(examProvider.select((s) => s.results));
    final latest = results.isNotEmpty ? results.first : null;
    final bestScore = results.isEmpty
        ? 0
        : results.map((r) => r.percentageScore).reduce((a, b) => a > b ? a : b);
    final averageScore = results.isEmpty
        ? 0
        : (results.map((r) => r.percentageScore).reduce((a, b) => a + b) /
                  results.length)
              .round();
    final improvement = _mostImprovedDomain(results);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Exam History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _SummaryCard(
            lastScore: latest?.percentageScore ?? 0,
            bestScore: bestScore,
            averageScore: averageScore,
            totalExams: results.length,
          ),
          if (results.length >= 2) ...[
            const SizedBox(height: 16),
            _ScoreHistoryChart(results: results),
          ],
          if (improvement != null) ...[
            const SizedBox(height: 16),
            _ImprovementCard(message: improvement),
          ],
          const SizedBox(height: 24),
          const _SectionLabel('Exam History'),
          const SizedBox(height: 8),
          if (results.isEmpty)
            const Text(
              'No completed exams yet.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            ...List.generate(results.length, (index) {
              final result = results[index];
              return _ExamHistoryItem(
                index: index,
                result: result,
                onTap: () =>
                    context.push('/exam/history/detail', extra: result),
              );
            }),
        ],
      ),
    );
  }
}

String? _mostImprovedDomain(List<ExamResult> results) {
  if (results.length < 2) return null;
  final latest = results[0];
  final previous = results[1];

  String? bestDomain;
  int? bestDelta;

  for (final entry in latest.domainScores.entries) {
    final previousScore = previous.domainScores[entry.key];
    if (previousScore == null) continue;
    final delta = entry.value - previousScore;
    if (bestDelta == null || delta > bestDelta) {
      bestDelta = delta;
      bestDomain = entry.key;
    }
  }

  if (bestDomain == null || bestDelta == null || bestDelta <= 0) return null;
  return 'Most improved domain: $bestDomain (+$bestDelta%)';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.lastScore,
    required this.bestScore,
    required this.averageScore,
    required this.totalExams,
  });

  final int lastScore;
  final int bestScore;
  final int averageScore;
  final int totalExams;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(label: 'Last', value: '$lastScore%'),
          ),
          Expanded(
            child: _Metric(label: 'Best', value: '$bestScore%'),
          ),
          Expanded(
            child: _Metric(label: 'Average', value: '$averageScore%'),
          ),
          Expanded(
            child: _Metric(label: 'Exams', value: '$totalExams'),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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
            fontWeight: FontWeight.bold,
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

class _ScoreHistoryChart extends StatelessWidget {
  const _ScoreHistoryChart({required this.results});

  final List<ExamResult> results;

  @override
  Widget build(BuildContext context) {
    final chronological = results.reversed.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score history',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chronological.map((result) {
              final height = (result.percentageScore.clamp(5, 100) / 100) * 90;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${result.percentageScore}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: height.toDouble(),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            chronological.map((r) => '${r.percentageScore}').join(' → '),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ImprovementCard extends StatelessWidget {
  const _ImprovementCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withAlpha(60)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
      ),
    );
  }
}

class _ExamHistoryItem extends StatelessWidget {
  const _ExamHistoryItem({
    required this.index,
    required this.result,
    required this.onTap,
  });

  final int index;
  final ExamResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Exam ${index + 1} — ${result.percentageScore}% — '
                '${result.totalQuestions} questions — ${_formatShortDate(result.completedAt)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: Colors.white38,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );
}

String _formatShortDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}
