import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/exam_result.dart';
import '../../../study/presentation/controllers/deck_library_controller.dart';
import '../controllers/exam_controller.dart';

class ExamHistoryPage extends ConsumerWidget {
  const ExamHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allResults = ref.watch(examProvider.select((s) => s.results));
    final notifier = ref.read(examProvider.notifier);
    final activeDeck = ref.watch(activeDeckMetaProvider);
    final results = activeDeck == null
        ? allResults
        : allResults.where((result) => result.deckId == activeDeck.id).toList();
    final summary = ExamHistorySummary.fromResults(results);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Exam History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (results.isNotEmpty)
            IconButton(
              tooltip: 'Clear visible history',
              onPressed: () async {
                final confirmed = await _confirmHistoryAction(
                  context,
                  title: 'Clear exam history?',
                  message: activeDeck == null
                      ? 'This removes all locally saved exam history entries.'
                      : 'This removes all locally saved exam history entries for ${activeDeck.title}.',
                  confirmLabel: 'Clear history',
                );
                if (confirmed != true || !context.mounted) return;
                notifier.clearHistoryForActiveDeck();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exam history cleared')),
                );
              },
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _SummaryCard(summary: summary),
          const SizedBox(height: 16),
          _ScoreTrendCard(results: results),
          if (summary.mostImprovedDomainMessage case final message?) ...[
            const SizedBox(height: 16),
            _InsightCard(message: message),
          ],
          const SizedBox(height: 24),
          const _SectionLabel('Exam History'),
          const SizedBox(height: 10),
          if (results.isEmpty)
            const _EmptyHistoryCard()
          else
            ...List.generate(results.length, (index) {
              final result = results[index];
              return _ExamHistoryItem(
                index: index,
                result: result,
                onDelete: () async {
                  final confirmed = await _confirmHistoryAction(
                    context,
                    title: 'Delete exam attempt?',
                    message:
                        'This removes the selected exam result from local history only.',
                    confirmLabel: 'Delete',
                  );
                  if (confirmed != true || !context.mounted) return;
                  notifier.deleteHistoryEntry(result.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exam attempt deleted')),
                  );
                },
                onTap: () =>
                    context.push('/exam/history/detail', extra: result),
              );
            }),
        ],
      ),
    );
  }
}

class ExamHistorySummary {
  const ExamHistorySummary({
    required this.lastScore,
    required this.bestScore,
    required this.averageScore,
    required this.totalExams,
    required this.mostImprovedDomainMessage,
  });

  final int lastScore;
  final int bestScore;
  final int averageScore;
  final int totalExams;
  final String? mostImprovedDomainMessage;

  factory ExamHistorySummary.fromResults(List<ExamResult> results) {
    final latest = results.isNotEmpty ? results.first : null;
    final bestScore = results.isEmpty
        ? 0
        : results.map((r) => r.percentageScore).reduce((a, b) => a > b ? a : b);
    final averageScore = results.isEmpty
        ? 0
        : (results.map((r) => r.percentageScore).reduce((a, b) => a + b) /
                  results.length)
              .round();

    return ExamHistorySummary(
      lastScore: latest?.percentageScore ?? 0,
      bestScore: bestScore,
      averageScore: averageScore,
      totalExams: results.length,
      mostImprovedDomainMessage: _mostImprovedDomain(results),
    );
  }
}

String? _mostImprovedDomain(List<ExamResult> results) {
  if (results.length < 2) return null;
  final latest = results[0];
  final previous = results[1];

  String? bestDomain;
  double? bestDelta;

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
  return 'Most improved domain: $bestDomain (+${bestDelta.round()}%)';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ExamHistorySummary summary;

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
            child: _Metric(label: 'Last', value: '${summary.lastScore}%'),
          ),
          Expanded(
            child: _Metric(label: 'Best', value: '${summary.bestScore}%'),
          ),
          Expanded(
            child: _Metric(label: 'Average', value: '${summary.averageScore}%'),
          ),
          Expanded(
            child: _Metric(label: 'Exams', value: '${summary.totalExams}'),
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

class _ScoreTrendCard extends StatelessWidget {
  const _ScoreTrendCard({required this.results});

  final List<ExamResult> results;

  @override
  Widget build(BuildContext context) {
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
            'Score Trend',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Recent exams over time',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (results.isEmpty)
            const Text(
              'Complete an exam to start tracking your progress.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else ...[
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: results.reversed.map((result) {
                  final height =
                      (result.percentageScore.clamp(8, 100) / 100) * 92;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${result.percentageScore}%',
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
                          const SizedBox(height: 6),
                          Text(
                            _formatShortDate(result.completedAt),
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
            const SizedBox(height: 12),
            Text(
              results.reversed
                  .map((r) => '${r.percentageScore}%')
                  .join('  •  '),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.message});

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

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: const Text(
        'No completed exams yet. Finish your first exam to unlock score trend and domain analytics.',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }
}

class _ExamHistoryItem extends StatelessWidget {
  const _ExamHistoryItem({
    required this.index,
    required this.result,
    required this.onDelete,
    required this.onTap,
  });

  final int index;
  final ExamResult result;
  final Future<void> Function() onDelete;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exam ${index + 1}  •  ${result.percentageScore}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      '${result.totalQuestions} questions',
                      if (result.durationSeconds != null)
                        _formatDuration(result.durationSeconds!),
                      _formatShortDateTime(result.completedAt),
                    ].join('  •  '),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  if (result.deckTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.deckTitle!,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () {
                onDelete();
              },
              icon: const Icon(Icons.delete_outline, color: Colors.white38),
            ),
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

String _formatShortDateTime(DateTime d) {
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '${_formatShortDate(d)}  $hour:$minute';
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (minutes <= 0) return '${remainingSeconds}s';
  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}

Future<bool?> _confirmHistoryAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
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
    ),
  );
}
