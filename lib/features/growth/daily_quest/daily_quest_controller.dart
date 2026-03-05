import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../rewards/reward_service.dart';
import '../xp/xp_notifier.dart';
import 'daily_quest_state.dart';

class DailyQuestNotifier extends Notifier<DailyQuestState> {
  static const _dateKey = 'quest_date';
  static const _typeKey = 'quest_type';
  static const _progressKey = 'quest_progress';
  static const _completedKey = 'quest_completed';
  static const _totalKey = 'total_completed';
  static const _lastCompletedKey = 'last_completed_date';
  static const _xpBoostKey = 'xp_boost_date';
  static const _modalShownKey = 'modal_shown_date';

  Box get _box => Hive.box('quest_box');

  @override
  DailyQuestState build() {
    final today = _today();
    _ensureQuestIsForToday(today);

    // For earnXp quest: reactively track XP changes.
    ref.listen(xpProvider.select((s) => s.dailyXp), (prev, next) {
      if (state.questType == QuestType.earnXp && !state.questCompleted) {
        _updateEarnXpProgress(next);
      }
    });

    return _loadState(today);
  }

  void _ensureQuestIsForToday(String today) {
    final storedDate = _box.get(_dateKey, defaultValue: '') as String;
    if (storedDate == today) return;

    // New day — reset quest (alternate type by weekday).
    final questType = DateTime.now().weekday.isOdd
        ? QuestType.earnXp
        : QuestType.answerQuizzes;

    _box.put(_dateKey, today);
    _box.put(_typeKey, questType.index);
    _box.put(_progressKey, 0);
    _box.put(_completedKey, false);
    // xpBoostKey is intentionally left: it may persist from a previous reward.
  }

  DailyQuestState _loadState(String today) {
    final typeIndex =
        (_box.get(_typeKey, defaultValue: 0) as num).toInt();
    final questType =
        QuestType.values[typeIndex.clamp(0, QuestType.values.length - 1)];
    final target = questType == QuestType.earnXp ? 10 : 3;

    // For earnXp, derive progress from actual dailyXp to stay in sync.
    int progress;
    if (questType == QuestType.earnXp) {
      final xpBox = Hive.box('xp_box');
      progress =
          (xpBox.get('daily_xp', defaultValue: 0) as num).toInt().clamp(0, target);
    } else {
      progress =
          (_box.get(_progressKey, defaultValue: 0) as num).toInt().clamp(0, target);
    }

    final completed = _box.get(_completedKey, defaultValue: false) as bool;
    final totalCompleted =
        (_box.get(_totalKey, defaultValue: 0) as num).toInt();
    final lastCompletedDate = _box.get(_lastCompletedKey) as String?;
    final xpBoostDate = _box.get(_xpBoostKey) as String?;
    final xpBoostActive = xpBoostDate == today;
    final modalShownDate = _box.get(_modalShownKey) as String?;
    final modalShownToday = modalShownDate == today;

    return DailyQuestState(
      questType: questType,
      questTarget: target,
      questProgress: progress,
      questCompleted: completed,
      totalCompleted: totalCompleted,
      lastCompletedDate: lastCompletedDate,
      xpBoostActive: xpBoostActive,
      modalShownToday: modalShownToday,
    );
  }

  void _updateEarnXpProgress(int dailyXp) {
    final clamped = dailyXp.clamp(0, state.questTarget);
    if (clamped == state.questProgress) return;
    state = state.copyWith(questProgress: clamped);
    if (clamped >= state.questTarget && !state.questCompleted) {
      _completeQuest();
    }
  }

  /// Call when a correct quiz answer is selected.
  void recordCorrectAnswer() {
    if (state.questType != QuestType.answerQuizzes) return;
    if (state.questCompleted) return;

    final newProgress = state.questProgress + 1;
    _box.put(_progressKey, newProgress);
    state = state.copyWith(questProgress: newProgress);
    if (newProgress >= state.questTarget) _completeQuest();
  }

  void _completeQuest() {
    final today = _today();
    final reward = RewardService.pickRandom();
    final total = state.totalCompleted + 1;

    _box.put(_completedKey, true);
    _box.put(_totalKey, total);
    _box.put(_lastCompletedKey, today);
    if (reward == RewardType.xpBoost) _box.put(_xpBoostKey, today);

    state = state.copyWith(
      questCompleted: true,
      totalCompleted: total,
      lastCompletedDate: today,
      xpBoostActive: reward == RewardType.xpBoost,
      pendingReward: () => reward,
    );
  }

  void markModalShown() {
    _box.put(_modalShownKey, _today());
    state = state.copyWith(modalShownToday: true);
  }

  void clearPendingReward() {
    state = state.copyWith(pendingReward: () => null);
  }

  /// Dev-only: wipe today's quest so you can trigger the full flow again.
  void devResetQuest() {
    _box.put(_dateKey, '');
    _box.put(_progressKey, 0);
    _box.put(_completedKey, false);
    _box.put(_modalShownKey, '');
    _box.put(_xpBoostKey, '');

    final today = _today();
    _ensureQuestIsForToday(today);
    state = _loadState(today);
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final dailyQuestProvider =
    NotifierProvider<DailyQuestNotifier, DailyQuestState>(
  DailyQuestNotifier.new,
);
