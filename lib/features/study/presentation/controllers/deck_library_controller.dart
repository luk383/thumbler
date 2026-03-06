import 'package:flutter/foundation.dart';
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
    this.packs = const [],
    this.loadingPackId,
    this.results = const {},
    this.isDiscovering = false,
    this.lastError,
  });

  final List<DeckPackMeta> packs;

  /// ID of the pack currently being imported (null = idle).
  final String? loadingPackId;

  /// packId → ImportResult, populated after each import this session.
  final Map<String, ImportResult> results;
  final bool isDiscovering;
  final String? lastError;

  bool isLoading(String packId) => loadingPackId == packId;
  ImportResult? resultFor(String packId) => results[packId];
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DeckLibraryNotifier extends Notifier<DeckLibraryState> {
  @override
  DeckLibraryState build() {
    Future.microtask(discoverPacks);
    return const DeckLibraryState();
  }

  Future<void> discoverPacks() async {
    state = DeckLibraryState(
      packs: state.packs,
      loadingPackId: state.loadingPackId,
      results: state.results,
      isDiscovering: true,
      lastError: null,
    );

    try {
      final packs = await DeckPackMeta.discoverLocalPacks();
      state = DeckLibraryState(
        packs: packs,
        loadingPackId: state.loadingPackId,
        results: state.results,
        isDiscovering: false,
      );
    } catch (e, st) {
      debugPrint('Deck discovery failed: $e');
      debugPrintStack(stackTrace: st);
      state = DeckLibraryState(
        packs: state.packs,
        loadingPackId: state.loadingPackId,
        results: state.results,
        isDiscovering: false,
        lastError: e.toString(),
      );
    }
  }

  void printDiscoveredPacks() {
    for (final p in state.packs) {
      debugPrint('[deck] ${p.assetPath}');
    }
  }

  Future<void> importPack(DeckPackMeta meta) async {
    if (state.loadingPackId != null) return; // import already in progress
    state = DeckLibraryState(
      packs: state.packs,
      loadingPackId: meta.id,
      results: state.results,
      isDiscovering: state.isDiscovering,
      lastError: null,
    );

    try {
      final pack = await DeckPack.load(meta);
      final result = const DeckPackService().importPack(pack, StudyStorage());

      // Refresh study provider so newly imported items appear immediately.
      ref.read(studyProvider.notifier).reloadFromStorage();
      // Refresh count preview after import if needed.
      await discoverPacks();

      state = DeckLibraryState(
        packs: state.packs,
        results: {...state.results, meta.id: result},
        isDiscovering: state.isDiscovering,
      );
    } catch (e, st) {
      debugPrint('Deck import failed (${meta.assetPath}): $e');
      debugPrintStack(stackTrace: st);
      state = DeckLibraryState(
        packs: state.packs,
        results: state.results,
        isDiscovering: state.isDiscovering,
        lastError: e.toString(),
      );
      rethrow;
    }
  }
}

final deckLibraryProvider =
    NotifierProvider<DeckLibraryNotifier, DeckLibraryState>(
      DeckLibraryNotifier.new,
    );
