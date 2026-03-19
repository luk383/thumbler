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
    final errors = <String>[];

    for (var i = 0; i < questions.length; i++) {
      final rawQuestion = questions[i];
      if (rawQuestion is! Map<String, dynamic>) {
        errors.add('Question ${i + 1} is not a valid object');
        continue;
      }

      final questionText =
          _nonEmptyString(rawQuestion['question']) ??
          _nonEmptyString(rawQuestion['promptText']);
      final answers = _stringList(
        rawQuestion['answers'] ?? rawQuestion['options'],
      );
      
      int? correctIndex;
      try {
        correctIndex = _intValue(
          rawQuestion['correctIndex'] ?? rawQuestion['correctAnswerIndex'],
        );
      } catch (_) {
        // Fallback or skip if correct index is missing/invalid
      }

      if (questionText == null) {
        errors.add('Question ${i + 1} is missing "question" text');
        continue;
      }
      if (answers.length < 2) {
        errors.add('Question ${i + 1} must have at least 2 answers (found ${answers.length})');
        continue;
      }
      if (correctIndex == null || correctIndex < 0 || correctIndex >= answers.length) {
        errors.add('Question ${i + 1} has an invalid or missing correct index ($correctIndex)');
        continue;
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

    if (normalizedQuestions.isEmpty) {
      if (errors.isNotEmpty) {
        throw FormatException('Failed to import any questions:\n${errors.take(3).join('\n')}');
      }
      throw const FormatException('No valid questions found in the JSON file');
    }

    return UserDeckDraft(
      id: _slugify(id),
      title: title,
      category: category,
      description: _nonEmptyString(decoded['description']) ?? '',
      questions: normalizedQuestions,
    );
  }

  /// Parses a CSV string into a [UserDeckDraft].
  ///
  /// Supported formats (auto-detected by delimiter: `;`, `,`, `\t`):
  ///
  /// **Full format** (≥ 6 columns):
  ///   `domanda;A;B;C;D;indice_corretto[;categoria[;spiegazione]]`
  ///
  /// **Short format** (2 columns):
  ///   `fronte;retro`
  ///   Needs at least 4 rows; uses other backs as distractors.
  UserDeckDraft importFromCsv({
    required String title,
    required String category,
    String description = '',
    required String csvText,
  }) {
    final delimiter = _detectDelimiter(csvText);
    final rows = csvText
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    if (rows.isEmpty) {
      throw const FormatException('Il CSV è vuoto.');
    }

    // Skip header row if first cell looks non-data (contains letters from header keywords)
    final firstCols = rows.first.split(delimiter);
    final isHeader = firstCols.isNotEmpty &&
        RegExp(r'^(domanda|question|fronte|front|term)',
                caseSensitive: false)
            .hasMatch(firstCols.first.trim());
    final dataRows = isHeader ? rows.skip(1).toList() : rows;

    if (dataRows.isEmpty) {
      throw const FormatException('Nessuna riga di dati trovata.');
    }

    final colCount = dataRows.first.split(delimiter).length;
    if (colCount >= 6) {
      return _importFullCsv(
        title: title,
        category: category,
        description: description,
        dataRows: dataRows,
        delimiter: delimiter,
      );
    }
    if (colCount == 2) {
      return _importShortCsv(
        title: title,
        category: category,
        description: description,
        dataRows: dataRows,
        delimiter: delimiter,
      );
    }
    throw FormatException(
      'Formato CSV non riconosciuto: $colCount colonne. '
      'Usa 2 colonne (fronte;retro) o ≥6 colonne (domanda;A;B;C;D;indice).',
    );
  }

  /// Full format: `domanda;A;B;C;D;indice_corretto[;categoria[;spiegazione]]`
  UserDeckDraft _importFullCsv({
    required String title,
    required String category,
    required String description,
    required List<String> dataRows,
    required String delimiter,
  }) {
    final questions = <UserDeckQuestionDraft>[];
    final errors = <String>[];

    for (var i = 0; i < dataRows.length; i++) {
      final cols = dataRows[i].split(delimiter).map((c) => c.trim()).toList();
      if (cols.length < 6) {
        errors.add('Riga ${i + 1}: meno di 6 colonne, saltata.');
        continue;
      }
      final question = cols[0];
      final answers = cols.sublist(1, min(5, cols.length));
      final correctIndex = int.tryParse(cols[5]);
      final rowCategory = cols.length > 6 && cols[6].isNotEmpty
          ? cols[6]
          : category;
      final explanation =
          cols.length > 7 ? cols[7] : '';

      if (question.isEmpty) {
        errors.add('Riga ${i + 1}: domanda vuota, saltata.');
        continue;
      }
      if (answers.length < 2) {
        errors.add('Riga ${i + 1}: meno di 2 risposte, saltata.');
        continue;
      }
      if (correctIndex == null ||
          correctIndex < 0 ||
          correctIndex >= answers.length) {
        errors.add(
            'Riga ${i + 1}: indice_corretto "$correctIndex" non valido, saltata.');
        continue;
      }

      questions.add(UserDeckQuestionDraft(
        question: question,
        answers: answers,
        correctIndex: correctIndex,
        explanation: explanation,
        domain: rowCategory,
      ));
    }

    if (questions.isEmpty) {
      final msg = errors.isEmpty
          ? 'Nessuna domanda valida trovata.'
          : 'Nessuna domanda valida:\n${errors.take(3).join('\n')}';
      throw FormatException(msg);
    }

    return UserDeckDraft(
      id: _slugify('${title}_${DateTime.now().millisecondsSinceEpoch}'),
      title: title,
      category: category,
      description: description,
      questions: questions,
    );
  }

  /// Short format: `fronte;retro` — uses other backs as distractors.
  UserDeckDraft _importShortCsv({
    required String title,
    required String category,
    required String description,
    required List<String> dataRows,
    required String delimiter,
  }) {
    final pairs = <(String front, String back)>[];
    for (final row in dataRows) {
      final cols = row.split(delimiter);
      if (cols.length < 2) continue;
      final front = cols[0].trim();
      final back = cols[1].trim();
      if (front.isEmpty || back.isEmpty) continue;
      pairs.add((front, back));
    }

    if (pairs.length < 4) {
      throw const FormatException(
        'Formato corto: servono almeno 4 righe per generare distrattori.',
      );
    }

    final questions = <UserDeckQuestionDraft>[];
    for (var i = 0; i < pairs.length; i++) {
      final (front, back) = pairs[i];
      final distractors = pairs
          .where((p) => p.$1 != front)
          .take(3)
          .map((p) => p.$2)
          .toList(growable: false);
      if (distractors.length < 3) continue;

      final answers = [back, ...distractors];
      answers.shuffle(Random(front.hashCode));
      final correctIndex = answers.indexOf(back);

      questions.add(UserDeckQuestionDraft(
        question: front,
        answers: answers,
        correctIndex: correctIndex,
        explanation: back,
        domain: category,
      ));
    }

    if (questions.isEmpty) {
      throw const FormatException('Nessuna domanda valida generata.');
    }

    return UserDeckDraft(
      id: _slugify('${title}_${DateTime.now().millisecondsSinceEpoch}'),
      title: title,
      category: category,
      description: description,
      questions: questions,
    );
  }

  String _detectDelimiter(String text) {
    final firstLine = text.split('\n').first;
    final counts = {
      ';': ';'.allMatches(firstLine).length,
      ',': ','.allMatches(firstLine).length,
      '\t': '\t'.allMatches(firstLine).length,
    };
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
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
