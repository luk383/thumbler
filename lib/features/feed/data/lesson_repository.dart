import '../domain/lesson.dart';
import 'mock_lessons.dart';

// TODO: Replace MockLessonRepository with SupabaseLessonRepository
abstract interface class LessonRepository {
  Future<List<Lesson>> fetchLessons();
}

class MockLessonRepository implements LessonRepository {
  @override
  Future<List<Lesson>> fetchLessons() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return mockLessons;
  }
}
