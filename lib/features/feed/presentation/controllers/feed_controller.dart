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

  final Map<String, CardState> cards;

  CardState cardStateFor(String lessonId) => cards[lessonId] ?? const CardState();

  FeedState updateCard(String lessonId, CardState updated) =>
      FeedState(cards: {...cards, lessonId: updated});
}

class FeedNotifier extends Notifier<FeedState> {
  @override
  FeedState build() => const FeedState();

  void reset() {
    state = const FeedState();
  }

  void reveal(String lessonId) {
    final current = state.cardStateFor(lessonId);
    if (current.revealed) return;
    state = state.updateCard(lessonId, current.copyWith(revealed: true));
  }

  void selectAnswer(String lessonId, String answer) {
    final current = state.cardStateFor(lessonId);
    if (current.selectedAnswer != null) return;
    state = state.updateCard(lessonId, current.copyWith(selectedAnswer: answer));
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);
