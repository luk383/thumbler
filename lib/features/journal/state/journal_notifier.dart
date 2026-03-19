import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../growth/xp/xp_notifier.dart';
import '../data/journal_storage.dart';
import '../domain/journal_entry.dart';

class JournalNotifier extends Notifier<List<JournalEntry>> {
  @override
  List<JournalEntry> build() => JournalStorage().all();

  void save(JournalEntry entry) {
    final isNew = !state.any((e) => e.id == entry.id);
    JournalStorage().save(entry);
    state = JournalStorage().all();
    if (isNew) ref.read(xpProvider.notifier).addXp(XpEvent.journalEntry);
  }

  void delete(String id) {
    JournalStorage().delete(id);
    state = JournalStorage().all();
  }
}

final journalProvider = NotifierProvider<JournalNotifier, List<JournalEntry>>(
  JournalNotifier.new,
);
