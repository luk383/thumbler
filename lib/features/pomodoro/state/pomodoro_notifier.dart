import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../growth/xp/xp_notifier.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroState {
  const PomodoroState({
    this.phase = PomodoroPhase.work,
    this.remainingSeconds = 25 * 60,
    this.isRunning = false,
    this.completedSessions = 0,
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
  });

  final PomodoroPhase phase;
  final int remainingSeconds;
  final bool isRunning;
  final int completedSessions;
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  int get totalSeconds => switch (phase) {
        PomodoroPhase.work => workMinutes * 60,
        PomodoroPhase.shortBreak => shortBreakMinutes * 60,
        PomodoroPhase.longBreak => longBreakMinutes * 60,
      };

  double get progress =>
      1.0 - (remainingSeconds / totalSeconds).clamp(0.0, 1.0);

  String get timeString {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? remainingSeconds,
    bool? isRunning,
    int? completedSessions,
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
  }) => PomodoroState(
        phase: phase ?? this.phase,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        isRunning: isRunning ?? this.isRunning,
        completedSessions: completedSessions ?? this.completedSessions,
        workMinutes: workMinutes ?? this.workMinutes,
        shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
        longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      );
}

class PomodoroNotifier extends Notifier<PomodoroState> {
  static const _boxName = 'pomodoro_box';
  static const _keyTotal = 'total_completed';
  Timer? _timer;

  @override
  PomodoroState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const PomodoroState();
  }

  int get totalCompleted {
    final box = Hive.box(_boxName);
    return (box.get(_keyTotal, defaultValue: 0) as num).toInt();
  }

  void startPause() {
    if (state.isRunning) {
      _timer?.cancel();
      state = state.copyWith(isRunning: false);
    } else {
      state = state.copyWith(isRunning: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void reset() {
    _timer?.cancel();
    state = PomodoroState(
      phase: state.phase,
      workMinutes: state.workMinutes,
      shortBreakMinutes: state.shortBreakMinutes,
      longBreakMinutes: state.longBreakMinutes,
      remainingSeconds: state.totalSeconds,
      completedSessions: state.completedSessions,
    );
  }

  void skipToNext() {
    _timer?.cancel();
    _advancePhase();
  }

  void updateSettings({int? workMin, int? shortMin, int? longMin}) {
    _timer?.cancel();
    final w = workMin ?? state.workMinutes;
    final s = shortMin ?? state.shortBreakMinutes;
    final l = longMin ?? state.longBreakMinutes;
    state = PomodoroState(
      workMinutes: w,
      shortBreakMinutes: s,
      longBreakMinutes: l,
      remainingSeconds: w * 60,
      completedSessions: state.completedSessions,
    );
  }

  void _tick() {
    if (state.remainingSeconds <= 1) {
      _sessionComplete();
    } else {
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    }
  }

  void _sessionComplete() {
    _timer?.cancel();
    if (state.phase == PomodoroPhase.work) {
      final newCount = state.completedSessions + 1;
      final box = Hive.box(_boxName);
      box.put(_keyTotal, totalCompleted + 1);
      ref.read(xpProvider.notifier).addXp(XpEvent.pomodoroComplete);
      _advancePhase(completedSessions: newCount);
    } else {
      _advancePhase();
    }
  }

  void _advancePhase({int? completedSessions}) {
    final done = completedSessions ?? state.completedSessions;
    final PomodoroPhase next;
    if (state.phase == PomodoroPhase.work) {
      next = done % 4 == 0 ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
    } else {
      next = PomodoroPhase.work;
    }
    state = PomodoroState(
      phase: next,
      completedSessions: done,
      workMinutes: state.workMinutes,
      shortBreakMinutes: state.shortBreakMinutes,
      longBreakMinutes: state.longBreakMinutes,
      remainingSeconds: switch (next) {
        PomodoroPhase.work => state.workMinutes * 60,
        PomodoroPhase.shortBreak => state.shortBreakMinutes * 60,
        PomodoroPhase.longBreak => state.longBreakMinutes * 60,
      },
      isRunning: false,
    );
  }
}

final pomodoroProvider =
    NotifierProvider<PomodoroNotifier, PomodoroState>(PomodoroNotifier.new);
