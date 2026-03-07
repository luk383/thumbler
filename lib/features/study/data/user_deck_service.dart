import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../domain/user_deck_draft.dart';
import 'deck_library_storage.dart';
import 'deck_pack.dart';

class UserDeckService {
  const UserDeckService();

  Future<void> saveDeck(UserDeckDraft draft) async {
    final normalized = draft.toNormalizedJson();
    DeckPack.parseJsonString(normalized, assetPath: 'user://${draft.id}');
    await const DeckLibraryStorage().saveUserDeckJson(draft.id, normalized);
  }

  UserDeckDraft normalizeImportedJson(
    String raw, {
    required String fallbackCategory,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Deck JSON must be an object');
    }

    final id = _nonEmptyString(decoded['id']);
    final title = _nonEmptyString(decoded['title']);
    final questions = decoded['questions'];
    if (id == null) {
      throw const FormatException('Missing required deck field "id"');
    }
    if (title == null) {
      throw const FormatException('Missing required deck field "title"');
    }
    if (questions is! List || questions.isEmpty) {
      throw const FormatException('Missing required deck field "questions"');
    }

    final category =
        _nonEmptyString(decoded['category']) ??
        (_stringList(decoded['domains']).isNotEmpty
            ? _stringList(decoded['domains']).first
            : null) ??
        fallbackCategory;

    final normalizedQuestions = <UserDeckQuestionDraft>[];
    for (var i = 0; i < questions.length; i++) {
      final rawQuestion = questions[i];
      if (rawQuestion is! Map<String, dynamic>) {
        throw FormatException('Question ${i + 1} must be an object');
      }

      final questionText =
          _nonEmptyString(rawQuestion['question']) ??
          _nonEmptyString(rawQuestion['promptText']);
      final answers = _stringList(
        rawQuestion['answers'] ?? rawQuestion['options'],
      );
      final correctIndex = _intValue(
        rawQuestion['correctIndex'] ?? rawQuestion['correctAnswerIndex'],
      );

      if (questionText == null) {
        throw FormatException('Question ${i + 1} is missing "question"');
      }
      if (answers.length != 4) {
        throw FormatException('Question ${i + 1} must have exactly 4 answers');
      }
      if (correctIndex < 0 || correctIndex >= answers.length) {
        throw FormatException('Question ${i + 1} has an invalid correctIndex');
      }

      normalizedQuestions.add(
        UserDeckQuestionDraft(
          question: questionText,
          answers: answers,
          correctIndex: correctIndex,
          explanation:
              _nonEmptyString(
                rawQuestion['explanation'] ?? rawQuestion['explanationText'],
              ) ??
              '',
          domain:
              _nonEmptyString(rawQuestion['domain']) ??
              _nonEmptyString(rawQuestion['category']) ??
              category,
        ),
      );
    }

    return UserDeckDraft(
      id: _slugify(id),
      title: title,
      category: category,
      description: _nonEmptyString(decoded['description']) ?? '',
      questions: normalizedQuestions,
    );
  }

  UserDeckDraft generateFromText({
    required String title,
    required String category,
    String description = '',
    required String sourceText,
    int maxQuestions = 12,
  }) {
    final statements = _extractStatements(sourceText);
    if (statements.length < 4) {
      throw const FormatException(
        'Not enough clear study content. Add more notes or paste longer text.',
      );
    }

    final questions = <UserDeckQuestionDraft>[];
    for (
      var i = 0;
      i < statements.length && questions.length < maxQuestions;
      i++
    ) {
      final statement = statements[i];
      final distractors = statements
          .where((candidate) => candidate.term != statement.term)
          .take(3)
          .map((candidate) => candidate.definition)
          .toList(growable: false);
      if (distractors.length < 3) continue;

      questions.add(
        UserDeckQuestionDraft(
          question: 'What best describes ${statement.term}?',
          answers: [statement.definition, ...distractors],
          correctIndex: 0,
          explanation: statement.definition,
          domain: category,
        ),
      );
    }

    if (questions.length < 4) {
      throw const FormatException(
        'Could not generate enough multiple choice questions from this text.',
      );
    }

    for (final question in questions) {
      question.answers.shuffle(Random(question.question.hashCode));
      question.correctIndex = question.answers.indexOf(question.explanation);
    }

    return UserDeckDraft(
      id: _slugify('${title}_${DateTime.now().millisecondsSinceEpoch}'),
      title: title,
      category: category,
      description: description,
      questions: questions,
    );
  }

  Future<String> extractTextFromPdf(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException('Unable to read the selected PDF file');
    }
    return _extractPdfText(bytes);
  }

  String _extractPdfText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalized.isEmpty) {
        throw const FormatException(
          'The selected PDF does not contain readable text',
        );
      }
      return normalized;
    } finally {
      document.dispose();
    }
  }
}

class _Statement {
  const _Statement({required this.term, required this.definition});

  final String term;
  final String definition;
}

List<_Statement> _extractStatements(String sourceText) {
  final normalized = sourceText.replaceAll('\r', '\n');
  final chunks = normalized
      .split(RegExp(r'[\n\.]'))
      .map((line) => line.trim())
      .where((line) => line.length >= 24)
      .toList(growable: false);

  final statements = <_Statement>[];
  for (final chunk in chunks) {
    final match = RegExp(
      r'^([A-Za-z0-9 \-/()]{3,60}?)\s+(is|are|means|refers to|describes)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(chunk);
    if (match != null) {
      final term = match.group(1)!.trim();
      final definition = _trimDefinition(match.group(3)!);
      if (term.length >= 3 && definition.length >= 12) {
        statements.add(_Statement(term: term, definition: definition));
        continue;
      }
    }

    final words = chunk.split(RegExp(r'\s+'));
    if (words.length < 6) continue;
    final term = words.take(min(3, max(2, words.length ~/ 5))).join(' ');
    final definition = _trimDefinition(chunk);
    if (term.length >= 3 && definition.length >= 18) {
      statements.add(_Statement(term: term, definition: definition));
    }
  }

  final seenTerms = <String>{};
  return statements
      .where((statement) {
        final key = statement.term.toLowerCase();
        if (seenTerms.contains(key)) return false;
        seenTerms.add(key);
        return true;
      })
      .toList(growable: false);
}

String _trimDefinition(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 110) return normalized;
  return '${normalized.substring(0, 107).trimRight()}...';
}

String _slugify(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (slug.isEmpty) {
    return 'deck_${DateTime.now().millisecondsSinceEpoch}';
  }
  return slug;
}

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw const FormatException('Invalid correctIndex');
}
