import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/exam_attempt.dart';
import '../../../study/domain/study_item.dart';
import '../../../study/presentation/controllers/study_controller.dart';
import '../controllers/exam_controller.dart';
import '../controllers/exam_state.dart';

class ExamResultsPage extends ConsumerWidget {
  const ExamResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(examProvider);
    final n = ref.read(examProvider.notifier);

    if (s.phase == ExamPhase.reviewing) {
      return _ReviewPage(state: s, notifier: n);
    }

    final attempt = s.activeAttempt;
    if (attempt == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: ElevatedButton(
              onPressed: n.backToHome,
              child: const Text('Back'),
            ),
          ),
        ),
      );
    }

    return _ResultsContent(
      attempt: attempt,
      sessionQuestions: s.sessionQuestions,
      notifier: n,
    );
  }
}

// ── Results content ───────────────────────────────────────────────────────────

class _ResultsContent extends StatelessWidget {
  const _ResultsContent({
    required this.attempt,
    required this.sessionQuestions,
    required this.notifier,
  });

  final ExamAttempt attempt;
  final List<StudyItem> sessionQuestions;
  final ExamNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final pct = attempt.totalQuestions == 0
        ? 0
        : (attempt.scoreCorrect / attempt.totalQuestions * 100).round();
    final passed = pct >= 75;
    final scoreColor = passed ? Colors.green : Colors.redAccent;

    final elapsedMin = attempt.elapsedSeconds ~/ 60;
    final elapsedSec = attempt.elapsedSeconds % 60;

    final domainStats = _groupStats(
      questions: sessionQuestions,
      attempt: attempt,
      keyFor: (q) => q.category,
    );
    final sortedDomains = _sortWeakest(domainStats).take(3).toList();
    final weakestDomain = _pickWeakest(domainStats, minQuestions: 3);

    final topicStatsInWeakestDomain = weakestDomain == null
        ? const <_AreaStat>[]
        : _sortWeakest(
            _groupStats(
              questions: sessionQuestions
                  .where(
                    (q) => q.category == weakestDomain.key && q.topic != null,
                  )
                  .toList(),
              attempt: attempt,
              keyFor: (q) => q.topic!,
            ),
          ).take(3).toList();
    final weakestTopic = _pickWeakest(
      topicStatsInWeakestDomain,
      minQuestions: 3,
    );

    final objectiveStats = _groupStats(
      questions: sessionQuestions
          .where((q) => q.objectiveId != null && q.objectiveId!.isNotEmpty)
          .toList(),
      attempt: attempt,
      keyFor: (q) => q.objectiveId!,
    );
    final weakestObjective = _pickWeakest(objectiveStats, minQuestions: 3);

    final wrongIds = sessionQuestions
        .where((q) {
          final selected = attempt.answers[q.id];
          return selected == null || selected != q.correctAnswerIndex;
        })
        .map((q) => q.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          children: [
            // ── Score hero ───────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    passed ? '🏆' : '📊',
                    style: const TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    passed ? 'PASS (≥75%)' : 'FAIL (<75%)',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Stats chips ──────────────────────────────────────────────
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(
                  label: 'Correct',
                  value: '${attempt.scoreCorrect}',
                  color: Colors.green,
                ),
                _StatChip(
                  label: 'Wrong',
                  value:
                      '${attempt.totalQuestions - attempt.scoreCorrect - attempt.unansweredCount}',
                  color: Colors.redAccent,
                ),
                _StatChip(
                  label: 'Unanswered',
                  value: '${attempt.unansweredCount}',
                  color: Colors.white54,
                ),
                _StatChip(
                  label: 'Time used',
                  value: '${elapsedMin}m ${elapsedSec}s',
                  color: Colors.white60,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Domain breakdown ─────────────────────────────────────────
            if (sortedDomains.isNotEmpty) ...[
              const _SectionLabel('Domain Breakdown'),
              const SizedBox(height: 8),
              ...sortedDomains.map((e) => _WeakAreaRow(stat: e)),
              const SizedBox(height: 28),
            ],

            // ── Weak areas bridge ───────────────────────────────────────
            const _SectionLabel('Weak Areas'),
            const SizedBox(height: 8),
            if (sortedDomains.isEmpty)
              const Text(
                'Not enough grouped data to detect weak areas yet.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              )
            else ...[
              ...sortedDomains.map((e) => _WeakAreaRow(stat: e)),
              if (topicStatsInWeakestDomain.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Weakest topics in ${weakestDomain?.key}:',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 6),
                ...topicStatsInWeakestDomain.map(
                  (e) => _WeakAreaRow(stat: e, compact: true),
                ),
              ],
              if (weakestObjective != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Weakest objective: ${weakestObjective.key} (${weakestObjective.percentageInt}%)',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
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
                            '/study?category=${Uri.encodeComponent(weakestDomain.key)}'
                            '&mode=study&source=exam_bridge&autostart=true'
                            '&lastExamAttemptId=${Uri.encodeComponent(attempt.id)}',
                          );
                        },
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: Text(
                    'Train Weakest Domain'
                    '${weakestDomain != null ? ' (${weakestDomain.key})' : ''}',
                  ),
                ),
              ),
              if (weakestTopic != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF236BFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.go(
                        '/study?category=${Uri.encodeComponent(weakestDomain!.key)}'
                        '&topic=${Uri.encodeComponent(weakestTopic.key)}'
                        '&mode=study&source=exam_bridge&autostart=true'
                        '&lastExamAttemptId=${Uri.encodeComponent(attempt.id)}',
                      );
                    },
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: const Text('Train Weakest Topic'),
                  ),
                ),
              ],
              if (wrongIds.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.withAlpha(200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.go(
                        '/study',
                        extra: StudyExternalSessionRequest(
                          source: 'exam_bridge',
                          questionIds: wrongIds,
                          autostart: true,
                          sessionLength: 10,
                          lastExamAttemptId: attempt.id,
                        ),
                      );
                    },
                    icon: const Icon(Icons.replay_outlined, size: 18),
                    label: const Text('Train Wrong Answers'),
                  ),
                ),
              ],
              const SizedBox(height: 28),
            ],

            // ── Actions ──────────────────────────────────────────────────
            if (attempt.scoreCorrect < attempt.totalQuestions) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withAlpha(200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: notifier.startReview,
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: Text(
                    'Review Wrong  (${attempt.totalQuestions - attempt.scoreCorrect})',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: notifier.backToHome,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('New Exam'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaStat {
  const _AreaStat({
    required this.key,
    required this.total,
    required this.correct,
    this.category,
  });

  final String key;
  final int total;
  final int correct;
  final String? category;

  double get percentage => total == 0 ? 0 : correct / total;
  int get percentageInt => (percentage * 100).round();
}

List<_AreaStat> _groupStats({
  required List<StudyItem> questions,
  required ExamAttempt attempt,
  required String Function(StudyItem) keyFor,
}) {
  final stats = <String, _AreaStat>{};
  for (final q in questions) {
    final key = keyFor(q).trim();
    if (key.isEmpty) continue;
    final selected = attempt.answers[q.id];
    final correct = selected != null && selected == q.correctAnswerIndex;
    final prev = stats[key];
    stats[key] = _AreaStat(
      key: key,
      total: (prev?.total ?? 0) + 1,
      correct: (prev?.correct ?? 0) + (correct ? 1 : 0),
      category: q.category,
    );
  }
  return stats.values.toList();
}

List<_AreaStat> _sortWeakest(List<_AreaStat> items) {
  final sorted = [...items];
  sorted.sort((a, b) {
    final byAccuracy = a.percentage.compareTo(b.percentage);
    if (byAccuracy != 0) return byAccuracy;
    return b.total.compareTo(a.total);
  });
  return sorted;
}

_AreaStat? _pickWeakest(List<_AreaStat> items, {int minQuestions = 3}) {
  final eligible = items.where((e) => e.total >= minQuestions).toList();
  if (eligible.isEmpty) return null;
  return _sortWeakest(eligible).first;
}

// ── Section label ─────────────────────────────────────────────────────────────

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

class _WeakAreaRow extends StatelessWidget {
  const _WeakAreaRow({required this.stat, this.compact = false});
  final _AreaStat stat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pct = stat.percentageInt;
    final color = pct >= 75
        ? Colors.green
        : pct >= 50
        ? Colors.orange
        : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 8 : 11),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stat.key,
              style: TextStyle(
                color: Colors.white70,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${stat.correct}/${stat.total}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '$pct%',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Review page ───────────────────────────────────────────────────────────────

class _ReviewPage extends StatelessWidget {
  const _ReviewPage({required this.state, required this.notifier});
  final ExamState state;
  final ExamNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final items = state.reviewQuestions;
    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎯', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                const Text(
                  'All answers were correct!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: notifier.backToResults,
                  child: const Text('Back to Results'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = state.currentQuestion!;
    final attempt = state.activeAttempt!;
    final userAnswer = attempt.answers[item.id];
    final total = items.length;
    final current = state.currentIndex + 1;
    const optionLabels = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              'Review Wrong Answers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$current / $total',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: notifier.backToResults,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, color: Colors.white60, size: 18),
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withAlpha(35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${item.category}${item.topic != null ? ' › ${item.topic}' : ''}',
                        style: const TextStyle(
                          color: Color(0xFFADA8FF),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Question text
                    Text(
                      item.promptText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Options with correct/wrong highlight
                    ...List.generate(item.options.length, (i) {
                      final label = i < optionLabels.length
                          ? optionLabels[i]
                          : '$i';
                      final isCorrect = i == item.correctAnswerIndex;
                      final isUserWrong = userAnswer == i && !isCorrect;

                      Color bg = Colors.white.withAlpha(10);
                      Color borderColor = Colors.white.withAlpha(22);
                      Color textColor = Colors.white54;

                      if (isCorrect) {
                        bg = Colors.green.withAlpha(38);
                        borderColor = Colors.green;
                        textColor = Colors.green;
                      } else if (isUserWrong) {
                        bg = Colors.redAccent.withAlpha(35);
                        borderColor = Colors.redAccent;
                        textColor = Colors.redAccent;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Colors.green
                                    : isUserWrong
                                    ? Colors.redAccent.withAlpha(120)
                                    : Colors.white.withAlpha(18),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: (isCorrect || isUserWrong)
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.options[i],
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: isCorrect
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isCorrect)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                            if (isUserWrong)
                              const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                          ],
                        ),
                      );
                    }),

                    // Explanation (if present)
                    if (item.explanationText != null &&
                        item.explanationText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(18)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFADA8FF),
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.explanationText!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // No answer note
                    if (userAnswer == null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⚠️  You did not answer this question.',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom nav for review
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: BorderSide(color: Colors.white.withAlpha(30)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onPressed: state.currentIndex == 0
                        ? null
                        : notifier.previous,
                    icon: const Icon(Icons.arrow_back_ios, size: 14),
                    label: const Text('Prev'),
                  ),
                  const Spacer(),
                  state.currentIndex == total - 1
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          onPressed: notifier.backToResults,
                          child: const Text('Back to Results'),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          onPressed: notifier.next,
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          label: const Text('Next'),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
