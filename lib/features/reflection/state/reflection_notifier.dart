import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reflection_storage.dart';
import '../domain/reflection_entry.dart';

class ReflectionNotifier extends Notifier<List<ReflectionEntry>> {
  @override
  List<ReflectionEntry> build() => ReflectionStorage().all();

  void saveEntry(ReflectionEntry entry) {
    ReflectionStorage().save(entry);
    state = ReflectionStorage().all();
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
