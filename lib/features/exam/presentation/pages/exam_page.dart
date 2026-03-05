import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/exam_controller.dart';
import '../controllers/exam_state.dart';
import 'exam_home_page.dart';
import 'exam_results_page.dart';
import 'exam_session_page.dart';

/// Root widget for the Exam tab. Routes between home, session, and results
/// based on [ExamPhase].
class ExamPage extends ConsumerWidget {
  const ExamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(examProvider.select((s) => s.phase));
    return switch (phase) {
      ExamPhase.home || ExamPhase.paused => const ExamHomePage(),
      ExamPhase.active => const ExamSessionPage(),
      ExamPhase.results || ExamPhase.reviewing => const ExamResultsPage(),
    };
  }
}
