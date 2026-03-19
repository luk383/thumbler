import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journal_storage.dart';
import '../domain/journal_entry.dart';

class JournalNotifier extends Notifier<List<JournalEntry>> {
  @override
  List<JournalEntry> build() => JournalStorage().all();

  void save(JournalEntry entry) {
    JournalStorage().save(entry);
    state = JournalStorage().all();
  }

  void delete(String id) {
    JournalStorage().delete(id);
    state = JournalStorage().all();
  }
}

final journalProvider = NotifierProvider<JournalNotifier, List<JournalEntry>>(
  JournalNotifier.new,
);
