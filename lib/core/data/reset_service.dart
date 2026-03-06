import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../features/bookmarks/presentation/bookmarks_notifier.dart';
import '../../features/exam/data/exam_attempt_storage.dart';
import '../../features/exam/data/exam_history_storage.dart';
import '../../features/exam/presentation/controllers/exam_controller.dart';
import '../../features/growth/daily_quest/daily_quest_notifier.dart';
import '../../features/growth/streak/streak_notifier.dart';
import '../../features/growth/xp/xp_notifier.dart';
import '../../features/study/data/study_storage.dart';
import '../../features/study/data/deck_library_storage.dart';
import '../../features/study/presentation/controllers/deck_library_controller.dart';
import '../../features/study/presentation/controllers/study_controller.dart';

enum ResetAction { studyDeck, progress, examHistory, allData }

class ResetService {
  const ResetService();

  static const xpBoxName = 'xp_box';
  static const streakBoxName = 'streak_box';
  static const bookmarksBoxName = 'bookmarks_box';
  static const questBoxName = 'quest_box';
  static const studyBoxName = StudyStorage.boxName;
  static const examBoxName = ExamAttemptStorage.boxName;
  static const libraryBoxName = DeckLibraryStorage.boxName;

  Future<void> resetStudyDeck({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return _runReset(
      context: context,
      ref: ref,
      successMessage: 'Study deck reset',
      operation: () => StudyStorage().clearAll(),
      onAfterClear: () async {
        ref
            .read(studyProvider.notifier)
            .resetAfterDataChange(clearSelections: true);
        ref.read(examProvider.notifier).resetAfterDataChange();
      },
    );
  }

  Future<void> resetProgress({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return _runReset(
      context: context,
      ref: ref,
      successMessage: 'Progress reset',
      operation: () async {
        await Hive.box(xpBoxName).clear();
        await Hive.box(streakBoxName).clear();
        await Hive.box(questBoxName).clear();
        await StudyStorage().resetProgress();
      },
      onAfterClear: () async {
        ref.read(xpProvider.notifier).reloadFromStorage();
        ref.read(streakProvider.notifier).reloadFromStorage();
        ref.read(dailyQuestProvider.notifier).reloadFromStorage();
        ref.read(studyProvider.notifier).resetAfterDataChange();
        ref.read(examProvider.notifier).resetAfterDataChange();
      },
    );
  }

  Future<void> resetExamHistory({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return _runReset(
      context: context,
      ref: ref,
      successMessage: 'Exam history reset',
      operation: () async {
        await ExamAttemptStorage().clearAll();
        await ExamHistoryStorage().clearResults();
      },
      onAfterClear: () async {
        ref.read(examProvider.notifier).resetAfterDataChange();
      },
    );
  }

  Future<void> resetAllData({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return _runReset(
      context: context,
      ref: ref,
      successMessage: 'All app data reset',
      operation: () async {
        await Hive.box(xpBoxName).clear();
        await Hive.box(streakBoxName).clear();
        await Hive.box(bookmarksBoxName).clear();
        await Hive.box(questBoxName).clear();
        await Hive.box(studyBoxName).clear();
        await Hive.box(examBoxName).clear();
        await Hive.box(libraryBoxName).clear();
      },
      onAfterClear: () async {
        ref.read(xpProvider.notifier).reloadFromStorage();
        ref.read(streakProvider.notifier).reloadFromStorage();
        ref.read(bookmarksProvider.notifier).reloadFromStorage();
        ref.read(dailyQuestProvider.notifier).reloadFromStorage();
        await ref.read(deckLibraryProvider.notifier).discoverPacks();
        ref
            .read(studyProvider.notifier)
            .resetAfterDataChange(clearSelections: true);
        ref.read(examProvider.notifier).resetAfterDataChange();
      },
    );
  }

  Future<void> _runReset({
    required BuildContext context,
    required WidgetRef ref,
    required Future<void> Function() operation,
    required Future<void> Function() onAfterClear,
    required String successMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      FocusManager.instance.primaryFocus?.unfocus();

      await operation();
      await onAfterClear();

      if (context.mounted) {
        context.go('/');
        await Future<void>.delayed(Duration.zero);
      }

      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: const Color(0xFF0D8B5F),
          ),
        );
    } catch (error) {
      if (!context.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Reset failed: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }
}
