import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const int dailyGoal = 10;

enum XpEvent {
  // Study
  viewCard,
  reveal,
  correctAnswer,
  // Personal growth
  habitComplete,
  goalMilestone,
  journalEntry,
  weeklyReflection,
  bookCompleted,
  customCard,
  pomodoroComplete;

  int get points => switch (this) {
    XpEvent.viewCard => 1,
    XpEvent.reveal => 1,
    XpEvent.correctAnswer => 3,
    XpEvent.habitComplete => 5,
    XpEvent.goalMilestone => 10,
    XpEvent.journalEntry => 2,
    XpEvent.weeklyReflection => 10,
    XpEvent.bookCompleted => 5,
    XpEvent.customCard => 3,
    XpEvent.pomodoroComplete => 8,
  };

  String get label => switch (this) {
    XpEvent.viewCard => 'Carta vista',
    XpEvent.reveal => 'Spiegazione letta',
    XpEvent.correctAnswer => 'Risposta corretta',
    XpEvent.habitComplete => 'Abitudine completata',
    XpEvent.goalMilestone => 'Milestone raggiunto',
    XpEvent.journalEntry => 'Nota scritta',
    XpEvent.weeklyReflection => 'Riflessione settimanale',
    XpEvent.bookCompleted => 'Libro/corso completato',
    XpEvent.customCard => 'Carta creata',
    XpEvent.pomodoroComplete => 'Pomodoro completato',
  };
}

class XpState {
  const XpState({this.totalXp = 0, this.dailyXp = 0});

  final int totalXp;
  final int dailyXp;

  XpState copyWith({int? totalXp, int? dailyXp}) => XpState(
    totalXp: totalXp ?? this.totalXp,
    dailyXp: dailyXp ?? this.dailyXp,
  );
}

class XpNotifier extends Notifier<XpState> {
  static const _boxName = 'xp_box';
  static const _keyTotal = 'total_xp';
  static const _keyDaily = 'daily_xp';
  static const _keyDate = 'daily_date';

  late final Box _box;

  @override
  XpState build() {
    _box = Hive.box(_boxName);
    _resetDailyIfNeeded();
    return XpState(
      totalXp: (_box.get(_keyTotal, defaultValue: 0) as num).toInt(),
      dailyXp: (_box.get(_keyDaily, defaultValue: 0) as num).toInt(),
    );
  }

  void _resetDailyIfNeeded() {
    final today = _todayString();
    final lastDate = _box.get(_keyDate, defaultValue: '') as String;
    if (lastDate != today) {
      _box.put(_keyDaily, 0);
      _box.put(_keyDate, today);
    }
  }

  void addXp(XpEvent event) {
    final pts = _boosted(event.points);
    final newTotal = state.totalXp + pts;
    final newDaily = state.dailyXp + pts;
    _box.put(_keyTotal, newTotal);
    _box.put(_keyDaily, newDaily);
    state = XpState(totalXp: newTotal, dailyXp: newDaily);
  }

  /// Applies +20% XP boost if the user earned an xpBoost reward today.
  int _boosted(int base) {
    final questBox = Hive.box('quest_box');
    final boostDate = questBox.get('xp_boost_date') as String?;
    if (boostDate == _todayString()) return (base * 1.2).round();
    return base;
  }

  void reloadFromStorage() {
    _resetDailyIfNeeded();
    state = XpState(
      totalXp: (_box.get(_keyTotal, defaultValue: 0) as num).toInt(),
      dailyXp: (_box.get(_keyDaily, defaultValue: 0) as num).toInt(),
    );
  }

  String _todayString() =>
      DateTime.now().toIso8601String().substring(0, 10);
}

final xpProvider = NotifierProvider<XpNotifier, XpState>(XpNotifier.new);
