import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wolf_lab/features/feed/domain/lesson.dart';
import 'package:wolf_lab/features/share/share_card_widget.dart';

void main() {
  testWidgets('Share card renders lesson content and branding', (tester) async {
    const lesson = Lesson(
      id: 'security-basics',
      hook: 'Use unique passwords for every critical account.',
      explanation: 'Password reuse increases blast radius after a breach.',
      quizQuestion: 'What reduces account takeover risk?',
      options: ['Reuse passwords', 'Use unique passwords'],
      correctAnswerIndex: 1,
      category: 'Security',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ShareCardWidget(lesson: lesson)),
      ),
    );

    expect(find.text('Security'), findsOneWidget);
    expect(
      find.text('Use unique passwords for every critical account.'),
      findsOneWidget,
    );
    expect(find.text('Wolf Lab'), findsOneWidget);
  });
}
