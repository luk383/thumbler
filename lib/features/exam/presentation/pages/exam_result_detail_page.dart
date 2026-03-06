import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/exam_result.dart';
import '../../../study/presentation/controllers/study_controller.dart';

class ExamResultDetailPage extends StatelessWidget {
  const ExamResultDetailPage({super.key, required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
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
                  'Correct ${result.correctAnswers} · Wrong ${result.wrongAnswers} · ${result.totalQuestions} questions',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
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
                    '${entry.value}%',
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
                        '&mode=study&source=exam_bridge&autostart=true'
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
