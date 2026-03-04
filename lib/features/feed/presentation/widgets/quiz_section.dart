import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/lesson.dart';
import '../feed_controller.dart';
import '../../../growth/xp/xp_notifier.dart';
import '../../../growth/daily_quest/daily_quest_notifier.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lesson.quizQuestion,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ...lesson.options.map(
          (option) => _OptionTile(
            option: option,
            selectedAnswer: selectedAnswer,
            correctAnswer: lesson.correctAnswer,
            onTap: selectedAnswer != null
                ? null
                : () {
                    ref
                        .read(feedProvider.notifier)
                        .selectAnswer(cardIndex, option);
                    if (option == lesson.correctAnswer) {
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
          _FeedbackBanner(isCorrect: selectedAnswer == lesson.correctAnswer),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.onTap,
  });

  final String option;
  final String? selectedAnswer;
  final String correctAnswer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isAnswered = selectedAnswer != null;
    final isCorrect = option == correctAnswer;
    final isSelected = selectedAnswer == option;

    Color borderColor = Colors.white24;
    Color bgColor = Colors.white.withAlpha(13);
    Color textColor = Colors.white70;

    if (isAnswered) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withAlpha(38);
        textColor = Colors.green;
      } else if (isSelected) {
        borderColor = Colors.redAccent;
        bgColor = Colors.redAccent.withAlpha(38);
        textColor = Colors.redAccent;
      }
    }

    return GestureDetector(
      // Wrap with haptic so every tap feels responsive.
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          option,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
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
    final color = isCorrect ? Colors.green : Colors.redAccent;
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final label = isCorrect ? 'Correct! +3 XP' : 'Not quite — try the next!';

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
