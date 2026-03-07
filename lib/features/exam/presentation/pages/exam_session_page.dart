import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../controllers/exam_controller.dart';
import '../controllers/exam_state.dart';

class ExamSessionPage extends ConsumerWidget {
  const ExamSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(examProvider);
    final n = ref.read(examProvider.notifier);
    final l10n = AppLocalizations.of(context);

    // Pop intercept → pause dialog.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _showPauseDialog(context, n, l10n),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(state: s, notifier: n, l10n: l10n),
              _ProgressBar(
                value: s.activeAttempt == null || s.sessionQuestions.isEmpty
                    ? 0
                    : s.currentIndex / s.sessionQuestions.length,
              ),
              Expanded(
                child: _QuestionArea(state: s, notifier: n, l10n: l10n),
              ),
              _BottomNav(state: s, notifier: n, l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.notifier, required this.l10n});
  final ExamState state;
  final ExamNotifier notifier;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final attempt = state.activeAttempt;
    final remaining = attempt?.remainingSeconds ?? 0;
    final mins = remaining ~/ 60;
    final secs = remaining % 60;
    final timerStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final isUrgent = remaining <= 300; // < 5 min

    final total = state.sessionQuestions.length;
    final current = total == 0 ? 0 : state.currentIndex + 1;
    final answered = attempt?.answeredCount ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          // Timer badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isUrgent
                  ? Colors.red.withAlpha(30)
                  : Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isUrgent
                    ? Colors.red.withAlpha(120)
                    : Colors.white.withAlpha(25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 13,
                  color: isUrgent ? Colors.redAccent : Colors.white60,
                ),
                const SizedBox(width: 4),
                Text(
                  timerStr,
                  style: TextStyle(
                    color: isUrgent ? Colors.redAccent : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Answered count
          Text(
            l10n.examResumeStatus(answered, total, '').split('  ·  ').first,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const Spacer(),

          // Question counter
          Text(
            '$current / $total',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(width: 10),

          // Grid / overview button
          _IconBtn(
            icon: Icons.grid_view_outlined,
            onTap: () => _showQuestionGrid(context, state, notifier, l10n),
          ),
          const SizedBox(width: 6),

          // Pause button
          _IconBtn(
            icon: Icons.pause_circle_outline,
            onTap: () => _showPauseDialog(context, notifier, l10n),
          ),
        ],
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 3,
            backgroundColor: Colors.white12,
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
          ),
        ),
      );
}

// ── Question area ─────────────────────────────────────────────────────────────

class _QuestionArea extends StatelessWidget {
  const _QuestionArea({required this.state, required this.notifier, required this.l10n});
  final ExamState state;
  final ExamNotifier notifier;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final item = state.currentQuestion;
    if (item == null) {
      return Center(
        child: Text(l10n.noExamQuestionsAvailable,
            style: const TextStyle(color: Colors.white54)),
      );
    }

    final selectedAnswer = state.currentAnswer;
    final isFlagged = state.currentFlagged;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category + flag row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withAlpha(35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${item.category}${item.topic != null ? ' › ${item.topic}' : ''}',
                    style: const TextStyle(
                        color: Color(0xFFADA8FF), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  notifier.toggleFlag(item.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isFlagged
                        ? Colors.orange.withAlpha(40)
                        : Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFlagged
                          ? Colors.orange.withAlpha(120)
                          : Colors.white.withAlpha(25),
                    ),
                  ),
                  child: Icon(
                    isFlagged ? Icons.flag : Icons.flag_outlined,
                    color:
                        isFlagged ? Colors.orange : Colors.white54,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
          const SizedBox(height: 24),

          // Options
          ...List.generate(item.options.length, (i) {
            const optionLabels = ['A', 'B', 'C', 'D'];
            final label = i < optionLabels.length ? optionLabels[i] : '$i';
            final isSelected = selectedAnswer == i;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                notifier.selectAnswer(item.id, i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6C63FF).withAlpha(55)
                      : Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withAlpha(25),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withAlpha(18),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected
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
                          color: isSelected
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.state, required this.notifier, required this.l10n});
  final ExamState state;
  final ExamNotifier notifier;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final total = state.sessionQuestions.length;
    final isFirst = state.currentIndex == 0;
    final isLast = state.currentIndex == total - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Row(
        children: [
          // Prev
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white60,
              side: BorderSide(color: Colors.white.withAlpha(30)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: isFirst ? null : notifier.previous,
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            label: Text(l10n.prev),
          ),
          const Spacer(),

          // Submit button (always visible)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent.withAlpha(200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            onPressed: () => _showFinishDialog(context, state, notifier, l10n),
            child: Text(l10n.submit,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const Spacer(),

          // Next
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: isLast
                ? () => _showFinishDialog(context, state, notifier, l10n)
                : notifier.next,
            icon: isLast
                ? const Icon(Icons.done_all, size: 16)
                : const Icon(Icons.arrow_forward_ios, size: 14),
            label: Text(isLast ? l10n.finish : l10n.next),
          ),
        ],
      ),
    );
  }
}

// ── Icon button helper ────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white60, size: 18),
        ),
      );
}

// ── Question grid sheet ───────────────────────────────────────────────────────

void _showQuestionGrid(
    BuildContext context, ExamState state, ExamNotifier notifier, AppLocalizations l10n) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0F0D1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _QuestionGridSheet(state: state, l10n: l10n, onSelect: (i) {
          notifier.goToQuestion(i);
          Navigator.pop(context);
        }),
  );
}

class _QuestionGridSheet extends StatelessWidget {
  const _QuestionGridSheet(
      {required this.state, required this.l10n, required this.onSelect});
  final ExamState state;
  final AppLocalizations l10n;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    final attempt = state.activeAttempt;
    final questions = state.sessionQuestions;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.questionOverview,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Legend(color: const Color(0xFF6C63FF), label: l10n.answered),
                const SizedBox(width: 12),
                _Legend(color: Colors.orange, label: l10n.flagged),
                const SizedBox(width: 12),
                _Legend(color: Colors.white24, label: l10n.unanswered),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: questions.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, i) {
                  final qId = questions[i].id;
                  final isAnswered =
                      attempt?.answers.containsKey(qId) ?? false;
                  final isFlagged =
                      attempt?.flaggedIds.contains(qId) ?? false;
                  final isCurrent = i == state.currentIndex;

                  Color bg = Colors.white.withAlpha(18);
                  Color textColor = Colors.white54;
                  if (isFlagged) {
                    bg = Colors.orange.withAlpha(50);
                    textColor = Colors.orange;
                  } else if (isAnswered) {
                    bg = const Color(0xFF6C63FF).withAlpha(60);
                    textColor = Colors.white;
                  }

                  return GestureDetector(
                    onTap: () => onSelect(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                        border: isCurrent
                            ? Border.all(
                                color: Colors.white, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      );
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

void _showPauseDialog(BuildContext context, ExamNotifier notifier, AppLocalizations l10n) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1730),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.pauseExam,
          style: const TextStyle(color: Colors.white, fontSize: 17)),
      content: Text(
        l10n.pauseExamHelp,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.keepGoing,
              style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange),
          onPressed: () {
            Navigator.pop(ctx);
            notifier.pause();
          },
          child: Text(l10n.pause),
        ),
      ],
    ),
  );
}

void _showFinishDialog(
    BuildContext context, ExamState state, ExamNotifier notifier, AppLocalizations l10n) {
  final attempt = state.activeAttempt;
  final unanswered = attempt?.unansweredCount ?? 0;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1730),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.submitExam,
          style: const TextStyle(color: Colors.white, fontSize: 17)),
      content: Text(
        unanswered > 0
            ? l10n.submitExamHelp(unanswered)
            : l10n.submitExamAllAnswered,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancelLabel,
              style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF)),
          onPressed: () {
            Navigator.pop(ctx);
            notifier.finish();
          },
          child: Text(l10n.submit),
        ),
      ],
    ),
  );
}
