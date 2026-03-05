import 'deck_pack.dart';
import 'study_storage.dart';

/// Handles importing a [DeckPack] into the local Hive study deck.
class DeckPackService {
  const DeckPackService();

  /// Imports all items from [pack] into [storage], skipping duplicates by id.
  ImportResult importPack(DeckPack pack, StudyStorage storage) {
    int added = 0, skipped = 0;
    for (final item in pack.items) {
      if (storage.contains(item.id)) {
        skipped++;
        continue;
      }
      storage.add(item.toStudyItem());
      added++;
    }
    return ImportResult(added: added, skipped: skipped);
  }
}
