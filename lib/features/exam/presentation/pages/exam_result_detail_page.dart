import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/exam_result.dart';
import '../../../study/presentation/controllers/study_controller.dart';
import '../controllers/exam_controller.dart';

class ExamResultDetailPage extends ConsumerWidget {
  const ExamResultDetailPage({super.key, required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedDomains = result.domainScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakestDomain = result.weakestDomain;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Exam Detail',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete result',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF161616),
                  title: const Text(
                    'Delete exam result?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'This removes the result from local exam history.',
                    style: TextStyle(color: Colors.white70),
                  ),
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
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              ref.read(examProvider.notifier).deleteHistoryEntry(result.id);
              context.pop();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.percentageScore}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    'Correct ${result.correctAnswers}',
                    'Wrong ${result.wrongAnswers}',
                    '${result.totalQuestions} questions',
                    if (result.durationSeconds != null)
                      _formatDuration(result.durationSeconds!),
                  ].join(' · '),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (result.deckTitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.deckTitle!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
                if (weakestDomain != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Weakest domain: $weakestDomain',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'DOMAIN BREAKDOWN',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          if (sortedDomains.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              child: const Text(
                'No domain breakdown is available for this exam.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            )
          else
            ...sortedDomains.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      _formatPercent(entry.value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D8B5F),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: weakestDomain == null
                  ? null
                  : () {
                      context.go(
                        '/study?category=${Uri.encodeComponent(weakestDomain)}'
                        '&source=exam_bridge&autostart=true'
                        '&lastExamAttemptId=${Uri.encodeComponent(result.id)}',
                      );
                    },
              icon: const Icon(Icons.school_outlined, size: 18),
              label: const Text('Train Weakest Domain'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.withAlpha(200),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: result.wrongQuestionIds.isEmpty
                  ? null
                  : () {
                      context.go(
                        '/study',
                        extra: StudyExternalSessionRequest(
                          source: 'exam_bridge',
                          questionIds: result.wrongQuestionIds,
                          autostart: true,
                          sessionLength: result.wrongQuestionIds.length,
                          lastExamAttemptId: result.id,
                        ),
                      );
                    },
              icon: const Icon(Icons.replay_outlined, size: 18),
              label: const Text('Review Wrong Answers'),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (minutes <= 0) return '${remainingSeconds}s';
  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}

String _formatPercent(double value) {
  final rounded = value.roundToDouble();
  final text = rounded == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text%';
}
