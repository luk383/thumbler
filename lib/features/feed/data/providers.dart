import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/lesson.dart';
import 'lesson_repository.dart';

// TODO: Swap MockLessonRepository for SupabaseLessonRepository
final lessonRepositoryProvider = Provider<LessonRepository>(
  (_) => MockLessonRepository(),
);

final lessonsProvider = FutureProvider<List<Lesson>>(
  (ref) => ref.watch(lessonRepositoryProvider).fetchLessons(),
);
