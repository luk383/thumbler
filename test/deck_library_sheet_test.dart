import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thumbler/features/study/data/deck_pack.dart';
import 'package:thumbler/features/study/presentation/controllers/deck_library_controller.dart';
import 'package:thumbler/features/study/presentation/widgets/deck_library_sheet.dart';

void main() {
  testWidgets('featured excludes active deck already shown in continue learning', (
    tester,
  ) async {
    const linuxDeck = DeckPackMeta(
      id: 'linux_essentials_010_160',
      assetPath: 'assets/decks/linux_essentials_010_160.json',
      title: 'Linux Essentials',
      category: 'Linux Administration',
      examCode: '010-160',
      description: 'Linux certification deck',
      questionCount: 25,
      domains: ['Linux'],
      examQuestionCount: 25,
      microCardCount: 0,
      isStarter: false,
      availabilityNote: null,
      invalidJsonMessage: null,
    );
    const securityDeck = DeckPackMeta(
      id: 'comptia_security_plus_sy0_701_pack_20',
      assetPath: 'assets/decks/sec701_exam_pack_20.json',
      title: 'CompTIA Security+ Pack 20',
      category: 'Cybersecurity',
      examCode: 'SY0-701',
      description: 'Security+ deck',
      questionCount: 20,
      domains: ['Security'],
      examQuestionCount: 20,
      microCardCount: 0,
      isStarter: false,
      availabilityNote: null,
      invalidJsonMessage: null,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckLibraryProvider.overrideWith(
            () => _FakeDeckLibraryNotifier(
              const DeckLibraryState(
                packs: [linuxDeck, securityDeck],
                activeDeckId: 'linux_essentials_010_160',
              ),
            ),
          ),
          deckProgressSummariesProvider.overrideWithValue(
            const {
              'linux_essentials_010_160': DeckProgressSummary(
                deckId: 'linux_essentials_010_160',
                totalItems: 25,
                reviewedItems: 3,
              ),
            },
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: DeckLibrarySheet())),
      ),
    );

    await tester.pumpAndSettle();

    final libraryText = find.text('Linux Essentials');
    expect(libraryText, findsOneWidget);
    expect(find.text('CompTIA Security+ Pack 20'), findsOneWidget);
  });
}

class _FakeDeckLibraryNotifier extends DeckLibraryNotifier {
  _FakeDeckLibraryNotifier(this._state);

  final DeckLibraryState _state;

  @override
  DeckLibraryState build() => _state;
}
