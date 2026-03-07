import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../paywall/presentation/paywall_page.dart';
import '../../../paywall/pro_guard.dart';
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
    final l10n = context.l10n;
    final canAccessExam = ref.watch(
      proGuardProvider.select((guard) => guard.canAccessExamMode()),
    );
    if (!canAccessExam) {
      return PaywallPage(
        featureName: 'Exam mode',
        title: l10n.examModeProTitle,
        subtitle: l10n.examModeProSubtitle,
      );
    }

    final phase = ref.watch(examProvider.select((s) => s.phase));
    return switch (phase) {
      ExamPhase.home || ExamPhase.paused => const ExamHomePage(),
      ExamPhase.active => const ExamSessionPage(),
      ExamPhase.results || ExamPhase.reviewing => const ExamResultsPage(),
    };
  }
}
