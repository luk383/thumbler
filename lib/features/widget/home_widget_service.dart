import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../growth/streak/streak_state.dart';
import '../growth/xp/xp_notifier.dart';
import '../study/presentation/controllers/study_controller.dart';

class HomeWidgetService {
  static const _appGroupId = 'com.wolflab.app';
  static const _androidName = 'WolfLabWidgetProvider';

  static Future<void> update({
    required StreakState streak,
    required XpState xp,
    required StudyState study,
  }) async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<int>('streak', streak.currentStreak);
      await HomeWidget.saveWidgetData<int>('due_cards', study.dueCount);
      await HomeWidget.saveWidgetData<int>('daily_xp', xp.dailyXp);
      await HomeWidget.updateWidget(
        androidName: _androidName,
        qualifiedAndroidName: '$_appGroupId.$_androidName',
      );
    } catch (e) {
      debugPrint('[HomeWidget] update failed: $e');
    }
  }
}
