import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../growth/xp/xp_notifier.dart';
import '../data/reflection_storage.dart';
import '../domain/reflection_entry.dart';

class ReflectionNotifier extends Notifier<List<ReflectionEntry>> {
  @override
  List<ReflectionEntry> build() => ReflectionStorage().all();

  void saveEntry(ReflectionEntry entry) {
    final existing = ReflectionStorage().forWeek(entry.weekStart);
    final wasEmpty = existing == null || existing.isEmpty;
    ReflectionStorage().save(entry);
    state = ReflectionStorage().all();
    // Award XP only on first save of this week's reflection
    if (wasEmpty && !entry.isEmpty) {
      ref.read(xpProvider.notifier).addXp(XpEvent.weeklyReflection);
    }
  }

  ReflectionEntry currentWeekEntry() {
    final ws = ReflectionEntry.currentWeekStart();
    return ReflectionStorage().forWeek(ws) ??
        ReflectionEntry(
          id: 'ref_${ws.millisecondsSinceEpoch}',
          weekStart: ws,
          createdAt: DateTime.now(),
        );
  }
}

final reflectionProvider =
    NotifierProvider<ReflectionNotifier, List<ReflectionEntry>>(
  ReflectionNotifier.new,
);
