import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../growth/xp/xp_notifier.dart';
import '../data/reading_storage.dart';
import '../domain/reading_item.dart';

class ReadingNotifier extends Notifier<List<ReadingItem>> {
  @override
  List<ReadingItem> build() => ReadingStorage().all();

  void save(ReadingItem item) {
    ReadingStorage().save(item);
    state = ReadingStorage().all();
  }

  void setStatus(String id, ReadingStatus status) {
    final item = state.firstWhere((i) => i.id == id);
    final wasNotCompleted = item.status != ReadingStatus.completed;
    ReadingStorage().save(item.copyWith(
      status: status,
      startedAt: status == ReadingStatus.reading && item.startedAt == null
          ? DateTime.now()
          : null,
      completedAt:
          status == ReadingStatus.completed ? DateTime.now() : null,
    ));
    state = ReadingStorage().all();
    // Award XP when marking as completed for the first time
    if (status == ReadingStatus.completed && wasNotCompleted) {
      ref.read(xpProvider.notifier).addXp(XpEvent.bookCompleted);
    }
  }

  void updateProgress(String id, int currentPage) {
    final item = state.firstWhere((i) => i.id == id);
    ReadingStorage().save(item.copyWith(currentPage: currentPage));
    state = ReadingStorage().all();
  }

  void delete(String id) {
    ReadingStorage().delete(id);
    state = ReadingStorage().all();
  }
}

final readingProvider = NotifierProvider<ReadingNotifier, List<ReadingItem>>(
  ReadingNotifier.new,
);
