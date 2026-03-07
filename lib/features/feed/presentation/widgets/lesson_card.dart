import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookmarks/presentation/bookmarks_notifier.dart';
import '../../../../core/ui/app_surfaces.dart';
import '../../../growth/xp/xp_notifier.dart';
import '../../../share/share_service.dart';
import '../../../study/presentation/controllers/study_controller.dart';
import '../../domain/lesson.dart';
import '../controllers/feed_controller.dart';
import 'quiz_section.dart';

const _kAutoAdvanceDelay = Duration(milliseconds: 1600);

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
  final Duration autoAdvanceDelay;

  @override
  ConsumerState<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends ConsumerState<LessonCard> {
  static const _overlayClearance = 88.0;

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
      feedProvider.select((s) => s.cardStateFor(widget.lesson.id)),
    );
    final isBookmarked = ref.watch(
      bookmarksProvider.select((ids) => ids.contains(widget.lesson.id)),
    );
    final isInStudy = ref.watch(
      studyProvider.select((s) => s.inDeck(widget.lesson.id)),
    );
    final repeatsQuizQuestion =
        widget.lesson.hook.trim() == widget.lesson.quizQuestion.trim();

    ref.listen(
        feedProvider.select(
          (s) => s.cardStateFor(widget.lesson.id).selectedAnswer,
      ),
      (prev, next) {
        if (next != null && prev == null) _scheduleAutoAdvance();
      },
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0C11), Color(0xFF090A0F), Color(0xFF111421)],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  _overlayClearance,
                  20,
                  18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CategoryChip(
                            category: widget.lesson.category,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AppGlassCard(
                      padding: const EdgeInsets.all(22),
                      radius: 28,
                      tint: const Color(0xFF6C63FF),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppStatusBadge(
                                label: 'Feed card',
                                icon: Icons.bolt_rounded,
                                tint: Color(0xFFADA8FF),
                              ),
                              const Spacer(),
                              Text(
                                'Swipe or tap next',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white38,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                repeatsQuizQuestion
                                    ? 'Question card'
                                    : 'Micro lesson',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFFADA8FF),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.lesson.hook,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(height: 1.2, fontSize: 26),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1320).withAlpha(220),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withAlpha(10),
                              ),
                            ),
                            child: Text(
                              repeatsQuizQuestion
                                  ? cardState.revealed
                                        ? 'Read the explanation, answer once, then keep scrolling.'
                                        : 'Read the question, reveal the explanation, then answer once.'
                                  : cardState.revealed
                                  ? 'Review the explanation, answer one quick check, then keep scrolling.'
                                  : 'Reveal the explanation, answer one quick check, then move to the next card.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          ? Padding(
                              key: const ValueKey('revealed'),
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _ExplanationBox(
                                    explanation: widget.lesson.explanation,
                                  ),
                                  const SizedBox(height: 18),
                                  QuizSection(
                                    lesson: widget.lesson,
                                    cardIndex: widget.cardIndex,
                                    selectedAnswer: cardState.selectedAnswer,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('hidden')),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: !cardState.revealed
                  ? Padding(
                      key: const ValueKey('reveal-btn'),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(feedProvider.notifier)
                                .reveal(widget.lesson.id);
                            ref.read(xpProvider.notifier).addXp(XpEvent.reveal);
                          },
                          child: const Text('Reveal Answer + Quiz'),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-btn')),
            ),
            _BottomBar(
              isBookmarked: isBookmarked,
              isInStudy: isInStudy,
              onBookmark: () =>
                  ref.read(bookmarksProvider.notifier).toggle(widget.lesson.id),
              onAddToStudy: () =>
                  ref.read(studyProvider.notifier).addLesson(widget.lesson),
              onShare: () => ShareService.shareLesson(context, widget.lesson),
              onNext: widget.onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withAlpha(24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6C63FF).withAlpha(70)),
        ),
        child: Text(
          category,
          style: const TextStyle(
            color: Color(0xFFADA8FF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(11),
            const Color(0xFF6C63FF).withAlpha(12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why this matters',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(explanation, style: Theme.of(context).textTheme.bodyLarge),
        ],
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1320).withAlpha(224),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withAlpha(16)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _IconBtn(
                    icon: isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    color: isBookmarked
                        ? const Color(0xFF6C63FF)
                        : Colors.white60,
                    label: isBookmarked ? 'Saved' : 'Save',
                    onTap: onBookmark,
                  ),
                  _IconBtn(
                    icon: isInStudy ? Icons.school : Icons.school_outlined,
                    color: isInStudy ? Colors.tealAccent : Colors.white60,
                    label: isInStudy ? 'In Study' : 'Study',
                    onTap: onAddToStudy,
                  ),
                  _IconBtn(
                    icon: Icons.share_outlined,
                    color: Colors.white60,
                    label: 'Share',
                    onTap: onShare,
                  ),
                ],
              ),
            ),
            if (onNext != null)
              _IconBtn(
                icon: Icons.keyboard_arrow_down_rounded,
                color: Colors.white60,
                label: 'Next',
                onTap: onNext!,
              ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
