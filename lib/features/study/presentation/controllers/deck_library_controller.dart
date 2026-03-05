import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/deck_pack.dart';
import '../../data/deck_pack_service.dart';
import '../../data/study_storage.dart';
import 'study_controller.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DeckLibraryState {
  const DeckLibraryState({
    this.loadingPackId,
    this.results = const {},
  });

  /// ID of the pack currently being imported (null = idle).
  final String? loadingPackId;

  /// packId → ImportResult, populated after each import this session.
  final Map<String, ImportResult> results;

  bool isLoading(String packId) => loadingPackId == packId;
  ImportResult? resultFor(String packId) => results[packId];
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DeckLibraryNotifier extends Notifier<DeckLibraryState> {
  @override
  DeckLibraryState build() => const DeckLibraryState();

  Future<void> importPack(DeckPackMeta meta) async {
    if (state.loadingPackId != null) return; // import already in progress
    state = DeckLibraryState(
      loadingPackId: meta.id,
      results: state.results,
    );

    final pack = await DeckPack.load(meta);
    final result = const DeckPackService().importPack(pack, StudyStorage());

    // Refresh study provider so newly imported items appear immediately.
    ref.read(studyProvider.notifier).reloadFromStorage();

    state = DeckLibraryState(
      results: {...state.results, meta.id: result},
    );
  }
}

final deckLibraryProvider =
    NotifierProvider<DeckLibraryNotifier, DeckLibraryState>(
  DeckLibraryNotifier.new,
);
