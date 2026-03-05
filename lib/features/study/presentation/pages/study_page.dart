import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feed/data/providers.dart';
import '../../../feed/domain/lesson.dart';
import '../../domain/study_item.dart';
import '../controllers/study_controller.dart';

// ============================================================================
// Root page — switches between Setup and Session view
// ============================================================================

class StudyPage extends ConsumerWidget {
  const StudyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studyProvider);

    if (s.isStudying) {
      return _SessionView(studyState: s);
    }
    return _SetupView(studyState: s);
  }
}

// ============================================================================
// A) Setup view
// ============================================================================

class _SetupView extends ConsumerWidget {
  const _SetupView({required this.studyState});

  final StudyState studyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCards = studyState.items.isNotEmpty;
    final cardCount = studyState.filtered.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Study Mode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: !hasCards
          ? _EmptyDeck()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Topic ──────────────────────────────────────────────
                  _SectionLabel('Argomento'),
                  const SizedBox(height: 10),
                  _CategoryChips(
                    categories: studyState.categories,
                    selected: studyState.selectedCategory,
                    onSelect: (cat) =>
                        ref.read(studyProvider.notifier).setCategory(cat),
                  ),
                  const SizedBox(height: 24),

                  // ── Mode ───────────────────────────────────────────────
                  _SectionLabel('Modalità'),
                  const SizedBox(height: 10),
                  _ModeSelector(
                    selected: studyState.selectedMode,
                    onSelect: (m) =>
                        ref.read(studyProvider.notifier).setMode(m),
                  ),
                  const SizedBox(height: 28),

                  // ── Preview + CTA ──────────────────────────────────────
                  if (cardCount > 0) ...[
                    _StatsPreview(
                      count: cardCount,
                      minutes: studyState.estimatedMinutes,
                      mode: studyState.selectedMode,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            ref.read(studyProvider.notifier).startSession(),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Study'),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: const Text(
                        'Nessuna carta per questa selezione.',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ============================================================================
// B) Session view
// ============================================================================

class _SessionView extends ConsumerWidget {
  const _SessionView({required this.studyState});

  final StudyState studyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      // ── Session header ────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Topic + mode badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studyState.selectedCategory ?? 'All',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      studyState.selectedMode.label,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Card counter
              if (!studyState.sessionComplete)
                Text(
                  '${studyState.currentIndex + 1} / '
                  '${studyState.sessionQueue.length}',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13),
                ),
              const SizedBox(width: 12),
              // Exit button
              GestureDetector(
                onTap: () =>
                    ref.read(studyProvider.notifier).stopSession(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white60, size: 18),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _SessionProgressBar(studyState: studyState),
        ),
        elevation: 0,
      ),
      body: studyState.sessionComplete
          ? _SessionComplete(
              answered: studyState.answeredInSession,
              onRestart: () =>
                  ref.read(studyProvider.notifier).startSession(),
              onExit: () =>
                  ref.read(studyProvider.notifier).stopSession(),
            )
          : lessonsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Errore: $e',
                    style: const TextStyle(color: Colors.white60)),
              ),
              data: (lessons) {
                final lessonMap = {for (final l in lessons) l.id: l};
                final item = studyState.currentItem;
                if (item == null) return const SizedBox();
                final lesson = lessonMap[item.lessonId];

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: lesson == null
                      ? _MissingLesson(
                          lessonId: item.lessonId,
                          onSkip: () =>
                              ref.read(studyProvider.notifier).nextCard(),
                        )
                      : _StudyCard(
                          key: ValueKey(studyState.generation),
                          lesson: lesson,
                          studyItem: item,
                          onRate: (again) => ref
                              .read(studyProvider.notifier)
                              .rate(item.lessonId, again: again),
                        ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// Setup sub-widgets
// ============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map(
            (cat) => _Chip(
              label: cat,
              selected: selected == cat,
              onTap: () => onSelect(cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
  const _ModeSelector(
      {required this.selected, required this.onSelect});

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
                label: Text(m.label,
                    style: const TextStyle(fontSize: 13)),
                icon: Icon(m.icon, size: 16),
              ))
          .toList(),
      selected: {selected},
      onSelectionChanged: (modes) => onSelect(modes.first),
    );
  }
}

class _StatsPreview extends StatelessWidget {
  const _StatsPreview({
    required this.count,
    required this.minutes,
    required this.mode,
  });

  final int count;
  final int minutes;
  final StudyMode mode;

  @override
  Widget build(BuildContext context) {
    final modeNote = switch (mode) {
      StudyMode.random => 'ordine casuale',
      StudyMode.weak => 'le più difficili prima',
      StudyMode.newOnly => 'solo carte nuove',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF6C63FF).withAlpha(60)),
      ),
      child: Row(
        children: [
          const Text('📊', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count carte · ~$minutes min',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                modeNote,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Session sub-widgets
// ============================================================================

class _SessionProgressBar extends StatelessWidget {
  const _SessionProgressBar({required this.studyState});

  final StudyState studyState;

  @override
  Widget build(BuildContext context) {
    final total = studyState.sessionQueue.length;
    final done = studyState.answeredInSession.clamp(0, total);
    final progress = total == 0 ? 0.0 : done / total;

    return LinearProgressIndicator(
      value: progress,
      minHeight: 3,
      backgroundColor: Colors.white12,
      valueColor:
          const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
    );
  }
}

class _SessionComplete extends StatelessWidget {
  const _SessionComplete({
    required this.answered,
    required this.onRestart,
    required this.onExit,
  });

  final int answered;
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
            const Text(
              'Sessione completata!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$answered carte studiate',
              style: const TextStyle(
                  color: Colors.white60, fontSize: 14),
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

// ============================================================================
// Study card (self-contained stateful, no feedProvider dependency)
// ============================================================================

class _StudyCard extends StatefulWidget {
  const _StudyCard({
    super.key,
    required this.lesson,
    required this.studyItem,
    required this.onRate,
  });

  final Lesson lesson;
  final StudyItem studyItem;
  final void Function(bool again) onRate;

  @override
  State<_StudyCard> createState() => _StudyCardState();
}

class _StudyCardState extends State<_StudyCard> {
  bool _revealed = false;
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final correctAnswer =
        widget.lesson.options[widget.lesson.correctAnswerIndex];
    final isAnswered = _selected != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0D1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withAlpha(38),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF6C63FF).withAlpha(80)),
                    ),
                    child: Text(
                      widget.lesson.category,
                      style: const TextStyle(
                        color: Color(0xFFADA8FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.studyItem.goodCount > 0 ||
                    widget.studyItem.againCount > 0)
                  _RatingBadge(
                    good: widget.studyItem.goodCount,
                    again: widget.studyItem.againCount,
                  ),
              ],
            ),
          ),

          // ── Hook ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Text(
              widget.lesson.hook,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Reveal button ────────────────────────────────────────────
          if (!_revealed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: ElevatedButton(
                onPressed: () => setState(() => _revealed = true),
                child: const Text('Reveal'),
              ),
            ),

          // ── Post-reveal content ──────────────────────────────────────
          if (_revealed) ...[
            // Explanation
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withAlpha(18)),
                ),
                child: Text(
                  widget.lesson.explanation,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Quiz question
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                widget.lesson.quizQuestion,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: widget.lesson.options.map((opt) {
                  Color border = Colors.white24;
                  Color bg = Colors.white.withAlpha(13);
                  Color text = Colors.white70;

                  if (isAnswered) {
                    if (opt == correctAnswer) {
                      border = Colors.green;
                      bg = Colors.green.withAlpha(38);
                      text = Colors.green;
                    } else if (opt == _selected) {
                      border = Colors.redAccent;
                      bg = Colors.redAccent.withAlpha(38);
                      text = Colors.redAccent;
                    }
                  }

                  return GestureDetector(
                    onTap: isAnswered
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            setState(() => _selected = opt);
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
                        opt,
                        style: TextStyle(
                          color: text,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Feedback + Again / Good buttons
            if (isAnswered)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  children: [
                    // Feedback banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: (_selected == correctAnswer
                                ? Colors.green
                                : Colors.redAccent)
                            .withAlpha(38),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selected == correctAnswer
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _selected == correctAnswer
                                ? Colors.green
                                : Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _selected == correctAnswer
                                  ? 'Correct!'
                                  : 'Corretto: $correctAnswer',
                              style: TextStyle(
                                color: _selected == correctAnswer
                                    ? Colors.green
                                    : Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // TODO: sostituire con scheduling SRS (v2)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1.5),
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                            ),
                            onPressed: () =>
                                widget.onRate(true),
                            icon: const Icon(Icons.replay,
                                size: 16),
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
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                            ),
                            onPressed: () =>
                                widget.onRate(false),
                            icon: const Icon(Icons.thumb_up,
                                size: 16),
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
// Shared utilities
// ============================================================================

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
              style:
                  const TextStyle(color: Colors.green, fontSize: 11)),
          const SizedBox(width: 6),
        ],
        if (again > 0) ...[
          const Icon(Icons.replay, color: Colors.redAccent, size: 12),
          const SizedBox(width: 2),
          Text('$again',
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 11)),
        ],
      ],
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
          children: [
            const Text('📚', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Il tuo mazzo è vuoto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Tocca l\'icona  🎓  su qualsiasi carta del feed per aggiungerla qui.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingLesson extends StatelessWidget {
  const _MissingLesson(
      {required this.lessonId, required this.onSkip});

  final String lessonId;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Lezione $lessonId non trovata',
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
          TextButton(onPressed: onSkip, child: const Text('Salta')),
        ],
      ),
    );
  }
}
