import '../rewards/reward_service.dart';

enum QuestType { earnXp, answerQuizzes }

class DailyQuestState {
  const DailyQuestState({
    required this.questType,
    required this.questTarget,
    required this.questProgress,
    required this.questCompleted,
    required this.totalCompleted,
    required this.lastCompletedDate,
    required this.xpBoostActive,
    required this.modalShownToday,
    this.pendingReward,
  });

  final QuestType questType;
  final int questTarget;
  final int questProgress;
  final bool questCompleted;
  final int totalCompleted;
  final String? lastCompletedDate;
  final bool xpBoostActive;
  final bool modalShownToday;
  final RewardType? pendingReward;

  double get progress => (questProgress / questTarget).clamp(0.0, 1.0);

  String get description => questType == QuestType.earnXp
      ? 'Earn $questTarget XP today'
      : 'Answer $questTarget quizzes correctly';

  DailyQuestState copyWith({
    QuestType? questType,
    int? questTarget,
    int? questProgress,
    bool? questCompleted,
    int? totalCompleted,
    String? lastCompletedDate,
    bool? xpBoostActive,
    bool? modalShownToday,
    RewardType? Function()? pendingReward,
  }) {
    return DailyQuestState(
      questType: questType ?? this.questType,
      questTarget: questTarget ?? this.questTarget,
      questProgress: questProgress ?? this.questProgress,
      questCompleted: questCompleted ?? this.questCompleted,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      xpBoostActive: xpBoostActive ?? this.xpBoostActive,
      modalShownToday: modalShownToday ?? this.modalShownToday,
      pendingReward:
          pendingReward != null ? pendingReward() : this.pendingReward,
    );
  }
}
