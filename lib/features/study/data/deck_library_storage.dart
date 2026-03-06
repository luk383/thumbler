import 'package:hive/hive.dart';

class DeckLibraryStorage {
  const DeckLibraryStorage();

  static const boxName = 'library_box';
  static const _activeDeckIdKey = 'active_deck_id';

  Box get _box => Hive.box(boxName);

  String? loadActiveDeckId() => _box.get(_activeDeckIdKey) as String?;

  Future<void> saveActiveDeckId(String deckId) =>
      _box.put(_activeDeckIdKey, deckId);

  Future<void> clearActiveDeckId() => _box.delete(_activeDeckIdKey);
}
