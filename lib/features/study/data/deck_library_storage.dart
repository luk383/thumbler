import 'package:hive/hive.dart';

class DeckLibraryStorage {
  const DeckLibraryStorage();

  static const boxName = 'library_box';
  static const _activeDeckIdKey = 'active_deck_id';
  static const _userDeckPrefix = 'user_deck::';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _onboardingInterestsKey = 'onboarding_interests';
  static const _preferredLanguageCodeKey = 'preferred_language_code';
  static const _themeModeKey = 'theme_mode';

  Box get _box => Hive.box(boxName);

  String? loadActiveDeckId() => _box.get(_activeDeckIdKey) as String?;

  Future<void> saveActiveDeckId(String deckId) =>
      _box.put(_activeDeckIdKey, deckId);

  Future<void> clearActiveDeckId() => _box.delete(_activeDeckIdKey);

  Future<void> saveUserDeckJson(String deckId, String rawJson) =>
      _box.put('$_userDeckPrefix$deckId', rawJson);

  String? loadUserDeckJson(String deckId) =>
      _box.get('$_userDeckPrefix$deckId') as String?;

  Map<String, String> loadAllUserDeckJson() {
    final entries = <String, String>{};
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith(_userDeckPrefix)) continue;
      final value = _box.get(key);
      if (value is! String) continue;
      final deckId = key.substring(_userDeckPrefix.length);
      entries[deckId] = value;
    }
    return entries;
  }

  Future<void> deleteUserDeck(String deckId) =>
      _box.delete('$_userDeckPrefix$deckId');

  bool isOnboardingComplete() =>
      (_box.get(_onboardingCompleteKey, defaultValue: false) as bool?) ?? false;

  Future<void> saveOnboardingComplete(bool complete) =>
      _box.put(_onboardingCompleteKey, complete);

  List<String> loadOnboardingInterests() {
    final raw = _box.get(_onboardingInterestsKey);
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  Future<void> saveOnboardingInterests(List<String> interests) =>
      _box.put(_onboardingInterestsKey, interests);

  String? loadPreferredLanguageCode() =>
      _box.get(_preferredLanguageCodeKey) as String?;

  Future<void> savePreferredLanguageCode(String code) =>
      _box.put(_preferredLanguageCodeKey, code);

  String? loadThemeMode() => _box.get(_themeModeKey) as String?;

  Future<void> saveThemeMode(String mode) => _box.put(_themeModeKey, mode);
}
