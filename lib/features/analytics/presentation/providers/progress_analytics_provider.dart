import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../exam/presentation/controllers/exam_controller.dart';
import '../../../study/presentation/controllers/study_controller.dart';
import '../../../study/presentation/controllers/deck_library_controller.dart';
import '../../domain/progress_analytics.dart';

final progressAnalyticsProvider = Provider<ProgressAnalytics>((ref) {
  final studyItems = ref.watch(studyProvider.select((state) => state.items));
  final activeDeckId = ref.watch(activeDeckIdProvider);
  final examResults = ref.watch(
    examProvider.select(
      (state) => state.results
          .where(
            (result) => activeDeckId == null
                ? result.deckId == null
                : result.deckId == activeDeckId,
          )
          .toList(),
    ),
  );

  return buildProgressAnalytics(
    studyItems: studyItems,
    examResults: examResults,
  );
});
