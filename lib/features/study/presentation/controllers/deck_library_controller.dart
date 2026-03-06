import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/deck_library_storage.dart';
import '../../data/deck_pack.dart';
import '../../data/deck_pack_service.dart';
import '../../data/study_storage.dart';
import '../../../exam/presentation/controllers/exam_controller.dart';
import 'study_controller.dart';

class DeckLibraryState {
  const DeckLibraryState({
    this.packs = const [],
    this.activeDeckId,
    this.loadingPackId,
    this.results = const {},
    this.isDiscovering = false,
    this.lastError,
  });

  final List<DeckPackMeta> packs;
  final String? activeDeckId;
  final String? loadingPackId;
  final Map<String, ImportResult> results;
  final bool isDiscovering;
  final String? lastError;

  DeckPackMeta? get activeDeck {
    if (activeDeckId == null) return null;
    for (final pack in packs) {
      if (pack.id == activeDeckId) return pack;
    }
    return null;
  }

  bool isLoading(String packId) => loadingPackId == packId;
  bool isActive(String packId) => activeDeckId == packId;
  ImportResult? resultFor(String packId) => results[packId];
}

class DeckLibraryNotifier extends Notifier<DeckLibraryState> {
  final _storage = const DeckLibraryStorage();

  @override
  DeckLibraryState build() {
    Future.microtask(discoverPacks);
    return DeckLibraryState(activeDeckId: _storage.loadActiveDeckId());
  }

  Future<void> discoverPacks() async {
    state = DeckLibraryState(
      packs: state.packs,
      activeDeckId: state.activeDeckId,
      loadingPackId: state.loadingPackId,
      results: state.results,
      isDiscovering: true,
      lastError: null,
    );

    try {
      final packs = await DeckPackMeta.discoverLocalPacks();
      var activeDeckId = _storage.loadActiveDeckId();

      final hasActive =
          activeDeckId != null && packs.any((pack) => pack.id == activeDeckId);
      if (!hasActive) {
        activeDeckId = _defaultDeckId(packs);
        if (activeDeckId != null) {
          await _storage.saveActiveDeckId(activeDeckId);
          await _ensureDeckImportedById(activeDeckId, packs);
        }
      }

      state = DeckLibraryState(
        packs: packs,
        activeDeckId: activeDeckId,
        loadingPackId: null,
        results: state.results,
        isDiscovering: false,
      );

      ref.read(studyProvider.notifier).reloadFromStorage();
      ref.read(examProvider.notifier).resetAfterDataChange();
    } catch (e, st) {
      debugPrint('Deck discovery failed: $e');
      debugPrintStack(stackTrace: st);
      state = DeckLibraryState(
        packs: state.packs,
        activeDeckId: state.activeDeckId,
        loadingPackId: null,
        results: state.results,
        isDiscovering: false,
        lastError: e.toString(),
      );
    }
  }

  Future<ImportResult> importPack(DeckPackMeta meta) async {
    if (!meta.isImportable) {
      throw FormatException(
        meta.invalidJsonMessage ??
            meta.availabilityNote ??
            'This pack is not ready to import.',
      );
    }
    final pack = await DeckPack.load(meta);
    final result = const DeckPackService().importPack(pack, StudyStorage());
    ref.read(studyProvider.notifier).reloadFromStorage();
    ref.read(examProvider.notifier).resetAfterDataChange();
    state = DeckLibraryState(
      packs: state.packs,
      activeDeckId: state.activeDeckId,
      loadingPackId: null,
      results: {...state.results, meta.id: result},
      isDiscovering: state.isDiscovering,
      lastError: null,
    );
    return result;
  }

  Future<void> setActiveDeck(DeckPackMeta meta) async {
    if (state.loadingPackId != null) return;
    state = DeckLibraryState(
      packs: state.packs,
      activeDeckId: state.activeDeckId,
      loadingPackId: meta.id,
      results: state.results,
      isDiscovering: state.isDiscovering,
      lastError: null,
    );

    try {
      final result = await importPack(meta);
      await _storage.saveActiveDeckId(meta.id);
      state = DeckLibraryState(
        packs: state.packs,
        activeDeckId: meta.id,
        loadingPackId: null,
        results: {...state.results, meta.id: result},
        isDiscovering: state.isDiscovering,
        lastError: null,
      );
      ref.read(studyProvider.notifier).reloadFromStorage();
      ref.read(examProvider.notifier).resetAfterDataChange();
    } catch (e, st) {
      debugPrint('Set active deck failed (${meta.id}): $e');
      debugPrintStack(stackTrace: st);
      state = DeckLibraryState(
        packs: state.packs,
        activeDeckId: state.activeDeckId,
        loadingPackId: null,
        results: state.results,
        isDiscovering: state.isDiscovering,
        lastError: e.toString(),
      );
      rethrow;
    }
  }

  String? _defaultDeckId(List<DeckPackMeta> packs) {
    final importable = packs.where((pack) => pack.isImportable).toList();
    if (importable.isEmpty) return null;

    final securityPacks =
        importable
            .where(
              (pack) =>
                  pack.id.toLowerCase().contains('sec701') ||
                  pack.assetPath.toLowerCase().contains('sec701') ||
                  pack.examCode == 'SY0-701',
            )
            .toList()
          ..sort((a, b) => b.questionCount.compareTo(a.questionCount));
    if (securityPacks.isNotEmpty) return securityPacks.first.id;
    if (importable.length == 1) return importable.first.id;
    return importable.first.id;
  }

  Future<void> _ensureDeckImportedById(
    String deckId,
    List<DeckPackMeta> packs,
  ) async {
    final meta = packs.cast<DeckPackMeta?>().firstWhere(
      (pack) => pack?.id == deckId,
      orElse: () => null,
    );
    if (meta == null) return;
    await importPack(meta);
  }
}

final deckLibraryProvider =
    NotifierProvider<DeckLibraryNotifier, DeckLibraryState>(
      DeckLibraryNotifier.new,
    );

final activeDeckIdProvider = Provider<String?>(
  (ref) => ref.watch(deckLibraryProvider.select((state) => state.activeDeckId)),
);

final activeDeckMetaProvider = Provider<DeckPackMeta?>(
  (ref) => ref.watch(deckLibraryProvider.select((state) => state.activeDeck)),
);
