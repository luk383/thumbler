import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/lesson.dart';
import '../controllers/feed_controller.dart';
import '../../../growth/xp/xp_notifier.dart';
import '../../../growth/daily_quest/daily_quest_notifier.dart';
import '../../../growth/streak/streak_notifier.dart';
import '../../../study/presentation/controllers/study_controller.dart';

class QuizSection extends ConsumerWidget {
  const QuizSection({
    super.key,
    required this.lesson,
    required this.cardIndex,
    required this.selectedAnswer,
  });

  final Lesson lesson;
  final int cardIndex;
  final String? selectedAnswer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correctAnswer = lesson.options[lesson.correctAnswerIndex];
    final repeatsCardPrompt = lesson.quizQuestion.trim() == lesson.hook.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(8),
                const Color(0xFF6C63FF).withAlpha(14),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Check',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFADA8FF),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                repeatsCardPrompt
                    ? 'Choose the best answer below.'
                    : lesson.quizQuestion,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: repeatsCardPrompt ? 14 : 17,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...lesson.options.map(
          (option) => _OptionTile(
            index: lesson.options.indexOf(option),
            option: option,
            selectedAnswer: selectedAnswer,
            correctAnswer: correctAnswer,
            onTap: selectedAnswer != null
                ? null
                : () {
                    ref
                        .read(feedProvider.notifier)
                        .selectAnswer(cardIndex, option);
                    ref
                        .read(studyProvider.notifier)
                        .recordFeedAnswer(
                          lesson.id,
                          correct: option == correctAnswer,
                        );
                    ref.read(streakProvider.notifier).recordStudyQuestion();
                    if (option == correctAnswer) {
                      ref
                          .read(xpProvider.notifier)
                          .addXp(XpEvent.correctAnswer);
                      ref
                          .read(dailyQuestProvider.notifier)
                          .recordCorrectAnswer();
                    }
                  },
          ),
        ),
        if (selectedAnswer != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _FeedbackBanner(isCorrect: selectedAnswer == correctAnswer),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.option,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.onTap,
  });

  final int index;
  final String option;
  final String? selectedAnswer;
  final String correctAnswer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAnswered = selectedAnswer != null;
    final isCorrect = option == correctAnswer;
    final isSelected = selectedAnswer == option;

    Color borderColor = Colors.white.withAlpha(18);
    Color bgColor = const Color(0xFF121620);
    Color textColor = Colors.white70;
    IconData? stateIcon;

    if (isAnswered) {
      if (isCorrect) {
        borderColor = const Color(0xFF2ECC71);
        bgColor = const Color(0x222ECC71);
        textColor = Colors.white;
        stateIcon = Icons.check_circle;
      } else if (isSelected) {
        borderColor = const Color(0xFFFF6B6B);
        bgColor = const Color(0x22FF6B6B);
        textColor = Colors.white;
        stateIcon = Icons.close_rounded;
      }
    }

    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor, bgColor.withAlpha(220)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(12)),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isAnswered)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white24,
                size: 18,
              ),
            if (stateIcon != null) ...[
              const SizedBox(width: 12),
              Icon(
                stateIcon,
                color: isCorrect
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFFF6B6B),
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.isCorrect});

  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF2ECC71) : const Color(0xFFFF6B6B);
    final icon = isCorrect ? Icons.check_circle : Icons.info_outline;
    final title = isCorrect ? 'Correct answer' : 'Review before you scroll';
    final label = isCorrect
        ? 'Nice hit. You earned XP and can keep the streak moving.'
        : 'The explanation above contains the key idea. Read it once, then continue.';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
