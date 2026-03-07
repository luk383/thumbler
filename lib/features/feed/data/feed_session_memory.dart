class FeedSessionMemory {
  FeedSessionMemory({this.maxRememberedIds = 24, this.rememberTopCount = 8});

  final int maxRememberedIds;
  final int rememberTopCount;
  final Map<String, List<String>> _recentByDeck = {};

  List<String> recentIdsForDeck(String? deckId) {
    return List.unmodifiable(
      _recentByDeck[_deckKey(deckId)] ?? const <String>[],
    );
  }

  void rememberSelection(String? deckId, List<String> lessonIds) {
    if (lessonIds.isEmpty) return;

    final key = _deckKey(deckId);
    final existing = [...(_recentByDeck[key] ?? const <String>[])];
    final incoming = lessonIds.take(rememberTopCount);

    for (final id in incoming) {
      existing.remove(id);
      existing.add(id);
    }

    if (existing.length > maxRememberedIds) {
      existing.removeRange(0, existing.length - maxRememberedIds);
    }

    _recentByDeck[key] = existing;
  }

  String _deckKey(String? deckId) => deckId ?? '__no_deck__';
}
