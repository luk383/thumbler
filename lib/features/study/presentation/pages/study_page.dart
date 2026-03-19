import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/settings/app_settings.dart';
import '../../../growth/streak/streak_notifier.dart';
import '../controllers/study_controller.dart';
import '../pages/study_launcher_page.dart';
import '../../domain/study_item.dart';

// ============================================================================
// Root page
// ============================================================================

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key, this.launchRequest});

  final StudyExternalSessionRequest? launchRequest;

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
  String? _appliedRequestKey;

  @override
  void initState() {
    super.initState();
    _applyLaunchRequestIfNeeded();
  }

  @override
  void didUpdateWidget(covariant StudyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyLaunchRequestIfNeeded();
  }

  void _applyLaunchRequestIfNeeded() {
    final request = widget.launchRequest;
    if (request == null) return;
    final key = [
      request.category,
      request.topic,
      request.mode.name,
      request.source,
      request.autostart,
      request.sessionLength,
      request.lastExamAttemptId,
      request.questionIds?.join('|'),
    ].join('::');
    if (key == _appliedRequestKey) return;
    _appliedRequestKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(studyProvider.notifier).applyExternalRequest(request);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(studyProvider);
    if (s.isStudying) return const _SessionPage();
    return const StudyLauncherPage();
  }
}

// ============================================================================
// A) Setup page
// ============================================================================
// B) Session page (router between SRS and Speed)
// ============================================================================

class _SessionPage extends ConsumerWidget {
  const _SessionPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studyProvider);
    final streak = ref.watch(streakProvider);
    if (s.selectedMode == StudyMode.speed) {
      return _SpeedSession(studyState: s);
    }
    return _SrsSession(studyState: s, streak: streak);
  }
}

// ============================================================================
// C) SRS session
// ============================================================================

class _SrsSession extends ConsumerWidget {
  const _SrsSession({required this.studyState, required this.streak});
  final StudyState studyState;
  final StreakState streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(studyProvider.notifier);
    void closeSession() {
      n.stopSession();
      if (studyState.startedFromExamBridge) {
        context.go('/exam');
      }
    }

    return PopScope(
      canPop: !studyState.startedFromExamBridge,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && studyState.startedFromExamBridge) {
          closeSession();
        }
      },
      child: Scaffold(
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
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!studyState.sessionComplete)
                  Text(
                    '${studyState.currentIndex + 1}/${studyState.sessionQueue.length}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withAlpha(12)),
                  ),
                  child: Text(
                    streak.completedToday
                        ? '🔥 ${streak.currentStreak}'
                        : '🔥 ${streak.currentStreak} • ${streak.answeredToday}/3',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (studyState.lastRatedSnapshot != null && !studyState.sessionComplete)
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      n.undoLastRating();
                    },
                    icon: const Icon(Icons.undo_rounded, color: Colors.white54, size: 20),
                    tooltip: 'Annulla ultima valutazione',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(10),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                const SizedBox(width: 4),
                _CloseBtn(onTap: closeSession),
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
            ? _SrsComplete(
                state: studyState,
                onRestart: n.startSession,
                onRetryWrong: studyState.wrongItemIds.isNotEmpty
                    ? n.retryWrongItems
                    : null,
                onExit: closeSession,
              )
            : () {
                final item = studyState.currentItem;
                if (item == null) return const SizedBox();
                final fontScale = ref.watch(
                  appSettingsProvider.select((s) => s.cardFontScale),
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: _SrsCard(
                    key: ValueKey(studyState.generation),
                    item: item,
                    fontScale: fontScale,
                    onRate: (rating) => n.rate(item.id, rating: rating),
                  ),
                );
              }(),
      ),
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
    final elapsed = DateTime.now().difference(_questionStart!).inMilliseconds;
    setState(() {
      _answered = true;
      _selectedIndex = null;
    });
    _scheduleAutoNext(
      widget.studyState.currentItem!.id,
      correct: false,
      timeMs: elapsed,
      timedOut: true,
    );
  }

  void _onTapOption(int index) {
    if (_answered) return;
    _timer?.cancel();
    final item = widget.studyState.currentItem!;
    final correct = index == item.correctAnswerIndex;
    final elapsed = DateTime.now().difference(_questionStart!).inMilliseconds;
    HapticFeedback.mediumImpact();
    setState(() {
      _answered = true;
      _selectedIndex = index;
    });
    _scheduleAutoNext(
      item.id,
      correct: correct,
      timeMs: elapsed,
      timedOut: false,
    );
  }

  void _scheduleAutoNext(
    String id, {
    required bool correct,
    required int timeMs,
    required bool timedOut,
  }) {
    // Auto-advance removed to allow reading the answer.
    // The state now needs a manual trigger or we use a very long delay as a fallback.
    // But better to add a "Next" button in the UI when answered.
  }

  void _onNextManual() {
    if (!_answered) return;
    final item = widget.studyState.currentItem!;
    final correct = _selectedIndex == item.correctAnswerIndex;
    final elapsed = _questionStart != null 
        ? DateTime.now().difference(_questionStart!).inMilliseconds 
        : 0;
    
    ref.read(studyProvider.notifier).recordSpeedAnswer(
          item.id,
          correct: correct,
          timeMs: elapsed,
          timedOut: _selectedIndex == null,
        );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.studyState;
    void closeSession() {
      ref.read(studyProvider.notifier).stopSession();
      if (s.startedFromExamBridge) {
        context.go('/exam');
      }
    }

    if (s.sessionComplete) {
      return _SpeedResults(
        state: s,
        onRetryWrong: s.wrongItemIds.isNotEmpty
            ? () => ref
                  .read(studyProvider.notifier)
                  .startSession(retryIds: s.wrongItemIds)
            : null,
        onExit: closeSession,
      );
    }

    final item = s.currentItem;
    if (item == null) return const SizedBox();

    final progress = s.sessionQueue.isEmpty
        ? 0.0
        : s.answeredInSession / s.sessionQueue.length;
    final timerFraction = _remaining / s.timerSeconds;

    return PopScope(
      canPop: !s.startedFromExamBridge,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && s.startedFromExamBridge) {
          closeSession();
        }
      },
      child: Scaffold(
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
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${s.speedCorrect} ✓  ${s.speedWrong} ✗',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${s.answeredInSession + 1}/${s.sessionQueue.length}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CloseBtn(onTap: closeSession),
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
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withAlpha(38),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              color: Color(0xFFADA8FF),
                              fontSize: 11,
                            ),
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
                              horizontal: 16,
                              vertical: 14,
                            ),
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

                      // Timeout or Next button
                      if (_answered) ...[
                        const SizedBox(height: 20),
                        if (_selectedIndex == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              '⏱  Tempo scaduto!',
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onNextManual,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Next Question'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Speed results screen
// ============================================================================

class _SpeedResults extends StatefulWidget {
  const _SpeedResults({
    required this.state,
    required this.onRetryWrong,
    required this.onExit,
  });

  final StudyState state;
  final VoidCallback? onRetryWrong;
  final VoidCallback onExit;

  @override
  State<_SpeedResults> createState() => _SpeedResultsState();
}

class _SpeedResultsState extends State<_SpeedResults> {
  bool _showWrong = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final avgSec = (s.speedAvgMs / 1000).toStringAsFixed(1);
    final wrongItems = s.items
        .where((i) => s.wrongItemIds.contains(i.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trophy or stats icon
              Text(
                s.speedCorrect == s.sessionQueue.length ? '🏆' : '📊',
                style: const TextStyle(fontSize: 52),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Speed Drill completato!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(
                    label: 'Correct',
                    value: '${s.speedCorrect}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Wrong',
                    value: '${s.speedWrong}',
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Accuracy',
                    value: '${s.speedAccuracyPct}%',
                    color: _accuracyColor(s.speedAccuracyPct),
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Avg',
                    value: '${avgSec}s',
                    color: Colors.white60,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Collapsible wrong-items list
              if (wrongItems.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => setState(() => _showWrong = !_showWrong),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withAlpha(18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${wrongItems.length} wrong answer${wrongItems.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _showWrong ? Icons.expand_less : Icons.expand_more,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showWrong) ...[
                  const SizedBox(height: 8),
                  ...wrongItems.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withAlpha(18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.promptText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Correct: ${item.correctAnswer}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Retry wrong button
              if (widget.onRetryWrong != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withAlpha(200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: widget.onRetryWrong,
                    icon: const Icon(Icons.replay),
                    label: Text('Retry wrong (${s.wrongItemIds.length})'),
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
                  onPressed: widget.onExit,
                  child: const Text('Torna al setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accuracyColor(int pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.redAccent;
  }
}

// ============================================================================
// SRS session: card widget
// ============================================================================

class _SrsCard extends ConsumerStatefulWidget {
  const _SrsCard({
    super.key,
    required this.item,
    required this.onRate,
    this.fontScale = 1.0,
  });
  final StudyItem item;
  final void Function(SrsRating rating) onRate;
  final double fontScale;

  @override
  ConsumerState<_SrsCard> createState() => _SrsCardState();
}

class _SrsCardState extends ConsumerState<_SrsCard> {
  bool _revealed = false;
  int? _selectedIndex;
  double _dragDx = 0;

  static const _swipeThreshold = 80.0;

  void _onDragUpdate(DragUpdateDetails d) {
    if (_selectedIndex == null) return;
    setState(() => _dragDx += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails _) {
    if (_selectedIndex == null) {
      setState(() => _dragDx = 0);
      return;
    }
    if (_dragDx > _swipeThreshold) {
      widget.onRate(SrsRating.good);
    } else if (_dragDx < -_swipeThreshold) {
      widget.onRate(SrsRating.again);
    } else {
      setState(() => _dragDx = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isAnswered = _selectedIndex != null;

    // Swipe overlay color
    Color? swipeColor;
    double swipeOpacity = 0;
    if (isAnswered && _dragDx.abs() > 20) {
      swipeOpacity = (_dragDx.abs() / _swipeThreshold).clamp(0.0, 0.8);
      swipeColor = _dragDx > 0 ? Colors.green : Colors.red;
    }

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => setState(() => _dragDx = 0),
      child: Transform.translate(
        offset: Offset(_dragDx * 0.25, 0),
        child: Stack(
          children: [
            Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0D1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: swipeColor?.withAlpha((swipeOpacity * 200).toInt()) ??
              Colors.white.withAlpha(18),
          width: swipeColor != null ? 2 : 1,
        ),
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
                  _RatingBadge(good: item.goodCount, again: item.againCount),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(studyProvider.notifier).toggleStar(item.id);
                  },
                  child: Icon(
                    item.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: item.isStarred ? Colors.amber : Colors.white38,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // Prompt — cloze shows blanks; MCQ shows raw text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: item.contentType == ContentType.clozeCard
                ? _ClozePromptText(
                    promptText: item.promptText,
                    revealed: _revealed,
                    fontScale: widget.fontScale,
                  )
                : Text(
                    item.promptText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20 * widget.fontScale,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),

          // Cloze: "Mostra risposta" button (no reveal step needed for MCQ)
          if (item.contentType == ContentType.clozeCard && !_revealed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _revealed = true;
                    _selectedIndex = 0; // marks isAnswered = true
                  });
                },
                child: const Text('Mostra risposta'),
              ),
            ),

          // MCQ: reveal button
          if (item.contentType != ContentType.clozeCard && !_revealed)
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
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Options (MCQ only)
            if (item.contentType != ContentType.clozeCard)
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
                          horizontal: 14,
                          vertical: 11,
                        ),
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
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // Feedback + Again / Hard / Good / Easy (FSRS grades 1–4)
            if (isAnswered)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  children: [
                    if (item.contentType != ContentType.clozeCard)
                      _FeedbackBanner(
                        correct: _selectedIndex == item.correctAnswerIndex,
                        correctAnswer: item.correctAnswer,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              widget.onRate(SrsRating.again);
                            },
                            child: const Text(
                              'Again',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orangeAccent,
                              side: const BorderSide(
                                color: Colors.orangeAccent,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onRate(SrsRating.hard);
                            },
                            child: const Text(
                              'Hard',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onRate(SrsRating.good);
                            },
                            child: const Text(
                              'Good',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onRate(SrsRating.easy);
                            },
                            child: const Text(
                              'Easy',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _UserNoteSection(item: item),
                  ],
                ),
              ),
          ],
        ],
      ),
          ),
            // Swipe direction overlay
            if (swipeColor != null && swipeOpacity > 0.1)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: swipeColor.withAlpha((swipeOpacity * 60).toInt()),
                    ),
                    child: Align(
                      alignment: _dragDx > 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(
                          _dragDx > 0
                              ? Icons.thumb_up_outlined
                              : Icons.replay_outlined,
                          color: swipeColor.withAlpha((swipeOpacity * 220).toInt()),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── User Note Section ─────────────────────────────────────────────────────────

class _UserNoteSection extends ConsumerStatefulWidget {
  const _UserNoteSection({required this.item});
  final StudyItem item;

  @override
  ConsumerState<_UserNoteSection> createState() => _UserNoteSectionState();
}

class _UserNoteSectionState extends ConsumerState<_UserNoteSection> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.userNote ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(studyProvider.notifier).updateUserNote(widget.item.id, _ctrl.text);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = widget.item.userNote?.isNotEmpty == true;

    if (_editing) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    color: Colors.amber, size: 14),
                const SizedBox(width: 6),
                const Text('Nota personale',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _editing = false),
                  child: const Icon(Icons.close, color: Colors.white38, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Aggiungi un appunto su questa carta…',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Salva nota', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }

    if (hasNote) {
      return GestureDetector(
        onTap: () {
          _ctrl.text = widget.item.userNote ?? '';
          setState(() => _editing = true);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withAlpha(40)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sticky_note_2_outlined,
                  color: Colors.amber, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.item.userNote!,
                  style: const TextStyle(
                      color: Colors.amber, fontSize: 13, height: 1.4),
                ),
              ),
              const Icon(Icons.edit_outlined, color: Colors.amber, size: 14),
            ],
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: () => setState(() => _editing = true),
      icon: const Icon(Icons.sticky_note_2_outlined, size: 14,
          color: Colors.white38),
      label: const Text('Aggiungi nota',
          style: TextStyle(color: Colors.white38, fontSize: 12)),
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
    );
  }
}

// ============================================================================
// SRS complete screen
// ============================================================================

class _SrsComplete extends StatefulWidget {
  const _SrsComplete({
    required this.state,
    required this.onRestart,
    required this.onExit,
    this.onRetryWrong,
  });
  final StudyState state;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final VoidCallback? onRetryWrong;

  @override
  State<_SrsComplete> createState() => _SrsCompleteState();
}

class _SrsCompleteState extends State<_SrsComplete>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final total = state.answeredInSession;
    final accuracy = total == 0 ? 0 : ((state.sessionCorrectCount / total) * 100).round();
    final wrong = state.wrongItemIds.length;
    final xpEarned = state.sessionCorrectCount * 3 + total;

    // Duration
    final start = state.sessionStartTime;
    final elapsed = start != null ? DateTime.now().difference(start) : Duration.zero;
    final mm = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    final emoji = accuracy >= 80 ? '🏆' : accuracy >= 50 ? '📊' : '💪';
    final message = accuracy >= 80
        ? 'Ottimo lavoro!'
        : accuracy >= 50
            ? 'Continua ad allenarci!'
            : 'Non mollare, ci si migliora!';

    final accColor = accuracy >= 80
        ? Colors.greenAccent
        : accuracy >= 50
            ? Colors.orangeAccent
            : Colors.redAccent;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(
              'Sessione completata!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Accuracy ring + key stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              child: Column(
                children: [
                  // Big accuracy circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: total == 0 ? 0 : accuracy / 100,
                          strokeWidth: 7,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(accColor),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '$accuracy%',
                            style: TextStyle(
                              color: accColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'accuracy',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      _SrsStatTile(label: 'Carte', value: '$total'),
                      _SrsStatTile(label: 'Durata', value: '$mm:$ss'),
                      _SrsStatTile(
                        label: 'XP',
                        value: '+$xpEarned',
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // FSRS rating breakdown bar
                  _RatingBreakdownBar(
                    again: state.sessionAgainCount,
                    hard: state.sessionHardCount,
                    good: state.sessionGoodCount,
                    easy: state.sessionEasyCount,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Retry wrong (primary if there are wrongs)
            if (widget.onRetryWrong != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: widget.onRetryWrong,
                  icon: const Icon(Icons.replay_outlined),
                  label: Text('Ripassa $wrong errate'),
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onRestart,
                icon: const Icon(Icons.replay),
                label: const Text('Nuova sessione'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: widget.onExit,
              child: const Text(
                'Torna al setup',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rating breakdown bar ──────────────────────────────────────────────────────

class _RatingBreakdownBar extends StatelessWidget {
  const _RatingBreakdownBar({
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
  });
  final int again;
  final int hard;
  final int good;
  final int easy;

  @override
  Widget build(BuildContext context) {
    final total = again + hard + good + easy;
    if (total == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating distribution',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              if (again > 0) Expanded(flex: again, child: Container(height: 8, color: Colors.redAccent)),
              if (hard > 0) Expanded(flex: hard, child: Container(height: 8, color: Colors.orangeAccent)),
              if (good > 0) Expanded(flex: good, child: Container(height: 8, color: Colors.lightGreenAccent)),
              if (easy > 0) Expanded(flex: easy, child: Container(height: 8, color: Colors.greenAccent)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (again > 0) _RatingLabel(label: 'Again', count: again, color: Colors.redAccent),
            if (hard > 0) _RatingLabel(label: 'Hard', count: hard, color: Colors.orangeAccent),
            if (good > 0) _RatingLabel(label: 'Good', count: good, color: Colors.lightGreenAccent),
            if (easy > 0) _RatingLabel(label: 'Easy', count: easy, color: Colors.greenAccent),
          ],
        ),
      ],
    );
  }
}

class _RatingLabel extends StatelessWidget {
  const _RatingLabel({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          '$label $count',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SrsStatTile extends StatelessWidget {
  const _SrsStatTile({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(18)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Session helper widgets
// ============================================================================

class _TimerBar extends StatelessWidget {
  const _TimerBar({
    required this.fraction,
    required this.remaining,
    required this.urgent,
  });
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
              fontWeight: FontWeight.bold,
            ),
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Cloze prompt renderer ─────────────────────────────────────────────────────

class _ClozePromptText extends StatelessWidget {
  const _ClozePromptText({
    required this.promptText,
    required this.revealed,
    this.fontScale = 1.0,
  });
  final String promptText;
  final bool revealed;
  final double fontScale;

  static final _pattern = RegExp(r'\{\{([^}]+)\}\}');

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    int last = 0;

    for (final match in _pattern.allMatches(promptText)) {
      if (match.start > last) {
        spans.add(TextSpan(text: promptText.substring(last, match.start)));
      }
      final answer = match.group(1)!;
      if (revealed) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF69F0AE).withAlpha(40),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF69F0AE).withAlpha(120)),
              ),
              child: Text(
                answer,
                style: TextStyle(
                  color: const Color(0xFF69F0AE),
                  fontSize: 20 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white38,
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(
                '　' * answer.length.clamp(2, 8),
                style: TextStyle(fontSize: 20 * fontScale),
              ),
            ),
          ),
        );
      }
      last = match.end;
    }
    if (last < promptText.length) {
      spans.add(TextSpan(text: promptText.substring(last)));
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20 * fontScale,
          fontWeight: FontWeight.bold,
          height: 1.45,
        ),
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ── Feedback banner ────────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.correct, required this.correctAnswer});
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
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              correct ? 'Correct!' : 'Corretto: $correctAnswer',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
          Text(
            '$good',
            style: const TextStyle(color: Colors.green, fontSize: 11),
          ),
          const SizedBox(width: 6),
        ],
        if (again > 0) ...[
          const Icon(Icons.replay, color: Colors.redAccent, size: 12),
          const SizedBox(width: 2),
          Text(
            '$again',
            style: const TextStyle(color: Colors.redAccent, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

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
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
