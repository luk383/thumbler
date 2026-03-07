import 'package:flutter_test/flutter_test.dart';
import 'package:thumbler/features/study/data/deck_pack.dart';
import 'package:thumbler/features/study/data/user_deck_service.dart';
import 'package:thumbler/features/study/domain/user_deck_draft.dart';

void main() {
  const service = UserDeckService();

  test(
    'normalizes a minimal imported JSON deck into app-compatible format',
    () {
      final draft = service.normalizeImportedJson('''
      {
        "id": "custom_import",
        "title": "Imported Deck",
        "questions": [
          {
            "question": "What is IAM?",
            "answers": ["Identity service", "Storage", "CDN", "Database"],
            "correctIndex": 0
          }
        ]
      }
      ''', fallbackCategory: 'Imported');

      final raw = draft.toNormalizedJson();
      final pack = DeckPack.parseJsonString(
        raw,
        assetPath: 'user://${draft.id}',
      );

      expect(pack.meta.title, 'Imported Deck');
      expect(pack.meta.questionCount, 1);
      expect(pack.items.single.options, hasLength(4));
    },
  );

  test(
    'draft validation requires title, category, and valid question shape',
    () {
      final draft = UserDeckDraft(
        id: 'draft',
        title: '',
        category: '',
        questions: [
          UserDeckQuestionDraft(
            question: '',
            answers: const ['', '', '', ''],
            correctIndex: 0,
          ),
        ],
      );

      expect(draft.validate(), isNotEmpty);
    },
  );

  test('generates quiz questions from study text', () {
    final draft = service.generateFromText(
      title: 'OSI Notes',
      category: 'Networking',
      sourceText: '''
        The physical layer is responsible for raw bit transmission.
        The data link layer is responsible for node-to-node delivery.
        The network layer is responsible for routing packets between networks.
        The transport layer is responsible for end-to-end communication.
        The application layer is responsible for network services for users.
      ''',
      maxQuestions: 5,
    );

    expect(draft.questions.length, greaterThanOrEqualTo(4));
    expect(draft.questions.first.answers, hasLength(4));
  });
}
