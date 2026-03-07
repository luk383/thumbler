import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/ui/app_surfaces.dart';
import '../../domain/exam_attempt.dart';
import '../../domain/exam_result.dart';
import '../../../study/presentation/controllers/deck_library_controller.dart';
import '../controllers/exam_controller.dart';

class ExamHomePage extends ConsumerWidget {
  const ExamHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(examProvider);
    final n = ref.read(examProvider.notifier);
    final activeDeck = ref.watch(activeDeckMetaProvider);
    final countOptions = _questionCountOptions(s.availableQuestions.length);
    final deckResults = activeDeck == null
        ? s.results
        : s.results.where((result) => result.deckId == activeDeck.id).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
          children: [
            // ── Header ──────────────────────────────────────────────────
            const SizedBox(height: 20),
            AppPageIntro(
              title: l10n.examTitle,
              subtitle: activeDeck == null
                  ? l10n.examQuestionsAvailable(s.availableQuestions.length)
                  : l10n.examQuestionsReady(
                      activeDeck.title,
                      s.availableQuestions.length,
                    ),
              trailing: activeDeck == null
                  ? null
                  : AppStatusBadge(
                      label: l10n.deckActive,
                      icon: Icons.layers_outlined,
                    ),
            ),
            const SizedBox(height: 24),

            // ── Resume banner ────────────────────────────────────────────
            if (s.hasIncompleteAttempt) ...[
              _ResumeBanner(attempt: s.activeAttempt!, onResume: n.resumeExam),
              const SizedBox(height: 20),
            ],

            // ── No questions ─────────────────────────────────────────────
            if (s.availableQuestions.isEmpty) ...[
              _NoQuestionsCard(),
              const SizedBox(height: 28),
            ],

            // ── Question count selector ──────────────────────────────────
            AppGlassCard(
              padding: const EdgeInsets.all(18),
              tint: const Color(0xFF6C63FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(l10n.questionsLabel),
                  _CountChips(
                    options: countOptions,
                    selected: s.effectiveQuestionCount,
                    available: s.availableQuestions.length,
                    onSelect: n.setQuestionCount,
                  ),
                  const SizedBox(height: 12),
                  if (s.availableQuestions.isNotEmpty)
                    _InfoPill(l10n.timedRunLabel(s.effectiveQuestionCount)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        disabledBackgroundColor: const Color(
                          0xFF6C63FF,
                        ).withAlpha(50),
                      ),
                      onPressed: s.availableQuestions.isEmpty
                          ? null
                          : () => n.startExam(s.selectedCount),
                      icon: const Icon(Icons.assignment_outlined, size: 20),
                      label: Text(
                        s.availableQuestions.isEmpty
                            ? l10n.noExamQuestionsAvailable
                            : l10n.startExamLabel(s.effectiveQuestionCount),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (deckResults.isEmpty && s.availableQuestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _InfoPill(l10n.noExamHistoryYet),
            ],
            const SizedBox(height: 12),

            // ── History ──────────────────────────────────────────────────
            if (deckResults.isNotEmpty) ...[
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(child: _SectionLabel(l10n.examHistoryTitle)),
                  TextButton(
                    onPressed: () => context.push('/exam/history'),
                    child: Text(l10n.viewAll),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...deckResults
                  .take(5)
                  .map(
                    (result) => _HistoryCard(
                      result: result,
                      onTap: () =>
                          context.push('/exam/history/detail', extra: result),
                    ),
                  ),
            ],

            const SizedBox(height: 20),
            if (s.availableQuestions.isNotEmpty &&
                s.availableQuestions.length < 30)
              Center(
                child: Text(
                  l10n.shortExamPoolNote,
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

List<int> _questionCountOptions(int availableQuestions) {
  const defaults = [30, 60, 90];
  final supported = defaults
      .where((count) => count <= availableQuestions)
      .toList(growable: false);
  if (supported.isNotEmpty) return supported;
  if (availableQuestions <= 0) return defaults;
  return [availableQuestions];
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
  );
}

// ── Resume banner ─────────────────────────────────────────────────────────────

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.attempt, required this.onResume});
  final ExamAttempt attempt;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mins = attempt.remainingSeconds ~/ 60;
    final secs = attempt.remainingSeconds % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final progress = attempt.answeredCount / attempt.totalQuestions;

    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      tint: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppSurfaceIcon(
                icon: Icons.timer_outlined,
                tint: Colors.orange,
                size: 34,
                iconSize: 16,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.examInProgress,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.examResumeStatus(
                        attempt.answeredCount,
                        attempt.totalQuestions,
                        timeStr,
                      ),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                onPressed: onResume,
                child: Text(l10n.resume),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── No questions card ─────────────────────────────────────────────────────────

class _NoQuestionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppGlassCard(
      padding: const EdgeInsets.all(20),
      tint: Colors.white,
      child: Column(
        children: [
          const AppSurfaceIcon(
            icon: Icons.assignment_outlined,
            tint: Color(0xFFADA8FF),
            size: 52,
            iconSize: 24,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noExamQuestionsImported,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.noExamQuestionsImportedHelp,
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Count chips ───────────────────────────────────────────────────────────────

class _CountChips extends StatelessWidget {
  const _CountChips({
    required this.options,
    required this.selected,
    required this.available,
    required this.onSelect,
  });

  final List<int> options;
  final int selected;
  final int available;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: options.map((n) {
        final isSelected = n == selected;
        final insufficient = n > available && available > 0;
        return GestureDetector(
          onTap: () => onSelect(n),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
            child: Column(
              children: [
                Text(
                  '$n',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (insufficient)
                  Text(
                    l10n.onlyAvailableCount(available),
                    style: const TextStyle(color: Colors.orange, fontSize: 9),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Info pill ─────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(50)),
      ),
      child: Text(
        text,
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

String _formatDate(DateTime d) {
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
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${months[d.month - 1]}, $h:$m';
}

// ── History card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.result, required this.onTap});
  final ExamResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pct = result.percentageScore;
    final passed = pct >= 75;
    final color = passed ? Colors.green : Colors.redAccent;

    return GestureDetector(
      onTap: onTap,
      child: AppGlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        tint: color,
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(100), width: 2),
              ),
              child: Center(
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.historyCardTop(
                      result.correctAnswers,
                      result.totalQuestions,
                      _formatDate(result.completedAt),
                    ),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.historyCardBottom(
                      result.wrongAnswers,
                      result.weakestDomain ?? l10n.noWeakestDomain,
                    ),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                passed ? l10n.passLabel : l10n.failLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
