import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wolf_lab/features/growth/streak/streak_controller.dart';
import 'package:wolf_lab/features/growth/streak/streak_state.dart';

class _TestStreakNotifier extends StreakNotifier {
  _TestStreakNotifier(this._now);

  DateTime _now;

  void setNow(DateTime value) {
    _now = value;
  }

  @override
  DateTime currentTime() => _now;
}

void main() {
  late Directory tempDir;
  late Box box;
  late DateTime now;
  late ProviderContainer container;
  late NotifierProvider<_TestStreakNotifier, StreakState> provider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wolf_lab_streak_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('streak_box');
    await box.clear();

    now = DateTime(2026, 3, 7, 10);
    provider = NotifierProvider<_TestStreakNotifier, StreakState>(
      () => _TestStreakNotifier(now),
    );
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await box.clear();
    await box.close();
    await tempDir.delete(recursive: true);
  });

  test('streak completes after three study questions in one day', () {
    final notifier = container.read(provider.notifier);

    notifier.recordStudyQuestion();
    expect(container.read(provider).currentStreak, 0);
    expect(container.read(provider).answeredToday, 1);
    expect(container.read(provider).completedToday, false);

    notifier.recordStudyQuestion();
    expect(container.read(provider).currentStreak, 0);
    expect(container.read(provider).answeredToday, 2);

    notifier.recordStudyQuestion();
    expect(container.read(provider).currentStreak, 1);
    expect(container.read(provider).answeredToday, 3);
    expect(container.read(provider).completedToday, true);
  });

  test(
    'streak increments on consecutive qualified days and resets after a skip',
    () {
      final notifier = container.read(provider.notifier);

      notifier.recordStudyQuestion();
      notifier.recordStudyQuestion();
      notifier.recordStudyQuestion();
      expect(container.read(provider).currentStreak, 1);

      now = DateTime(2026, 3, 8, 10);
      notifier.setNow(now);
      notifier.reloadFromStorage();
      notifier.recordStudyQuestion();
      notifier.recordStudyQuestion();
      notifier.recordStudyQuestion();
      expect(container.read(provider).currentStreak, 2);

      now = DateTime(2026, 3, 10, 10);
      notifier.setNow(now);
      notifier.reloadFromStorage();
      expect(container.read(provider).currentStreak, 0);
      expect(container.read(provider).completedToday, false);
    },
  );
}
