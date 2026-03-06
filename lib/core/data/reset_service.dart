import 'package:hive/hive.dart';

import '../../features/exam/data/exam_attempt_storage.dart';
import '../../features/study/data/study_storage.dart';

class ResetService {
  const ResetService();

  static const xpBoxName = 'xp_box';
  static const streakBoxName = 'streak_box';
  static const bookmarksBoxName = 'bookmarks_box';
  static const questBoxName = 'quest_box';
  static const studyBoxName = StudyStorage.boxName;
  static const examBoxName = ExamAttemptStorage.boxName;

  Future<void> resetStudyDeck() async {
    // TODO: When cloud sync exists, separate local-only reset from remote reset.
    await StudyStorage().clearAll();
  }

  Future<void> resetProgress() async {
    // TODO: When cloud sync exists, separate local-only reset from remote reset.
    await Hive.box(xpBoxName).clear();
    await Hive.box(streakBoxName).clear();
    await Hive.box(questBoxName).clear();
    await StudyStorage().resetProgress();
  }

  Future<void> resetExamHistory() async {
    // TODO: When cloud sync exists, separate local-only reset from remote reset.
    await ExamAttemptStorage().clearAll();
  }

  Future<void> resetAllAppData() async {
    // TODO: When cloud sync exists, separate local-only reset from remote reset.
    await Hive.box(xpBoxName).clear();
    await Hive.box(streakBoxName).clear();
    await Hive.box(bookmarksBoxName).clear();
    await Hive.box(questBoxName).clear();
    await Hive.box(studyBoxName).clear();
    await Hive.box(examBoxName).clear();
  }
}
