import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/deck_library_storage.dart';
import '../../data/deck_pack.dart';
import '../../data/deck_pack_service.dart';
import '../../data/study_storage.dart';
import '../../domain/study_item.dart';

class DeckLibraryState {
  const DeckLibraryState({
    this.packs = const [],
    this.activeDeckId,
    this.loadingPackId,
    this.results = const {},
    this.isDiscovering = false,
    this.lastError,
    this.dataVersion = 0,
  });

  final List<DeckPackMeta> packs;
  final String? activeDeckId;
  final String? loadingPackId;
  final Map<String, ImportResult> results;
  final bool isDiscovering;
  final String? lastError;
  final int dataVersion;

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
      dataVersion: state.dataVersion,
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
        dataVersion: state.dataVersion,
      );
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
        dataVersion: state.dataVersion,
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
    state = DeckLibraryState(
      packs: state.packs,
      activeDeckId: state.activeDeckId,
      loadingPackId: null,
      results: {...state.results, meta.id: result},
      isDiscovering: state.isDiscovering,
      lastError: null,
      dataVersion: state.dataVersion + 1,
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
      dataVersion: state.dataVersion,
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
        dataVersion: state.dataVersion,
      );
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
        dataVersion: state.dataVersion,
      );
      rethrow;
    }
  }

  Future<void> deleteUserDeck(String deckId) async {
    await _storage.deleteUserDeck(deckId);
    // If we just deleted the active deck, clear the active selection
    String? nextActiveDeckId = state.activeDeckId;
    if (nextActiveDeckId == deckId) {
      await _storage.clearActiveDeckId();
      nextActiveDeckId = null;
    }
    await discoverPacks();
  }

  /// Creates a copy of [deckId] with a new ID and fresh progress stats.
  Future<String> cloneDeck(String sourceDeckId, {String? newTitle}) async {
    final storage = StudyStorage();
    final sourceItems = storage.allForDeck(sourceDeckId);
    if (sourceItems.isEmpty) throw FormatException('Deck "$sourceDeckId" è vuoto.');

    final newDeckId =
        '${sourceDeckId}_clone_${DateTime.now().millisecondsSinceEpoch}';
    final clonedItems = sourceItems.map((item) {
      return StudyItem(
        id: '${item.id}_clone',
        deckId: newDeckId,
        contentType: item.contentType,
        category: item.category,
        topic: item.topic,
        subtopic: item.subtopic,
        objectiveId: item.objectiveId,
        promptText: item.promptText,
        explanationText: item.explanationText,
        options: item.options,
        correctAnswerIndex: item.correctAnswerIndex,
        difficulty: item.difficulty,
        userNote: item.userNote,
        // Progress reset
        easeFactor: 2.5,
        srsInterval: 0,
        srsRepetitions: 0,
      );
    }).toList(growable: false);

    for (final item in clonedItems) {
      storage.add(item);
    }

    // Persist a user-deck JSON entry so it shows in library
    final sourcePack = state.packs
        .cast<DeckPackMeta?>()
        .firstWhere((p) => p?.id == sourceDeckId, orElse: () => null);
    final sourceJson = _storage.loadUserDeckJson(sourceDeckId);
    if (sourceJson != null) {
      final decoded = sourceJson.replaceFirst(
        '"id": "$sourceDeckId"',
        '"id": "$newDeckId"',
      );
      final titled = newTitle != null
          ? decoded.replaceFirst(
              RegExp(r'"title":\s*"[^"]*"'),
              '"title": "$newTitle"',
            )
          : decoded;
      await _storage.saveUserDeckJson(newDeckId, titled);
    } else {
      // Fallback: build minimal JSON
      final title = newTitle ??
          (sourcePack?.title != null ? '${sourcePack!.title} (copia)' : '$sourceDeckId (copia)');
      final minimalJson = '{"id":"$newDeckId","title":"$title","category":"Importato","description":"","questions":[]}';
      await _storage.saveUserDeckJson(newDeckId, minimalJson);
    }

    await discoverPacks();
    return newDeckId;
  }

  /// Copies all cards from [sourceDeckId] into [targetDeckId] (skipping duplicates by ID).
  Future<int> mergeDeck({
    required String sourceDeckId,
    required String targetDeckId,
  }) async {
    if (sourceDeckId == targetDeckId) return 0;
    final storage = StudyStorage();
    final sourceItems = storage.allForDeck(sourceDeckId);
    final targetItems = storage.allForDeck(targetDeckId);
    final existingIds = {for (final i in targetItems) i.id};

    var added = 0;
    for (final item in sourceItems) {
      final mergedId = '${targetDeckId}_${item.id}';
      if (existingIds.contains(mergedId) || existingIds.contains(item.id)) {
        continue;
      }
      storage.add(StudyItem(
        id: mergedId,
        deckId: targetDeckId,
        contentType: item.contentType,
        category: item.category,
        topic: item.topic,
        subtopic: item.subtopic,
        objectiveId: item.objectiveId,
        promptText: item.promptText,
        explanationText: item.explanationText,
        options: item.options,
        correctAnswerIndex: item.correctAnswerIndex,
        difficulty: item.difficulty,
        userNote: item.userNote,
        easeFactor: 2.5,
        srsInterval: 0,
        srsRepetitions: 0,
      ));
      added++;
    }

    state = DeckLibraryState(
      packs: state.packs,
      activeDeckId: state.activeDeckId,
      loadingPackId: null,
      results: state.results,
      isDiscovering: false,
      lastError: null,
      dataVersion: state.dataVersion + 1,
    );
    return added;
  }

  Future<void> chooseDeckForInterests(List<String> interests) async {
    if (interests.isEmpty) {
      if (state.activeDeckId == null) {
        await discoverPacks();
      }
      return;
    }

    var packs = state.packs;
    if (packs.isEmpty) {
      await discoverPacks();
      packs = state.packs;
    }

    final importable = packs.where((pack) => pack.isImportable).toList();
    if (importable.isEmpty) return;

    final rankedCandidates = [
      ...importable.where((pack) => pack.supportsFeed),
      ...importable.where((pack) => !pack.supportsFeed),
    ];

    final interestKeywords = {
      for (final interest in interests) interest: _interestKeywords(interest),
    };

    DeckPackMeta? bestMatch;
    var bestScore = -1;
    for (final pack in rankedCandidates) {
      final haystack = [
        pack.title,
        pack.category ?? '',
        pack.examCode ?? '',
        ...pack.domains,
      ].join(' ').toLowerCase();

      var score = 0;
      if (pack.supportsFeed) score += 2;
      if (pack.librarySection == 'General Knowledge') score += 1;
      for (final keywords in interestKeywords.values) {
        if (keywords.any(haystack.contains)) {
          score += 2;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = pack;
      }
    }

    if (bestMatch == null) return;
    if (state.activeDeckId == bestMatch.id) return;
    await setActiveDeck(bestMatch);
  }

  String? _defaultDeckId(List<DeckPackMeta> packs) {
    final validDecks = packs.where((pack) => !pack.hasInvalidJson && pack.hasQuestions).toList();
    if (validDecks.isEmpty) return null;

    final preferredGeneralDecks =
        validDecks
            .where(
              (pack) =>
                  pack.librarySection == 'General Knowledge' &&
                  pack.supportsFeed,
            )
            .toList()
          ..sort((a, b) {
            final preferredIds = [
              'general_knowledge_daily',
              'technology_basics_daily',
              'basic_science_daily',
              'world_history_daily',
            ];
            final aIndex = preferredIds.indexOf(a.id);
            final bIndex = preferredIds.indexOf(b.id);
            if (aIndex != -1 || bIndex != -1) {
              if (aIndex == -1) return 1;
              if (bIndex == -1) return -1;
              return aIndex.compareTo(bIndex);
            }
            final byQuestions = b.questionCount.compareTo(a.questionCount);
            if (byQuestions != 0) return byQuestions;
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          });
    if (preferredGeneralDecks.isNotEmpty) return preferredGeneralDecks.first.id;

    if (validDecks.length == 1) return validDecks.first.id;
    return validDecks.first.id;
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

List<String> _interestKeywords(String interest) {
  switch (interest.toLowerCase()) {
    case 'cybersecurity':
      return const ['security', 'cyber', 'linux', 'threat'];
    case 'cloud':
      return const ['cloud', 'aws', 'architecture'];
    case 'technology':
      return const ['technology', 'computer', 'internet', 'ai', 'network'];
    case 'science':
      return const ['science', 'physics', 'chemistry', 'biology', 'astronomy'];
    case 'history':
      return const ['history', 'civilization', 'medieval', 'modern'];
  }
  return [interest.toLowerCase()];
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

final deckLibraryDataVersionProvider = Provider<int>(
  (ref) => ref.watch(deckLibraryProvider.select((state) => state.dataVersion)),
);

class DeckProgressSummary {
  const DeckProgressSummary({
    required this.deckId,
    this.totalItems = 0,
    this.reviewedItems = 0,
  });

  final String deckId;
  final int totalItems;
  final int reviewedItems;

  bool get hasImportedItems => totalItems > 0;
  bool get hasProgress => reviewedItems > 0;
}

final deckProgressSummariesProvider =
    Provider<Map<String, DeckProgressSummary>>((ref) {
      ref.watch(deckLibraryProvider);

      final items = StudyStorage().all();
      final grouped = <String, List<StudyItem>>{};
      for (final item in items) {
        final deckId = item.deckId;
        if (deckId == null || deckId.trim().isEmpty) continue;
        grouped.putIfAbsent(deckId, () => []).add(item);
      }

      return grouped.map((deckId, deckItems) {
        final reviewedItems = deckItems
            .where((item) => item.timesSeen > 0)
            .length;
        return MapEntry(
          deckId,
          DeckProgressSummary(
            deckId: deckId,
            totalItems: deckItems.length,
            reviewedItems: reviewedItems,
          ),
        );
      });
    });
