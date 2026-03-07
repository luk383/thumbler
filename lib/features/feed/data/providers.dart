import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/lesson.dart';
import 'lesson_repository.dart';
import 'feed_session_memory.dart';
import '../../analytics/presentation/providers/progress_analytics_provider.dart';
import '../../study/presentation/controllers/study_controller.dart';
import '../../study/presentation/controllers/deck_library_controller.dart';

final feedSessionMemoryProvider = Provider<FeedSessionMemory>(
  (ref) => FeedSessionMemory(),
);

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LocalDeckLessonRepository(
    activeDeckId: ref.watch(activeDeckIdProvider),
    items: ref.watch(studyProvider.select((state) => state.items)),
    weakestDomains: ref.watch(
      progressAnalyticsProvider.select(
        (analytics) =>
            analytics.weakestDomains.map((summary) => summary.domain).toList(),
      ),
    ),
    sessionMemory: ref.watch(feedSessionMemoryProvider),
  ),
);

final lessonsProvider = FutureProvider<List<Lesson>>(
  (ref) => ref.watch(lessonRepositoryProvider).fetchLessons(),
);
