import 'dart:convert';

import 'package:flutter/services.dart';

import 'deck_library_storage.dart';
import '../domain/study_item.dart';

class DeckPackMeta {
  const DeckPackMeta({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.questionCount,
    required this.microCardCount,
    required this.examQuestionCount,
    this.provider,
    this.certificationId,
    this.certificationTitle,
    this.track,
    this.examCode,
    this.category,
    this.description,
    this.version,
    this.domains = const [],
    this.tags = const [],
    this.aliases = const [],
    this.isStarter = false,
    this.availabilityNote,
    this.invalidJsonMessage,
  });

  final String id;
  final String title;
  final String assetPath;
  final String? provider;
  final String? certificationId;
  final String? certificationTitle;
  final String? track;
  final String? examCode;
  final String? category;
  final String? description;
  final String? version;
  final List<String> domains;
  final List<String> tags;
  final List<String> aliases;
  final bool isStarter;
  final String? availabilityNote;
  final int questionCount;
  final int microCardCount;
  final int examQuestionCount;
  final String? invalidJsonMessage;

  bool get hasInvalidJson => invalidJsonMessage != null;
  bool get hasQuestions => questionCount > 0;
  bool get supportsFeed => microCardCount > 0;
  bool get supportsExam => examQuestionCount > 0;
  bool get isImportable => !hasInvalidJson && !isStarter && hasQuestions;
  bool get isCertificationDeck =>
      (certificationId?.trim().isNotEmpty ?? false) ||
      (examCode?.trim().isNotEmpty ?? false);
  String get librarySection => 'Certifications';

  String get subtitle {
    final parts = <String>[
      ...?(examCode == null ? null : [examCode!]),
      ...?(category == null ? null : [category!]),
      if (questionCount > 0) '$questionCount items',
    ];
    return parts.isEmpty ? assetPath.split('/').last : parts.join(' • ');
  }

  static DeckPackMeta inspectJsonString(
    String raw, {
    required String assetPath,
  }) {
    final decoded = jsonDecode(raw);
    return _inspectDecodedDeck(decoded, assetPath: assetPath);
  }

  static Future<List<DeckPackMeta>> discoverLocalPacks() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest
        .listAssets()
        .where((k) => k.startsWith('assets/decks/') && k.endsWith('.json'))
        .toList();

    final metas = <DeckPackMeta>[];
    for (final path in paths) {
      final filename = path.split('/').last;
      final fallbackId = filename.replaceAll('.json', '');
      final fallbackTitle = _titleFromFilename(filename);
      String id = fallbackId;
      String title = fallbackTitle;
      String? description;
      String? provider;
      String? certificationId;
      String? certificationTitle;
      String? track;
      String? examCode = _deriveExamCodeFromFilename(filename);
      String? category;
      String? version;
      List<String> domains = const [];
      List<String> tags = const [];
      List<String> aliases = const [];
      bool isStarter = false;
      String? availabilityNote;
      int questionCount = 0;
      int microCardCount = 0;
      int examQuestionCount = 0;
      String? invalidJsonMessage;

      try {
        final raw = await rootBundle.loadString(path);
        final inspected = inspectJsonString(raw, assetPath: path);
        id = inspected.id;
        title = inspected.title;
        description = inspected.description;
        provider = inspected.provider;
        certificationId = inspected.certificationId;
        certificationTitle = inspected.certificationTitle;
        track = inspected.track;
        examCode = inspected.examCode ?? examCode;
        category = inspected.category;
        version = inspected.version;
        domains = inspected.domains;
        tags = inspected.tags;
        aliases = inspected.aliases;
        isStarter = inspected.isStarter;
        availabilityNote = inspected.availabilityNote;
        questionCount = inspected.questionCount;
        microCardCount = inspected.microCardCount;
        examQuestionCount = inspected.examQuestionCount;
      } catch (e) {
        invalidJsonMessage = e.toString();
      }

      metas.add(
        DeckPackMeta(
          id: id,
          title: title,
          assetPath: path,
          provider: provider,
          certificationId: certificationId,
          certificationTitle: certificationTitle,
          track: track,
          examCode: examCode,
          category: category,
          description: description,
          version: version,
          domains: domains,
          tags: tags,
          aliases: aliases,
          isStarter: isStarter,
          availabilityNote: availabilityNote,
          questionCount: questionCount,
          microCardCount: microCardCount,
          examQuestionCount: examQuestionCount,
          invalidJsonMessage: invalidJsonMessage,
        ),
      );
    }

    const libraryStorage = DeckLibraryStorage();
    final userDecks = libraryStorage.loadAllUserDeckJson();
    for (final entry in userDecks.entries) {
      final deckId = entry.key;
      final raw = entry.value;
      final pseudoPath = 'user://$deckId';
      String title = deckId;
      String? description;
      String? provider;
      String? certificationId;
      String? certificationTitle;
      String? track;
      String? examCode;
      String? category;
      String? version;
      List<String> domains = const [];
      List<String> tags = const [];
      List<String> aliases = const [];
      bool isStarter = false;
      String? availabilityNote;
      int questionCount = 0;
      int microCardCount = 0;
      int examQuestionCount = 0;
      String? invalidJsonMessage;

      try {
        final inspected = inspectJsonString(raw, assetPath: pseudoPath);
        title = inspected.title;
        description = inspected.description;
        provider = inspected.provider;
        certificationId = inspected.certificationId;
        certificationTitle = inspected.certificationTitle;
        track = inspected.track;
        examCode = inspected.examCode;
        category = inspected.category;
        version = inspected.version;
        domains = inspected.domains;
        tags = inspected.tags;
        aliases = inspected.aliases;
        isStarter = inspected.isStarter;
        availabilityNote = inspected.availabilityNote;
        questionCount = inspected.questionCount;
        microCardCount = inspected.microCardCount;
        examQuestionCount = inspected.examQuestionCount;
      } catch (e) {
        invalidJsonMessage = e.toString();
      }

      metas.add(
        DeckPackMeta(
          id: deckId,
          title: title,
          assetPath: pseudoPath,
          provider: provider,
          certificationId: certificationId,
          certificationTitle: certificationTitle,
          track: track,
          examCode: examCode,
          category: category,
          description: description,
          version: version,
          domains: domains,
          tags: tags,
          aliases: aliases,
          isStarter: isStarter,
          availabilityNote: availabilityNote,
          questionCount: questionCount,
          microCardCount: microCardCount,
          examQuestionCount: examQuestionCount,
          invalidJsonMessage: invalidJsonMessage,
        ),
      );
    }

    // If the same deck ID exists as both a bundled asset and a user-imported
    // deck, prefer the asset version and silently drop the user copy.
    final assetIds = {
      for (final meta in metas)
        if (!meta.assetPath.startsWith('user://')) meta.id,
    };
    metas.removeWhere(
      (meta) =>
          meta.assetPath.startsWith('user://') && assetIds.contains(meta.id),
    );

    // Flag true duplicates: same ID appearing more than once within the same
    // source (asset+asset or user+user).
    final duplicatePathsById = <String, List<String>>{};
    for (final meta in metas) {
      duplicatePathsById.putIfAbsent(meta.id, () => []).add(meta.assetPath);
    }
    final duplicateIds = duplicatePathsById.entries
        .where((entry) => entry.key.trim().isNotEmpty && entry.value.length > 1)
        .toList();
    if (duplicateIds.isNotEmpty) {
      final duplicateIdSet = {for (final entry in duplicateIds) entry.key};
      for (var index = 0; index < metas.length; index++) {
        final meta = metas[index];
        if (!duplicateIdSet.contains(meta.id)) continue;
        final duplicatePaths = duplicatePathsById[meta.id]!..sort();
        metas[index] = DeckPackMeta(
          id: meta.id,
          title: meta.title,
          assetPath: meta.assetPath,
          provider: meta.provider,
          certificationId: meta.certificationId,
          certificationTitle: meta.certificationTitle,
          track: meta.track,
          examCode: meta.examCode,
          category: meta.category,
          description: meta.description,
          version: meta.version,
          domains: meta.domains,
          tags: meta.tags,
          aliases: meta.aliases,
          isStarter: meta.isStarter,
          availabilityNote: meta.availabilityNote,
          questionCount: meta.questionCount,
          microCardCount: meta.microCardCount,
          examQuestionCount: meta.examQuestionCount,
          invalidJsonMessage:
              'Duplicate deck id "${meta.id}" found in ${duplicatePaths.join(', ')}',
        );
      }
    }

    metas.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return metas;
  }
}

class DeckPackItem {
  const DeckPackItem({
    required this.id,
    required this.contentType,
    required this.category,
    this.domainId,
    this.topic,
    this.subtopic,
    this.objectiveId,
    this.tags = const [],
    required this.promptText,
    this.promptTextIt,
    this.explanationText,
    this.explanationTextIt,
    required this.options,
    this.optionsIt,
    required this.correctAnswerIndex,
    this.difficulty,
  });

  final String id;
  final String contentType;
  final String category;
  final String? domainId;
  final String? topic;
  final String? subtopic;
  final String? objectiveId;
  final List<String> tags;
  final String promptText;
  final String? promptTextIt;
  final String? explanationText;
  final String? explanationTextIt;
  final List<String> options;
  final List<String>? optionsIt;
  final int correctAnswerIndex;
  final int? difficulty;

  factory DeckPackItem.fromJson(Map<String, dynamic> j) {
    return DeckPackItem.fromJsonWithDefaults(j);
  }

  factory DeckPackItem.fromJsonWithDefaults(
    Map<String, dynamic> j, {
    String? defaultContentType,
  }) {
    final options = _stringList(j['options'] ?? j['answers']);
    final correctAnswerIndex = _intValue(
      j['correctAnswerIndex'] ?? j['correctIndex'],
    );
    if (options.isEmpty) {
      throw const FormatException(
        'Invalid "options"/"answers": expected a non-empty list',
      );
    }
    if (options.length < 2) {
      throw const FormatException(
        'Invalid "options"/"answers": expected at least 2 answer options',
      );
    }
    if (correctAnswerIndex < 0 || correctAnswerIndex >= options.length) {
      throw const FormatException(
        'Invalid "correctAnswerIndex"/"correctIndex": out of range',
      );
    }

    final contentType =
        _nonEmptyString(j['contentType']) ??
        _nonEmptyString(j['type']) ??
        defaultContentType ??
        'micro_card';
    if (!_supportedContentTypes.contains(contentType)) {
      throw FormatException(
        'Invalid question type "$contentType": expected one of ${_supportedContentTypes.join(', ')}',
      );
    }

    final optionsIt = j.containsKey('options_it')
        ? _stringList(j['options_it'])
        : null;

    return DeckPackItem(
      id: _requiredString(j, 'id'),
      contentType: contentType,
      category:
          _nonEmptyString(j['category']) ??
          _nonEmptyString(j['domain']) ??
          _requiredString(j, 'category'),
      domainId: _asString(j['domainId']),
      topic: _asString(j['topic']),
      subtopic: _asString(j['subtopic']),
      objectiveId: _asString(j['objectiveId']),
      tags: _stringListOrEmpty(j['tags']),
      promptText:
          _nonEmptyString(j['promptText']) ??
          _nonEmptyString(j['question']) ??
          _requiredString(j, 'promptText'),
      promptTextIt: _nonEmptyString(j['promptText_it']),
      explanationText:
          _asString(j['explanationText']) ?? _asString(j['explanation']),
      explanationTextIt: _asString(j['explanationText_it']),
      options: options,
      optionsIt: optionsIt,
      correctAnswerIndex: correctAnswerIndex,
      difficulty: _nullableIntValue(j['difficulty']),
    );
  }

  StudyItem toStudyItem(
    String deckId, {
    String? provider,
    String? certificationId,
    bool isItalian = false,
  }) => StudyItem(
    id: id,
    deckId: deckId,
    provider: provider,
    certificationId: certificationId,
    contentType: contentType == 'exam_question'
        ? ContentType.examQuestion
        : ContentType.microCard,
    category: category,
    domainId: domainId,
    topic: topic,
    subtopic: subtopic,
    objectiveId: objectiveId,
    tags: tags,
    promptText: (isItalian && promptTextIt != null)
        ? promptTextIt!
        : promptText,
    explanationText: (isItalian && explanationTextIt != null)
        ? explanationTextIt
        : explanationText,
    options: (isItalian && optionsIt != null) ? optionsIt! : options,
    correctAnswerIndex: correctAnswerIndex,
    difficulty: difficulty,
  );
}

class DeckPack {
  const DeckPack({required this.meta, required this.items});

  final DeckPackMeta meta;
  final List<DeckPackItem> items;

  static DeckPack parseJsonString(String raw, {required String assetPath}) {
    final decoded = jsonDecode(raw);
    final meta = _inspectDecodedDeck(decoded, assetPath: assetPath);
    final items = _parseItemsFromDecoded(decoded);
    return DeckPack(meta: meta, items: items);
  }

  static Future<DeckPack> load(DeckPackMeta meta) async {
    final raw = await loadRawJson(meta);
    if (raw == null) {
      throw FormatException('Missing local deck data for "${meta.id}"');
    }
    return parseJsonString(raw, assetPath: meta.assetPath);
  }

  static Future<String?> loadRawJson(DeckPackMeta meta) async {
    if (meta.assetPath.startsWith('user://')) {
      return const DeckLibraryStorage().loadUserDeckJson(meta.id);
    }
    return rootBundle.loadString(meta.assetPath);
  }
}

class ImportResult {
  const ImportResult({
    required this.added,
    required this.updated,
    required this.skipped,
  });

  final int added;
  final int updated;
  final int skipped;

  @override
  String toString() => 'Imported $added, updated $updated, skipped $skipped';
}

String _requiredString(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v is String && v.trim().isNotEmpty) return v;
  throw FormatException('Missing/invalid "$key"');
}

String? _asString(Object? v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

String? _nonEmptyString(Object? v) {
  final value = _asString(v)?.trim();
  return value == null || value.isEmpty ? null : value;
}

int _intValue(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  throw const FormatException('Invalid "correctAnswerIndex"');
}

int? _nullableIntValue(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  throw const FormatException('Invalid integer value');
}

List<String> _stringList(Object? v) {
  if (v is List) {
    final values = <String>[];
    for (final entry in v) {
      final normalized = _nonEmptyString(entry);
      if (normalized == null) {
        throw const FormatException(
          'Invalid "options"/"answers": expected only non-empty strings',
        );
      }
      values.add(normalized);
    }
    return values;
  }
  throw const FormatException('Invalid "options"');
}

String _titleFromFilename(String filename) {
  final base = filename.replaceAll('.json', '');
  return base
      .split('_')
      .where((e) => e.isNotEmpty)
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .join(' ');
}

String? _deriveExamCodeFromFilename(String filename) {
  final lower = filename.toLowerCase();
  if (lower.contains('saa_c03')) return 'SAA-C03';
  if (lower.contains('scs_c02')) return 'SCS-C02';
  return null;
}

String? _deriveCategoryFromItems(List<dynamic> items) {
  final categories = items
      .whereType<Map>()
      .map(
        (item) =>
            _nonEmptyString(item['category']) ??
            _nonEmptyString(item['domain']),
      )
      .whereType<String>()
      .toSet();

  if (categories.isEmpty) return null;
  if (categories.length == 1) return categories.first;
  return 'Mixed';
}

List<dynamic> _extractItemsList(dynamic decoded) {
  if (decoded is List) return decoded;
  if (decoded is Map<String, dynamic>) {
    final items = decoded['questions'] ?? decoded['items'];
    if (items is List) return items;
  }
  throw const FormatException(
    'Deck JSON must be an array or {"questions":[...]} / {"items":[...]}',
  );
}

DeckPackMeta _inspectDecodedDeck(dynamic decoded, {required String assetPath}) {
  final filename = assetPath.split('/').last;
  final fallbackId = filename.replaceAll('.json', '');
  final fallbackTitle = _titleFromFilename(filename);
  final list = _extractItemsList(decoded);

  int microCardCount = 0;
  int examQuestionCount = 0;
  String? id = fallbackId;
  String? title = fallbackTitle;
  String? description;
  String? provider;
  String? certificationId;
  String? certificationTitle;
  String? track;
  String? examCode = _deriveExamCodeFromFilename(filename);
  String? category;
  String? version;
  List<String> domains = const [];
  List<String> tags = const [];
  List<String> aliases = const [];
  bool isStarter = false;
  String? availabilityNote;

  if (decoded is Map<String, dynamic>) {
    id = _nonEmptyString(decoded['id']) ?? fallbackId;
    title =
        _nonEmptyString(decoded['title']) ??
        _nonEmptyString(decoded['name']) ??
        fallbackTitle;
    description = _nonEmptyString(decoded['description']);
    provider = _nonEmptyString(decoded['provider']);
    certificationId = _nonEmptyString(decoded['certificationId']);
    certificationTitle = _nonEmptyString(decoded['certificationTitle']);
    track = _nonEmptyString(decoded['track']);
    examCode = _nonEmptyString(decoded['examCode']) ?? examCode;
    category = _nonEmptyString(decoded['category']);
    version = _asString(decoded['version']);
    domains = _stringListOrEmpty(decoded['domains']);
    tags = _stringListOrEmpty(decoded['tags']);
    aliases = _stringListOrEmpty(decoded['aliases']);
    isStarter = (decoded['isStarter'] as bool?) ?? false;
    availabilityNote = _nonEmptyString(decoded['availabilityNote']);
  }

  _validateDeckMetadata(
    decoded,
    assetPath: assetPath,
    id: id,
    title: title,
    isStarter: isStarter,
    availabilityNote: availabilityNote,
    items: list,
  );

  final defaultContentType = _defaultContentTypeForDecoded(decoded);
  for (final item in list.whereType<Map>()) {
    final type =
        _nonEmptyString(item['contentType']) ??
        _nonEmptyString(item['type']) ??
        defaultContentType;
    if (type == 'exam_question') {
      examQuestionCount++;
    } else {
      microCardCount++;
    }
  }

  domains = domains.isNotEmpty ? domains : _deriveDomainsFromItems(list);
  category ??= _deriveCategoryFromItems(list);

  return DeckPackMeta(
    id: id,
    title: title,
    assetPath: assetPath,
    provider: provider,
    certificationId: certificationId,
    certificationTitle: certificationTitle,
    track: track,
    examCode: examCode,
    category: category,
    description: description,
    version: version,
    domains: domains,
    tags: tags,
    aliases: aliases,
    isStarter: isStarter,
    availabilityNote: availabilityNote,
    questionCount: list.length,
    microCardCount: microCardCount,
    examQuestionCount: examQuestionCount,
  );
}

List<DeckPackItem> _parseItemsFromDecoded(dynamic decoded) {
  final list = _extractItemsList(decoded);
  final defaultContentType = _defaultContentTypeForDecoded(decoded);
  final items = <DeckPackItem>[];
  final seenIds = <String>{};

  for (var index = 0; index < list.length; index++) {
    final raw = list[index];
    if (raw is! Map) {
      throw FormatException(
        'Invalid question at index $index: expected an object entry',
      );
    }

    try {
      final item = DeckPackItem.fromJsonWithDefaults(
        raw.cast<String, dynamic>(),
        defaultContentType: defaultContentType,
      );
      if (!seenIds.add(item.id)) {
        throw FormatException('Duplicate question id "${item.id}"');
      }
      items.add(item);
    } catch (e) {
      throw FormatException('Question ${index + 1}: $e');
    }
  }

  return items;
}

String _defaultContentTypeForDecoded(dynamic decoded) {
  if (decoded is Map<String, dynamic>) {
    return _nonEmptyString(decoded['defaultContentType']) ??
        _nonEmptyString(decoded['contentType']) ??
        (decoded.containsKey('questions') ? 'exam_question' : 'micro_card');
  }
  return 'micro_card';
}

List<String> _deriveDomainsFromItems(List<dynamic> items) {
  final domains =
      items
          .whereType<Map>()
          .map(
            (item) =>
                _nonEmptyString(item['domain']) ??
                _nonEmptyString(item['category']),
          )
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
  return domains;
}

List<String> _stringListOrEmpty(Object? value) {
  if (value == null) return const [];
  return _stringList(value);
}

const _supportedContentTypes = {'micro_card', 'exam_question'};

void _validateDeckMetadata(
  dynamic decoded, {
  required String? id,
  required String? title,
  required bool isStarter,
  required String? availabilityNote,
  required String assetPath,
  required List<dynamic> items,
}) {
  final issues = <String>[];
  int? declaredQuestionCount;

  if (decoded is Map<String, dynamic>) {
    if (_nonEmptyString(decoded['id']) == null) {
      issues.add('Missing required deck field "id"');
    }
    if (_nonEmptyString(decoded['title']) == null &&
        _nonEmptyString(decoded['name']) == null) {
      issues.add('Missing required deck field "title"');
    }
    if (decoded.containsKey('questionCount')) {
      try {
        declaredQuestionCount = _intValue(decoded['questionCount']);
        if (declaredQuestionCount < 0) {
          issues.add('"questionCount" must be zero or greater');
        }
      } catch (_) {
        issues.add('Invalid deck field "questionCount"');
      }
    }
  }

  if (id == null || id.trim().isEmpty) {
    issues.add('Deck id must be a non-empty string');
  }
  if (title == null || title.trim().isEmpty) {
    issues.add('Deck title must be a non-empty string');
  }
  if (items.isEmpty && !isStarter) {
    issues.add(
      'Deck has no questions/items. Use "isStarter": true for roadmap entries',
    );
  }
  if (isStarter &&
      (availabilityNote == null || availabilityNote.trim().isEmpty)) {
    issues.add('Starter decks must provide "availabilityNote"');
  }
  if (declaredQuestionCount != null && declaredQuestionCount != items.length) {
    issues.add(
      '"questionCount" ($declaredQuestionCount) does not match actual item count (${items.length})',
    );
  }

  if (issues.isNotEmpty) {
    throw FormatException(
      '${assetPath.split('/').last}: ${issues.join(' | ')}',
    );
  }
}
