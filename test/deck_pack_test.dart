import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thumbler/features/study/data/deck_pack.dart';

void main() {
  test('parses standardized questions-based deck format', () {
    const raw = '''
{
  "id": "sec-plus",
  "title": "Security+",
  "examCode": "SY0-701",
  "category": "Cybersecurity",
  "description": "Practice deck",
  "version": "1",
  "domains": ["General Security Concepts"],
  "defaultContentType": "exam_question",
  "questions": [
    {
      "id": "q1",
      "domain": "General Security Concepts",
      "topic": "CIA Triad",
      "question": "Which principle keeps systems accessible?",
      "answers": ["Confidentiality", "Integrity", "Availability"],
      "correctIndex": 2,
      "explanation": "Availability keeps systems reachable."
    }
  ]
}
''';

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath: 'assets/decks/security_plus.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/security_plus.json',
    );

    expect(meta.id, 'sec-plus');
    expect(meta.title, 'Security+');
    expect(meta.examCode, 'SY0-701');
    expect(meta.questionCount, 1);
    expect(meta.examQuestionCount, 1);
    expect(meta.domains, contains('General Security Concepts'));
    expect(deck.items.single.category, 'General Security Concepts');
    expect(
      deck.items.single.promptText,
      'Which principle keeps systems accessible?',
    );
    expect(deck.items.single.correctAnswerIndex, 2);
    expect(deck.items.single.contentType, 'exam_question');
  });

  test('parses legacy wrapped items format', () {
    const raw = '''
{
  "id": "starter_pack_v1",
  "name": "Starter Pack",
  "description": "Legacy wrapper",
  "version": 1,
  "items": [
    {
      "id": "sp_001",
      "contentType": "micro_card",
      "category": "Technology",
      "promptText": "Prompt",
      "explanationText": "Explanation",
      "options": ["A", "B"],
      "correctAnswerIndex": 0
    }
  ]
}
''';

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath: 'assets/decks/starter_pack.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/starter_pack.json',
    );

    expect(meta.title, 'Starter Pack');
    expect(meta.microCardCount, 1);
    expect(deck.items.single.contentType, 'micro_card');
    expect(deck.items.single.explanationText, 'Explanation');
  });

  test('parses legacy raw array Security+ format', () {
    const raw = '''
[
  {
    "id": "sec701_exam_001",
    "contentType": "exam_question",
    "category": "General Security Concepts",
    "topic": "CIA Triad",
    "promptText": "Which principle ensures access?",
    "options": ["Confidentiality", "Integrity", "Availability"],
    "correctAnswerIndex": 2
  }
]
''';

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath: 'assets/decks/sec701_exam_pack_20.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/sec701_exam_pack_20.json',
    );

    expect(meta.examCode, 'SY0-701');
    expect(meta.examQuestionCount, 1);
    expect(meta.title, 'Sec701 Exam Pack 20');
    expect(deck.items.single.category, 'General Security Concepts');
    expect(deck.items.single.contentType, 'exam_question');
  });

  test('rejects standardized deck missing title metadata', () {
    const raw = '''
{
  "id": "broken_pack",
  "questions": [
    {
      "id": "q1",
      "domain": "Security",
      "question": "Prompt?",
      "answers": ["A", "B"],
      "correctIndex": 0
    }
  ]
}
''';

    expect(
      () => DeckPackMeta.inspectJsonString(
        raw,
        assetPath: 'assets/decks/broken_pack.json',
      ),
      throwsFormatException,
    );
  });

  test('rejects non-starter deck with empty questions list', () {
    const raw = '''
{
  "id": "empty_pack",
  "title": "Empty Pack",
  "questions": []
}
''';

    expect(
      () => DeckPackMeta.inspectJsonString(
        raw,
        assetPath: 'assets/decks/empty_pack.json',
      ),
      throwsFormatException,
    );
  });

  test(
    'allows starter deck with empty questions list when availability note exists',
    () {
      const raw = '''
{
  "id": "starter_only",
  "title": "Starter Only",
  "isStarter": true,
  "availabilityNote": "Coming later",
  "questions": []
}
''';

      final meta = DeckPackMeta.inspectJsonString(
        raw,
        assetPath: 'assets/decks/starter_only.json',
      );

      expect(meta.isStarter, true);
      expect(meta.questionCount, 0);
      expect(meta.librarySection, 'General Knowledge');
    },
  );

  test('classifies certification and general knowledge deck sections', () {
    const certificationRaw = '''
{
  "id": "security_plus",
  "title": "Security+",
  "examCode": "SY0-701",
  "questions": [
    {
      "id": "q1",
      "domain": "Security",
      "question": "Prompt?",
      "answers": ["A", "B"],
      "correctIndex": 0
    }
  ]
}
''';

    const generalKnowledgeRaw = '''
{
  "id": "history_starter",
  "title": "World History",
  "category": "General Knowledge",
  "isStarter": true,
  "availabilityNote": "Coming later",
  "questions": []
}
''';

    final certificationMeta = DeckPackMeta.inspectJsonString(
      certificationRaw,
      assetPath: 'assets/decks/security_plus.json',
    );
    final generalKnowledgeMeta = DeckPackMeta.inspectJsonString(
      generalKnowledgeRaw,
      assetPath: 'assets/decks/world_history_starter.json',
    );

    expect(certificationMeta.librarySection, 'Certifications');
    expect(generalKnowledgeMeta.librarySection, 'General Knowledge');
  });

  test('rejects invalid question answer shape and duplicate ids', () {
    const duplicateIds = '''
{
  "id": "dup_pack",
  "title": "Duplicate Pack",
  "questions": [
    {
      "id": "q1",
      "domain": "Security",
      "question": "Prompt 1?",
      "answers": ["A", "B"],
      "correctIndex": 0
    },
    {
      "id": "q1",
      "domain": "Security",
      "question": "Prompt 2?",
      "answers": ["A", "B"],
      "correctIndex": 0
    }
  ]
}
''';

    const outOfRange = '''
{
  "id": "range_pack",
  "title": "Range Pack",
  "questions": [
    {
      "id": "q1",
      "domain": "Security",
      "question": "Prompt?",
      "answers": ["A", "B"],
      "correctIndex": 3
    }
  ]
}
''';

    expect(
      () => DeckPack.parseJsonString(
        duplicateIds,
        assetPath: 'assets/decks/dup_pack.json',
      ),
      throwsFormatException,
    );
    expect(
      () => DeckPack.parseJsonString(
        outOfRange,
        assetPath: 'assets/decks/range_pack.json',
      ),
      throwsFormatException,
    );
  });

  test('rejects empty answer strings in normalized question entries', () {
    const raw = '''
{
  "id": "empty_answer_pack",
  "title": "Empty Answer Pack",
  "questions": [
    {
      "id": "q1",
      "domain": "Security",
      "question": "Prompt?",
      "answers": ["A", ""],
      "correctIndex": 0
    }
  ]
}
''';

    expect(
      () => DeckPack.parseJsonString(
        raw,
        assetPath: 'assets/decks/empty_answer_pack.json',
      ),
      throwsFormatException,
    );
  });

  test('rejects mismatched declared questionCount metadata', () {
    const raw = '''
{
  "id": "count_mismatch",
  "title": "Count Mismatch",
  "questionCount": 4,
  "questions": [
    {
      "id": "q1",
      "domain": "Security",
      "question": "Prompt?",
      "answers": ["A", "B"],
      "correctIndex": 0
    }
  ]
}
''';

    expect(
      () => DeckPack.parseJsonString(
        raw,
        assetPath: 'assets/decks/count_mismatch.json',
      ),
      throwsFormatException,
    );
  });

  test('parses the real AWS Cloud Practitioner deck asset', () {
    final raw = File(
      'assets/decks/aws_cloud_practitioner_clf_c02.json',
    ).readAsStringSync();

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath: 'assets/decks/aws_cloud_practitioner_clf_c02.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/aws_cloud_practitioner_clf_c02.json',
    );

    expect(meta.id, 'aws_cloud_practitioner_clf_c02');
    expect(meta.title, 'AWS Cloud Practitioner');
    expect(meta.examCode, 'CLF-C02');
    expect(meta.questionCount, 24);
    expect(meta.examQuestionCount, 24);
    expect(meta.isStarter, false);
    expect(
      meta.domains,
      containsAll(<String>[
        'Cloud Concepts',
        'Security and Compliance',
        'Cloud Technology and Services',
        'Billing, Pricing, and Support',
      ]),
    );
    expect(deck.items, hasLength(24));
    expect(
      deck.items.every((item) => item.contentType == 'exam_question'),
      isTrue,
    );
    expect(deck.items.every((item) => item.options.length == 4), isTrue);
  });

  test('parses the real AWS Solutions Architect Associate deck asset', () {
    final raw = File(
      'assets/decks/aws_solutions_architect_associate_saa_c03.json',
    ).readAsStringSync();

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath: 'assets/decks/aws_solutions_architect_associate_saa_c03.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/aws_solutions_architect_associate_saa_c03.json',
    );

    expect(meta.id, 'aws_solutions_architect_associate_saa_c03');
    expect(meta.title, 'AWS Solutions Architect Associate');
    expect(meta.examCode, 'SAA-C03');
    expect(meta.questionCount, 24);
    expect(meta.examQuestionCount, 24);
    expect(meta.isStarter, false);
    expect(
      meta.domains,
      containsAll(<String>[
        'Design Secure Architectures',
        'Design Resilient Architectures',
        'Design High-Performing Architectures',
        'Design Cost-Optimized Architectures',
      ]),
    );
    expect(deck.items, hasLength(24));
    expect(
      deck.items.every((item) => item.contentType == 'exam_question'),
      isTrue,
    );
    expect(deck.items.every((item) => item.options.length == 4), isTrue);
  });

  test('parses the normalized Security+ 20-question deck asset', () {
    final raw = File(
      'assets/decks/sec701_exam_pack_20.json',
    ).readAsStringSync();

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath: 'assets/decks/sec701_exam_pack_20.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/sec701_exam_pack_20.json',
    );

    expect(meta.id, 'comptia_security_plus_sy0_701_pack_20');
    expect(meta.title, 'CompTIA Security+ Pack 20');
    expect(meta.examCode, 'SY0-701');
    expect(meta.questionCount, 20);
    expect(meta.examQuestionCount, 20);
    expect(
      meta.domains,
      containsAll(<String>[
        'General Security Concepts',
        'Threats, Vulnerabilities, and Mitigations',
        'Security Architecture',
        'Security Operations',
        'Security Program Management and Oversight',
      ]),
    );
    expect(deck.items, hasLength(20));
    expect(deck.items.every((item) => item.options.length == 4), isTrue);
    expect(deck.items.every((item) => item.explanationText != null), isTrue);
    expect(deck.items.every((item) => item.difficulty != null), isTrue);
  });

  test('Security+ app assets follow the standardized root metadata shape', () {
    final files = <String>[
      'assets/decks/sec701_exam_pack_20.json',
      'assets/decks/sec701_exam_pack_30_a.json',
      'assets/decks/sec701_exam_simulation_90.json',
    ];

    for (final path in files) {
      final decoded =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final questions = decoded['questions'] as List<dynamic>;

      expect(decoded['id'], isA<String>());
      expect(decoded['title'], isA<String>());
      expect(decoded['examCode'], 'SY0-701');
      expect(decoded['category'], 'Cybersecurity');
      expect(decoded['description'], isA<String>());
      expect(decoded['version'], isNotNull);
      expect(decoded['questionCount'], questions.length);
      expect(decoded['domains'], isA<List<dynamic>>());
      expect(decoded['defaultContentType'], 'exam_question');
      expect(decoded['questions'], isA<List<dynamic>>());
    }
  });

  test('Security+ app assets use normalized question keys', () {
    final files = <String>[
      'assets/decks/sec701_exam_pack_20.json',
      'assets/decks/sec701_exam_pack_30_a.json',
      'assets/decks/sec701_exam_simulation_90.json',
    ];

    for (final path in files) {
      final decoded =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final questions = decoded['questions'] as List<dynamic>;

      expect(questions, isNotEmpty);
      for (final raw in questions.cast<Map<String, dynamic>>()) {
        expect(raw['id'], isA<String>());
        expect(raw['domain'], isA<String>());
        expect(raw['difficulty'], isA<int>());
        expect(raw['question'], isA<String>());
        expect(raw['answers'], isA<List<dynamic>>());
        expect(raw['correctIndex'], isA<int>());
        expect(raw['explanation'], isA<String>());
      }
    }
  });

  test('parses the real Linux Essentials deck asset', () {
    final raw = File(
      'assets/decks/linux_essentials_010_160.json',
    ).readAsStringSync();

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath: 'assets/decks/linux_essentials_010_160.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/linux_essentials_010_160.json',
    );

    expect(meta.id, 'linux_essentials_010_160');
    expect(meta.title, 'Linux Essentials');
    expect(meta.examCode, '010-160');
    expect(meta.questionCount, 25);
    expect(meta.examQuestionCount, 25);
    expect(meta.isStarter, false);
    expect(
      meta.domains,
      containsAll(<String>[
        'The Linux Community and a Career in Open Source',
        'Finding Your Way on a Linux System',
        'The Power of the Command Line',
        'The Linux Operating System',
        'Security and File Permissions',
      ]),
    );
    expect(deck.items, hasLength(25));
    expect(
      deck.items.every((item) => item.contentType == 'exam_question'),
      isTrue,
    );
    expect(deck.items.every((item) => item.options.length == 4), isTrue);
  });

  test('parses public launch topic deck assets', () {
    final files = <String>[
      'assets/decks/technology_basics_starter.json',
      'assets/decks/world_history_starter.json',
      'assets/decks/basic_science_starter.json',
      'assets/decks/general_knowledge_starter.json',
    ];

    for (final path in files) {
      final raw = File(path).readAsStringSync();
      final meta = DeckPackMeta.inspectJsonString(raw, assetPath: path);
      final deck = DeckPack.parseJsonString(raw, assetPath: path);

      expect(meta.isStarter, isFalse);
      expect(meta.questionCount, greaterThan(0));
      expect(meta.hasQuestions, isTrue);
      expect(meta.isImportable, isTrue);
      expect(meta.supportsFeed, isTrue);
      expect(meta.supportsExam, isFalse);
      expect(meta.librarySection, 'General Knowledge');
      expect(deck.items, hasLength(meta.questionCount));
      expect(
        deck.items.every((item) => item.contentType == 'micro_card'),
        isTrue,
      );
    }
  });

  test('parses all Security+ batch deck files', () {
    final dir = Directory('docs/question_batches/security_plus');
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);

    for (final file in files) {
      final raw = file.readAsStringSync();
      final meta = DeckPackMeta.inspectJsonString(raw, assetPath: file.path);
      final deck = DeckPack.parseJsonString(raw, assetPath: file.path);

      expect(meta.title, 'CompTIA Security+');
      expect(meta.questionCount, 30);
      expect(meta.examQuestionCount, 30);
      expect(meta.domains, hasLength(1));
      expect(deck.items, hasLength(30));
      expect(deck.items.every((item) => item.options.length == 4), isTrue);
      expect(
        deck.items.every((item) => item.contentType == 'exam_question'),
        isTrue,
      );
    }
  });

  test('parses all AWS Cloud Practitioner batch deck files', () {
    final dir = Directory('docs/question_batches/aws_cloud_practitioner');
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);

    for (final file in files) {
      final raw = file.readAsStringSync();
      final meta = DeckPackMeta.inspectJsonString(raw, assetPath: file.path);
      final deck = DeckPack.parseJsonString(raw, assetPath: file.path);

      expect(meta.title, 'AWS Cloud Practitioner');
      expect(meta.questionCount, 30);
      expect(meta.examQuestionCount, 30);
      expect(meta.domains, hasLength(1));
      expect(deck.items, hasLength(30));
      expect(deck.items.every((item) => item.options.length == 4), isTrue);
      expect(
        deck.items.every((item) => item.contentType == 'exam_question'),
        isTrue,
      );
    }
  });

  test('parses all AWS Solutions Architect Associate batch deck files', () {
    final dir = Directory(
      'docs/question_batches/aws_solutions_architect_associate',
    );
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);

    for (final file in files) {
      final raw = file.readAsStringSync();
      final meta = DeckPackMeta.inspectJsonString(raw, assetPath: file.path);
      final deck = DeckPack.parseJsonString(raw, assetPath: file.path);

      expect(meta.title, 'AWS Solutions Architect Associate');
      expect(meta.questionCount, 30);
      expect(meta.examQuestionCount, 30);
      expect(meta.domains, hasLength(1));
      expect(deck.items, hasLength(30));
      expect(deck.items.every((item) => item.options.length == 4), isTrue);
      expect(
        deck.items.every((item) => item.contentType == 'exam_question'),
        isTrue,
      );
    }
  });

  test('parses all Linux Essentials batch deck files', () {
    final dir = Directory('docs/question_batches/linux_essentials');
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);

    for (final file in files) {
      final raw = file.readAsStringSync();
      final meta = DeckPackMeta.inspectJsonString(raw, assetPath: file.path);
      final deck = DeckPack.parseJsonString(raw, assetPath: file.path);

      expect(meta.title, 'Linux Essentials');
      expect(meta.questionCount, 30);
      expect(meta.examQuestionCount, 30);
      expect(meta.domains, hasLength(1));
      expect(deck.items, hasLength(30));
      expect(deck.items.every((item) => item.options.length == 4), isTrue);
      expect(
        deck.items.every((item) => item.contentType == 'exam_question'),
        isTrue,
      );
    }
  });

  test('parses all Technology Basics batch deck files', () {
    final dir = Directory('docs/question_batches/technology_basics');
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, isNotEmpty);

    for (final file in files) {
      final raw = file.readAsStringSync();
      final meta = DeckPackMeta.inspectJsonString(raw, assetPath: file.path);
      final deck = DeckPack.parseJsonString(raw, assetPath: file.path);

      expect(meta.title, 'Technology Basics');
      expect(meta.questionCount, 30);
      expect(meta.examQuestionCount, 30);
      expect(meta.librarySection, 'General Knowledge');
      expect(meta.domains, hasLength(1));
      expect(deck.items, hasLength(30));
      expect(deck.items.every((item) => item.options.length == 4), isTrue);
      expect(
        deck.items.every((item) => item.contentType == 'exam_question'),
        isTrue,
      );
    }
  });

  test('public launch packs are real feed-ready decks', () {
    final publicPacks =
        <({String path, String title, String id, String? examCode})>[
          (
            path: 'assets/decks/technology_basics_starter.json',
            title: 'Technology Basics',
            id: 'technology_basics_daily',
            examCode: null,
          ),
          (
            path: 'assets/decks/world_history_starter.json',
            title: 'World History',
            id: 'world_history_daily',
            examCode: null,
          ),
          (
            path: 'assets/decks/basic_science_starter.json',
            title: 'Basic Science',
            id: 'basic_science_daily',
            examCode: null,
          ),
          (
            path: 'assets/decks/general_knowledge_starter.json',
            title: 'General Knowledge',
            id: 'general_knowledge_daily',
            examCode: null,
          ),
        ];

    for (final pack in publicPacks) {
      final raw = File(pack.path).readAsStringSync();
      final meta = DeckPackMeta.inspectJsonString(raw, assetPath: pack.path);

      expect(meta.id, pack.id);
      expect(meta.title, pack.title);
      expect(meta.examCode, pack.examCode);
      expect(meta.isStarter, isFalse);
      expect(meta.supportsFeed, isTrue);
      expect(meta.supportsExam, isFalse);
      expect(meta.librarySection, 'General Knowledge');
      expect(meta.isImportable, isTrue);
      expect(meta.questionCount, greaterThan(0));
    }
  });

  test(
    'marks duplicate deck ids as invalid during local discovery post-processing',
    () {
      const metaA = DeckPackMeta(
        id: 'dup_deck',
        title: 'Deck A',
        assetPath: 'assets/decks/deck_a.json',
        questionCount: 10,
        microCardCount: 0,
        examQuestionCount: 10,
      );
      const metaB = DeckPackMeta(
        id: 'dup_deck',
        title: 'Deck B',
        assetPath: 'assets/decks/deck_b.json',
        questionCount: 8,
        microCardCount: 0,
        examQuestionCount: 8,
      );
      const unique = DeckPackMeta(
        id: 'unique_deck',
        title: 'Deck C',
        assetPath: 'assets/decks/deck_c.json',
        questionCount: 6,
        microCardCount: 0,
        examQuestionCount: 6,
      );

      final metas = [metaA, metaB, unique];
      final duplicatePathsById = <String, List<String>>{};
      for (final meta in metas) {
        duplicatePathsById.putIfAbsent(meta.id, () => []).add(meta.assetPath);
      }
      final duplicateIdSet = {
        for (final entry in duplicatePathsById.entries)
          if (entry.value.length > 1) entry.key,
      };

      final normalized = [
        for (final meta in metas)
          if (!duplicateIdSet.contains(meta.id))
            meta
          else
            DeckPackMeta(
              id: meta.id,
              title: meta.title,
              assetPath: meta.assetPath,
              questionCount: meta.questionCount,
              microCardCount: meta.microCardCount,
              examQuestionCount: meta.examQuestionCount,
              invalidJsonMessage:
                  'Duplicate deck id "${meta.id}" found in ${(duplicatePathsById[meta.id]!..sort()).join(', ')}',
            ),
      ];

      expect(normalized[0].hasInvalidJson, isTrue);
      expect(normalized[1].hasInvalidJson, isTrue);
      expect(normalized[2].hasInvalidJson, isFalse);
    },
  );
}
