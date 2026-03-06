import 'deck_pack.dart';
import 'study_storage.dart';

/// Handles importing a [DeckPack] into the local Hive study deck.
class DeckPackService {
  const DeckPackService();

  /// Imports all items from [pack] into [storage], skipping duplicates by id.
  ImportResult importPack(DeckPack pack, StudyStorage storage) {
    int added = 0, updated = 0, skipped = 0;
    final seenInPack = <String>{};

    for (final item in pack.items) {
      if (!seenInPack.add(item.id)) {
        skipped++;
        continue;
      }

      final nextItem = item.toStudyItem(pack.meta.id);
      final existing =
          storage.getById(item.id, deckId: pack.meta.id) ??
          storage.getById(item.id);
      if (existing == null) {
        storage.add(nextItem);
        added++;
        continue;
      }

      storage.update(
        nextItem.copyWith(
          againCount: existing.againCount,
          goodCount: existing.goodCount,
          timesSeen: existing.timesSeen,
          correctCount: existing.correctCount,
          wrongCount: existing.wrongCount,
          avgTimeMs: existing.avgTimeMs,
          nextReviewAt: existing.nextReviewAt,
          lastReviewedAt: existing.lastReviewedAt,
        ),
      );
      updated++;
    }

    return ImportResult(added: added, updated: updated, skipped: skipped);
  }
}
