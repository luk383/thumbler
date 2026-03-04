import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardState {
  const CardState({this.revealed = false, this.selectedAnswer});

  final bool revealed;
  final String? selectedAnswer;

  CardState copyWith({bool? revealed, String? selectedAnswer}) => CardState(
    revealed: revealed ?? this.revealed,
    selectedAnswer: selectedAnswer ?? this.selectedAnswer,
  );
}

class FeedState {
  const FeedState({this.cards = const {}});

  final Map<int, CardState> cards;

  CardState cardStateAt(int index) => cards[index] ?? const CardState();

  FeedState updateCard(int index, CardState updated) =>
      FeedState(cards: {...cards, index: updated});
}

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => const FeedState();

  void reveal(int index) {
    final current = state.cardStateAt(index);
    if (current.revealed) return;
    state = state.updateCard(index, current.copyWith(revealed: true));
  }

  void selectAnswer(int index, String answer) {
    final current = state.cardStateAt(index);
    if (current.selectedAnswer != null) return;
    state = state.updateCard(index, current.copyWith(selectedAnswer: answer));
  }
}

final feedProvider =
    NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
