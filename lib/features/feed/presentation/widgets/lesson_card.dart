import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/lesson.dart';
import '../controllers/feed_controller.dart';
import '../../../bookmarks/presentation/bookmarks_notifier.dart';
import '../../../growth/xp/xp_notifier.dart';
import '../../../share/share_service.dart';
import '../../../study/presentation/controllers/study_controller.dart';
import 'quiz_section.dart';

/// How long to wait after an answer before auto-advancing to the next card.
const _kAutoAdvanceDelay = Duration(milliseconds: 700);

class LessonCard extends ConsumerStatefulWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.cardIndex,
    this.onNext,
    this.autoAdvanceDelay = _kAutoAdvanceDelay,
  });

  final Lesson lesson;
  final int cardIndex;
  final VoidCallback? onNext;

  /// Configurable delay before auto-advancing after an answer is selected.
  final Duration autoAdvanceDelay;

  @override
  ConsumerState<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends ConsumerState<LessonCard> {
  Timer? _autoAdvanceTimer;

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(widget.autoAdvanceDelay, () {
      if (mounted) widget.onNext?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardState = ref.watch(
      feedProvider.select((s) => s.cardStateAt(widget.cardIndex)),
    );
    final isBookmarked = ref.watch(
      bookmarksProvider.select((ids) => ids.contains(widget.lesson.id)),
    );
    final isInStudy = ref.watch(
      studyProvider.select((s) => s.inDeck(widget.lesson.id)),
    );

    // When selectedAnswer transitions null → value, schedule auto-advance.
    ref.listen(
      feedProvider.select(
        (s) => s.cardStateAt(widget.cardIndex).selectedAnswer,
      ),
      (prev, next) {
        if (next != null && prev == null) _scheduleAutoAdvance();
      },
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Colors.black, Color(0xFF0D0B1A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Category chip ──────────────────────────────────────────
            _CategoryChip(category: widget.lesson.category),

            // ── Scrollable main content ────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Hook — always visible
                    Text(
                      widget.lesson.hook,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),

                    // Animated reveal: explanation + quiz fade & slide in
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: cardState.revealed
                          ? Column(
                              key: const ValueKey('revealed'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 28),
                                _ExplanationBox(
                                  explanation: widget.lesson.explanation,
                                ),
                                const SizedBox(height: 20),
                                QuizSection(
                                  lesson: widget.lesson,
                                  cardIndex: widget.cardIndex,
                                  selectedAnswer: cardState.selectedAnswer,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(key: ValueKey('hidden')),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Reveal button (animated disappear) ─────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: !cardState.revealed
                  ? Padding(
                      key: const ValueKey('reveal-btn'),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(feedProvider.notifier)
                                .reveal(widget.cardIndex);
                            ref
                                .read(xpProvider.notifier)
                                .addXp(XpEvent.reveal);
                          },
                          child: const Text('Reveal'),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-btn')),
            ),

            // ── Bottom action bar ──────────────────────────────────────
            _BottomBar(
              isBookmarked: isBookmarked,
              isInStudy: isInStudy,
              onBookmark: () => ref
                  .read(bookmarksProvider.notifier)
                  .toggle(widget.lesson.id),
              onAddToStudy: () => ref
                  .read(studyProvider.notifier)
                  .addLesson(widget.lesson),
              onShare: () =>
                  ShareService.shareLesson(context, widget.lesson),
              onNext: widget.onNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withAlpha(38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6C63FF).withAlpha(100)),
          ),
          child: Text(
            category,
            style: const TextStyle(
              color: Color(0xFFADA8FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  const _ExplanationBox({required this.explanation});

  final String explanation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Text(
        explanation,
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isBookmarked,
    required this.isInStudy,
    required this.onBookmark,
    required this.onAddToStudy,
    required this.onShare,
    this.onNext,
  });

  final bool isBookmarked;
  final bool isInStudy;
  final VoidCallback onBookmark;
  final VoidCallback onAddToStudy;
  final VoidCallback onShare;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _IconBtn(
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
            color: isBookmarked ? const Color(0xFF6C63FF) : Colors.white60,
            onTap: onBookmark,
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: isInStudy ? Icons.school : Icons.school_outlined,
            color: isInStudy ? Colors.tealAccent : Colors.white60,
            onTap: onAddToStudy,
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.share_outlined,
            color: Colors.white60,
            onTap: onShare,
          ),
          if (onNext != null) ...[
            const SizedBox(width: 8),
            _IconBtn(
              icon: Icons.keyboard_arrow_down_rounded,
              color: Colors.white60,
              onTap: onNext!,
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
