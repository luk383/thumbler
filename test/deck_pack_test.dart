import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wolf_lab/features/study/data/deck_pack.dart';

void main() {
  test('parses normalized AWS certification metadata', () {
    const raw = '''
{
  "id": "aws_certified_security_specialty_scs_c02",
  "provider": "aws",
  "certificationId": "aws_scs",
  "certificationTitle": "AWS Certified Security - Specialty",
  "track": "Specialty",
  "title": "AWS Certified Security - Specialty",
  "examCode": "SCS-C02",
  "category": "AWS Security",
  "aliases": ["aws_security_specialty_scs_c02"],
  "tags": ["aws", "aws_scs"],
  "questions": [
    {
      "id": "q1",
      "type": "exam_question",
      "domainId": "scs-threat-detection",
      "domain": "Threat Detection and Monitoring",
      "topic": "Detection",
      "subtopic": "GuardDuty",
      "objectiveId": "1.1",
      "difficulty": 2,
      "tags": ["aws_scs", "guardduty"],
      "question": "Which service provides managed threat detection?",
      "answers": ["Amazon GuardDuty", "AWS Budgets", "Amazon S3"],
      "correctIndex": 0,
      "explanation": "GuardDuty analyzes AWS telemetry to identify suspicious behavior."
    }
  ]
}
''';

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath: 'assets/decks/aws_certified_security_specialty_scs_c02.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/aws_certified_security_specialty_scs_c02.json',
    );

    expect(meta.provider, 'aws');
    expect(meta.certificationId, 'aws_scs');
    expect(meta.certificationTitle, 'AWS Certified Security - Specialty');
    expect(meta.track, 'Specialty');
    expect(meta.examCode, 'SCS-C02');
    expect(meta.tags, contains('aws_scs'));
    expect(meta.aliases, contains('aws_security_specialty_scs_c02'));
    expect(meta.librarySection, 'Certifications');
    expect(deck.items.single.domainId, 'scs-threat-detection');
    expect(deck.items.single.tags, contains('guardduty'));
  });

  test('still parses legacy wrapped items format', () {
    const raw = '''
{
  "id": "legacy_pack",
  "name": "Legacy Pack",
  "items": [
    {
      "id": "legacy_001",
      "contentType": "micro_card",
      "category": "AWS Architecture",
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
      assetPath: 'assets/decks/legacy_pack.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/legacy_pack.json',
    );

    expect(meta.title, 'Legacy Pack');
    expect(meta.microCardCount, 1);
    expect(deck.items.single.contentType, 'micro_card');
  });

  test('parses the real AWS Solutions Architect Associate deck asset', () {
    final raw = File(
      'assets/decks/aws_certified_solutions_architect_associate_saa_c03.json',
    ).readAsStringSync();

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath:
          'assets/decks/aws_certified_solutions_architect_associate_saa_c03.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath:
          'assets/decks/aws_certified_solutions_architect_associate_saa_c03.json',
    );

    expect(meta.id, 'aws_certified_solutions_architect_associate_saa_c03');
    expect(meta.provider, 'aws');
    expect(meta.certificationId, 'aws_saa');
    expect(meta.examCode, 'SAA-C03');
    expect(meta.questionCount, 140);
    expect(meta.microCardCount, 80);
    expect(meta.examQuestionCount, 60);
    expect(
      meta.domains,
      containsAll(<String>[
        'Design Secure Architectures',
        'Design Resilient Architectures',
        'Design High-Performing Architectures',
        'Design Cost-Optimized Architectures',
      ]),
    );
    expect(deck.items, hasLength(140));
    expect(
      deck.items.where((item) => item.contentType == 'exam_question'),
      hasLength(60),
    );
    expect(
      deck.items.where((item) => item.contentType == 'micro_card'),
      hasLength(80),
    );
  });

  test('parses the real AWS Security Specialty deck asset', () {
    final raw = File(
      'assets/decks/aws_certified_security_specialty_scs_c02.json',
    ).readAsStringSync();

    final meta = DeckPackMeta.inspectJsonString(
      raw,
      assetPath: 'assets/decks/aws_certified_security_specialty_scs_c02.json',
    );
    final deck = DeckPack.parseJsonString(
      raw,
      assetPath: 'assets/decks/aws_certified_security_specialty_scs_c02.json',
    );

    expect(meta.id, 'aws_certified_security_specialty_scs_c02');
    expect(meta.provider, 'aws');
    expect(meta.certificationId, 'aws_scs');
    expect(meta.examCode, 'SCS-C02');
    expect(meta.questionCount, 140);
    expect(meta.microCardCount, 80);
    expect(meta.examQuestionCount, 60);
    expect(
      meta.domains,
      containsAll(<String>[
        'Threat Detection and Monitoring',
        'Identity, Access, and Perimeter Controls',
        'Data Protection and Cryptography',
        'Incident Response and Infrastructure Protection',
      ]),
    );
    expect(deck.items, hasLength(140));
    expect(deck.items.every((item) => item.tags.isNotEmpty), isTrue);
  });

  test('parses all AWS Solutions Architect Associate batch deck files', () {
    final dir = Directory(
      'docs/question_batches/aws_certified_solutions_architect_associate',
    );
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, hasLength(4));

    for (final file in files) {
      final raw = file.readAsStringSync();
      final meta = DeckPackMeta.inspectJsonString(raw, assetPath: file.path);
      final deck = DeckPack.parseJsonString(raw, assetPath: file.path);

      expect(meta.title, 'AWS Certified Solutions Architect - Associate');
      expect(meta.examQuestionCount, 15);
      expect(meta.microCardCount, 0);
      expect(
        deck.items.every((item) => item.contentType == 'exam_question'),
        isTrue,
      );
    }
  });

  test('parses all AWS Security Specialty batch deck files', () {
    final dir = Directory(
      'docs/question_batches/aws_certified_security_specialty',
    );
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, hasLength(4));

    for (final file in files) {
      final raw = file.readAsStringSync();
      final meta = DeckPackMeta.inspectJsonString(raw, assetPath: file.path);
      final deck = DeckPack.parseJsonString(raw, assetPath: file.path);

      expect(meta.title, 'AWS Certified Security - Specialty');
      expect(meta.examQuestionCount, 15);
      expect(meta.microCardCount, 0);
      expect(
        deck.items.every((item) => item.contentType == 'exam_question'),
        isTrue,
      );
    }
  });
}
