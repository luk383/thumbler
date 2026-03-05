import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/study_controller.dart';
import '../../domain/study_item.dart';

// ============================================================================
// Root page
// ============================================================================

class StudyPage extends ConsumerWidget {
  const StudyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studyProvider);
    if (s.isStudying) return const _SessionPage();
    return const _SetupPage();
  }
}

// ============================================================================
// A) Setup page
// ============================================================================

class _SetupPage extends ConsumerWidget {
  const _SetupPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studyProvider);
    final n = ref.read(studyProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Study',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: s.items.isEmpty
          ? _EmptyDeck()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Topic ──────────────────────────────────────────────
                  _SectionLabel('Topic'),
                  const SizedBox(height: 10),
                  _ChipRow(
                    chips: ['All', ...s.categories],
                    selected: s.selectedCategory ?? 'All',
                    onSelect: (v) => n.setCategory(v == 'All' ? null : v),
                  ),
                  const SizedBox(height: 22),

                  // ── Mode ───────────────────────────────────────────────
                  _SectionLabel('Mode'),
                  const SizedBox(height: 10),
                  _ModeSelector(
                    selected: s.selectedMode,
                    onSelect: n.setMode,
                  ),
                  const SizedBox(height: 22),

                  // ── Session length ─────────────────────────────────────
                  _SectionLabel('Questions'),
                  const SizedBox(height: 10),
                  _ChipRow(
                    chips: ['5', '10', '20'],
                    selected: '${s.sessionLength}',
                    onSelect: (v) => n.setSessionLength(int.parse(v)),
                  ),
                  const SizedBox(height: 22),

                  // ── Timer (Speed only) ────────────────────────────────
                  if (s.selectedMode == StudyMode.speed) ...[
                    _SectionLabel('Timer per question'),
                    const SizedBox(height: 10),
                    _ChipRow(
                      chips: ['5s', '8s', '12s'],
                      selected: '${s.timerSeconds}s',
                      onSelect: (v) => n.setTimerSeconds(
                          int.parse(v.replaceAll('s', ''))),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // ── Preview + CTA ──────────────────────────────────────
                  if (s.availableCount > 0) ...[
                    _PreviewCard(state: s),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: n.startSession,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('START SESSION'),
                      ),
                    ),
                  ] else
                    _EmptyFilterResult(),
                ],
              ),
            ),
    );
  }
}

// ============================================================================
// B) Session page (router between SRS and Speed)
// ============================================================================

class _SessionPage extends ConsumerWidget {
  const _SessionPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studyProvider);
    if (s.selectedMode == StudyMode.speed) {
      return _SpeedSession(studyState: s);
    }
    return _SrsSession(studyState: s);
  }
}

// ============================================================================
// C) SRS session
// ============================================================================

class _SrsSession extends ConsumerWidget {
  const _SrsSession({required this.studyState});
  final StudyState studyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(studyProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  studyState.selectedCategory ?? 'All topics',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!studyState.sessionComplete)
                Text(
                  '${studyState.currentIndex + 1}/${studyState.sessionQueue.length}',
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              const SizedBox(width: 12),
              _CloseBtn(onTap: n.stopSession),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _ProgressBar(
            value: studyState.sessionQueue.isEmpty
                ? 0
                : studyState.answeredInSession /
                    studyState.sessionQueue.length,
          ),
        ),
        elevation: 0,
      ),
      body: studyState.sessionComplete
          ? _SrsComplete(state: studyState, onRestart: n.startSession, onExit: n.stopSession)
          : () {
              final item = studyState.currentItem;
              if (item == null) return const SizedBox();
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: _SrsCard(
                  key: ValueKey(studyState.generation),
                  item: item,
                  onRate: (again) => n.rate(item.id, again: again),
                ),
              );
            }(),
    );
  }
}

// ============================================================================
// D) Speed Drill session
// ============================================================================

class _SpeedSession extends ConsumerStatefulWidget {
  const _SpeedSession({required this.studyState});
  final StudyState studyState;

  @override
  ConsumerState<_SpeedSession> createState() => _SpeedSessionState();
}

class _SpeedSessionState extends ConsumerState<_SpeedSession>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late int _remaining;
  DateTime? _questionStart;
  bool _answered = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(_SpeedSession old) {
    super.didUpdateWidget(old);
    // New card generation → reset
    if (old.studyState.generation != widget.studyState.generation) {
      _resetCard();
    }
  }

  void _startTimer() {
    _remaining = widget.studyState.timerSeconds;
    _questionStart = DateTime.now();
    _answered = false;
    _selectedIndex = null;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) _onTimeout();
    });
  }

  void _resetCard() {
    _timer?.cancel();
    _startTimer();
  }

  void _onTimeout() {
    if (_answered) return;
    _timer?.cancel();
    final elapsed = DateTime.now()
        .difference(_questionStart!)
        .inMilliseconds;
    setState(() {
      _answered = true;
      _selectedIndex = null;
    });
    _scheduleAutoNext(
        widget.studyState.currentItem!.id,
        correct: false,
        timeMs: elapsed,
        timedOut: true);
  }

  void _onTapOption(int index) {
    if (_answered) return;
    _timer?.cancel();
    final item = widget.studyState.currentItem!;
    final correct = index == item.correctAnswerIndex;
    final elapsed =
        DateTime.now().difference(_questionStart!).inMilliseconds;
    HapticFeedback.mediumImpact();
    setState(() {
      _answered = true;
      _selectedIndex = index;
    });
    _scheduleAutoNext(item.id,
        correct: correct, timeMs: elapsed, timedOut: false);
  }

  void _scheduleAutoNext(String id,
      {required bool correct,
      required int timeMs,
      required bool timedOut}) {
    final delay = 600 + _rng.nextInt(301); // 600–900ms
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      ref.read(studyProvider.notifier).recordSpeedAnswer(
            id,
            correct: correct,
            timeMs: timeMs,
            timedOut: timedOut,
          );
    });
  }

  static final _rng = Random();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.studyState;
    if (s.sessionComplete) {
      return _SpeedResults(
        state: s,
        onRetryWrong: s.wrongItemIds.isNotEmpty
            ? () => ref.read(studyProvider.notifier).startSession(
                  retryIds: s.wrongItemIds,
                )
            : null,
        onExit: () => ref.read(studyProvider.notifier).stopSession(),
      );
    }

    final item = s.currentItem;
    if (item == null) return const SizedBox();

    final progress =
        s.sessionQueue.isEmpty ? 0.0 : s.answeredInSession / s.sessionQueue.length;
    final timerFraction = _remaining / s.timerSeconds;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${s.speedCorrect} ✓  ${s.speedWrong} ✗',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${s.answeredInSession + 1}/${s.sessionQueue.length}',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  _CloseBtn(
                    onTap: () =>
                        ref.read(studyProvider.notifier).stopSession(),
                  ),
                ],
              ),
            ),

            // ── Session progress bar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _ProgressBar(value: progress),
            ),

            // ── Timer arc / countdown ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _TimerBar(
                fraction: timerFraction.clamp(0.0, 1.0),
                remaining: _remaining,
                urgent: _remaining <= 3,
              ),
            ),

            // ── Question ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    // Category chip
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withAlpha(38),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                              color: Color(0xFFADA8FF), fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      item.promptText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Options
                    ...List.generate(item.options.length, (i) {
                      final isCorrect = i == item.correctAnswerIndex;
                      final isSelected = _selectedIndex == i;

                      Color bg = Colors.white.withAlpha(13);
                      Color border = Colors.white24;
                      Color textColor = Colors.white70;

                      if (_answered) {
                        if (isCorrect) {
                          bg = Colors.green.withAlpha(38);
                          border = Colors.green;
                          textColor = Colors.green;
                        } else if (isSelected) {
                          bg = Colors.redAccent.withAlpha(38);
                          border = Colors.redAccent;
                          textColor = Colors.redAccent;
                        }
                        // timed out: highlight correct only
                        if (_selectedIndex == null && isCorrect) {
                          bg = Colors.orange.withAlpha(38);
                          border = Colors.orange;
                          textColor = Colors.orange;
                        }
                      }

                      return GestureDetector(
                        onTap: () => _onTapOption(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          child: Text(
                            item.options[i],
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }),

                    // Timeout label
                    if (_answered && _selectedIndex == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '⏱  Tempo scaduto!',
                          style: TextStyle(
                              color: Colors.orange.shade300, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Speed results screen
// ============================================================================

class _SpeedResults extends StatelessWidget {
  const _SpeedResults({
    required this.state,
    required this.onRetryWrong,
    required this.onExit,
  });

  final StudyState state;
  final VoidCallback? onRetryWrong;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final avgSec = (state.speedAvgMs / 1000).toStringAsFixed(1);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.speedCorrect == state.sessionQueue.length
                      ? '🏆'
                      : '📊',
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Speed Drill completato!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                        label: 'Correct',
                        value: '${state.speedCorrect}',
                        color: Colors.green),
                    const SizedBox(width: 10),
                    _StatChip(
                        label: 'Wrong',
                        value: '${state.speedWrong}',
                        color: Colors.redAccent),
                    const SizedBox(width: 10),
                    _StatChip(
                        label: 'Avg time',
                        value: '${avgSec}s',
                        color: Colors.white60),
                  ],
                ),
                const SizedBox(height: 32),

                if (onRetryWrong != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withAlpha(200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onRetryWrong,
                      icon: const Icon(Icons.replay),
                      label: Text(
                          'Retry wrong (${state.wrongItemIds.length})'),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: BorderSide(color: Colors.white.withAlpha(40)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onExit,
                    child: const Text('Torna al setup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SRS session: card widget
// ============================================================================

class _SrsCard extends StatefulWidget {
  const _SrsCard({
    super.key,
    required this.item,
    required this.onRate,
  });
  final StudyItem item;
  final void Function(bool again) onRate;

  @override
  State<_SrsCard> createState() => _SrsCardState();
}

class _SrsCardState extends State<_SrsCard> {
  bool _revealed = false;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isAnswered = _selectedIndex != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0D1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _CategoryTag(label: item.category)),
                const SizedBox(width: 8),
                if (item.goodCount > 0 || item.againCount > 0)
                  _RatingBadge(
                      good: item.goodCount, again: item.againCount),
              ],
            ),
          ),

          // Prompt (hook / question)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Text(
              item.promptText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (!_revealed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: ElevatedButton(
                onPressed: () => setState(() => _revealed = true),
                child: const Text('Reveal'),
              ),
            ),

          if (_revealed) ...[
            // Explanation (optional)
            if (item.explanationText != null &&
                item.explanationText!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: Text(
                    item.explanationText!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Options
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                children: List.generate(item.options.length, (i) {
                  final isCorrect = i == item.correctAnswerIndex;
                  final isSelected = _selectedIndex == i;

                  Color bg = Colors.white.withAlpha(13);
                  Color border = Colors.white24;
                  Color textColor = Colors.white70;

                  if (isAnswered) {
                    if (isCorrect) {
                      bg = Colors.green.withAlpha(38);
                      border = Colors.green;
                      textColor = Colors.green;
                    } else if (isSelected) {
                      bg = Colors.redAccent.withAlpha(38);
                      border = Colors.redAccent;
                      textColor = Colors.redAccent;
                    }
                  }

                  return GestureDetector(
                    onTap: isAnswered
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            setState(() => _selectedIndex = i);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        item.options[i],
                        style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Feedback + Again / Good
            if (isAnswered)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  children: [
                    _FeedbackBanner(
                      correct: _selectedIndex == item.correctAnswerIndex,
                      correctAnswer: item.correctAnswer,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                  color: Colors.redAccent, width: 1.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => widget.onRate(true),
                            icon: const Icon(Icons.replay, size: 16),
                            label: const Text('Again'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => widget.onRate(false),
                            icon: const Icon(Icons.thumb_up, size: 16),
                            label: const Text('Got it'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// SRS complete screen
// ============================================================================

class _SrsComplete extends StatelessWidget {
  const _SrsComplete(
      {required this.state, required this.onRestart, required this.onExit});
  final StudyState state;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('Sessione completata!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '${state.answeredInSession} carte studiate',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay),
                label: const Text('Studia di nuovo'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onExit,
              child: const Text('Torna al setup',
                  style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Shared small widgets
// ============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );
}

class _ChipRow extends StatelessWidget {
  const _ChipRow(
      {required this.chips, required this.selected, required this.onSelect});
  final List<String> chips;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map((c) => _Chip(
                  label: c,
                  selected: c == selected,
                  onTap: () => onSelect(c),
                ))
            .toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF)
              : Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : Colors.white.withAlpha(30),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onSelect});
  final StudyMode selected;
  final void Function(StudyMode) onSelect;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StudyMode>(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white.withAlpha(12),
        foregroundColor: Colors.white60,
        selectedBackgroundColor: const Color(0xFF6C63FF),
        selectedForegroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withAlpha(30)),
      ),
      segments: StudyMode.values
          .map((m) => ButtonSegment<StudyMode>(
                value: m,
                label: Text(m.label, style: const TextStyle(fontSize: 13)),
                icon: Icon(m.icon, size: 16),
              ))
          .toList(),
      selected: {selected},
      onSelectionChanged: (modes) => onSelect(modes.first),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.state});
  final StudyState state;

  @override
  Widget build(BuildContext context) {
    final count =
        state.sessionLength.clamp(1, state.availableCount);
    final modeNote = state.selectedMode == StudyMode.speed
        ? '${state.timerSeconds}s per domanda'
        : 'priorità: più difficili prima';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(60)),
      ),
      child: Row(
        children: [
          Text(
            state.selectedMode == StudyMode.speed ? '⚡' : '🧠',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count available • ~${state.estimatedMinutes} min',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(modeNote,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerBar extends StatelessWidget {
  const _TimerBar(
      {required this.fraction, required this.remaining, required this.urgent});
  final double fraction;
  final int remaining;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final color = urgent ? Colors.redAccent : const Color(0xFF6C63FF);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$remaining',
            style: TextStyle(
                color: urgent ? Colors.redAccent : Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
        value: value,
        minHeight: 3,
        backgroundColor: Colors.white12,
        valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
      );
}

class _CloseBtn extends StatelessWidget {
  const _CloseBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.close, color: Colors.white60, size: 18),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withAlpha(38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withAlpha(80)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Color(0xFFADA8FF),
            fontSize: 11,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner(
      {required this.correct, required this.correctAnswer});
  final bool correct;
  final String correctAnswer;

  @override
  Widget build(BuildContext context) {
    final color = correct ? Colors.green : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel,
              color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              correct ? 'Correct!' : 'Corretto: $correctAnswer',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.good, required this.again});
  final int good;
  final int again;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (good > 0) ...[
          const Icon(Icons.thumb_up, color: Colors.green, size: 12),
          const SizedBox(width: 2),
          Text('$good',
              style: const TextStyle(color: Colors.green, fontSize: 11)),
          const SizedBox(width: 6),
        ],
        if (again > 0) ...[
          const Icon(Icons.replay, color: Colors.redAccent, size: 12),
          const SizedBox(width: 2),
          Text('$again',
              style:
                  const TextStyle(color: Colors.redAccent, fontSize: 11)),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('📚', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text(
              'Il tuo mazzo è vuoto',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Tocca l\'icona 🎓 su qualsiasi carta del feed per aggiungerla qui.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilterResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: const Text(
        'Nessuna carta per questa selezione.',
        style: TextStyle(color: Colors.white54),
        textAlign: TextAlign.center,
      ),
    );
  }
}
