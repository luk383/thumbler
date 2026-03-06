import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/study_item.dart';

class DeckPackMeta {
  const DeckPackMeta({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.emoji,
    this.estimatedItemCount,
    this.invalidJsonMessage,
  });

  final String id;
  final String name;
  final String description;
  final String assetPath;
  final String emoji;
  final int? estimatedItemCount;
  final String? invalidJsonMessage;

  bool get hasInvalidJson => invalidJsonMessage != null;

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
      final fallbackName = _titleFromFilename(filename);
      int? count;
      String? invalidJsonMessage;
      String id = fallbackId;
      String name = fallbackName;
      String description = filename;
      try {
        final raw = await rootBundle.loadString(path);
        final decoded = jsonDecode(raw);
        final list = _extractItemsList(decoded);
        count = list.length;
        if (decoded is Map<String, dynamic>) {
          id = _asString(decoded['id'])?.trim().isNotEmpty == true
              ? _asString(decoded['id'])!.trim()
              : fallbackId;
          name = _asString(decoded['name'])?.trim().isNotEmpty == true
              ? _asString(decoded['name'])!.trim()
              : fallbackName;
          description =
              _asString(decoded['description'])?.trim().isNotEmpty == true
              ? _asString(decoded['description'])!.trim()
              : filename;
        }
      } catch (e) {
        invalidJsonMessage = e.toString();
      }

      metas.add(
        DeckPackMeta(
          id: id,
          name: name,
          description: description,
          assetPath: path,
          emoji: '📦',
          estimatedItemCount: count,
          invalidJsonMessage: invalidJsonMessage,
        ),
      );
    }
    metas.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return metas;
  }
}

class DeckPackItem {
  const DeckPackItem({
    required this.id,
    required this.contentType,
    required this.category,
    this.topic,
    this.subtopic,
    this.objectiveId,
    required this.promptText,
    this.explanationText,
    required this.options,
    required this.correctAnswerIndex,
    this.difficulty,
  });

  final String id;
  final String contentType; // "micro_card" | "exam_question"
  final String category;
  final String? topic;
  final String? subtopic;
  final String? objectiveId;
  final String promptText;
  final String? explanationText;
  final List<String> options;
  final int correctAnswerIndex;
  final int? difficulty;

  factory DeckPackItem.fromJson(Map<String, dynamic> j) {
    final options = _stringList(j['options']);
    final correctAnswerIndex = _intValue(j['correctAnswerIndex']);
    if (options.isEmpty) {
      throw const FormatException(
        'Invalid "options": expected a non-empty list',
      );
    }
    if (correctAnswerIndex < 0 || correctAnswerIndex >= options.length) {
      throw const FormatException(
        'Invalid "correctAnswerIndex": out of range for "options"',
      );
    }
    return DeckPackItem(
      id: _requiredString(j, 'id'),
      contentType: _asString(j['contentType']) ?? 'micro_card',
      category: _requiredString(j, 'category'),
      topic: _asString(j['topic']),
      subtopic: _asString(j['subtopic']),
      objectiveId: _asString(j['objectiveId']),
      promptText: _requiredString(j, 'promptText'),
      explanationText: _asString(j['explanationText']),
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      difficulty: _nullableIntValue(j['difficulty']),
    );
  }

  StudyItem toStudyItem() => StudyItem(
    id: id,
    contentType: contentType == 'exam_question'
        ? ContentType.examQuestion
        : ContentType.microCard,
    category: category,
    topic: topic,
    subtopic: subtopic,
    objectiveId: objectiveId,
    promptText: promptText,
    explanationText: explanationText,
    options: options,
    correctAnswerIndex: correctAnswerIndex,
    difficulty: difficulty,
  );
}

class DeckPack {
  const DeckPack({required this.meta, required this.items});

  final DeckPackMeta meta;
  final List<DeckPackItem> items;

  static Future<DeckPack> load(DeckPackMeta meta) async {
    final raw = await rootBundle.loadString(meta.assetPath);
    final decoded = jsonDecode(raw);
    final list = _extractItemsList(decoded);
    final items = list
        .map((e) => DeckPackItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return DeckPack(meta: meta, items: items);
  }
}

class ImportResult {
  const ImportResult({required this.added, required this.skipped});

  final int added;
  final int skipped;

  @override
  String toString() => 'Imported $added, skipped $skipped';
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
    return v.map((e) => e.toString()).toList();
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

List<dynamic> _extractItemsList(dynamic decoded) {
  if (decoded is List) return decoded;
  if (decoded is Map<String, dynamic>) {
    final items = decoded['items'];
    if (items is List) return items;
  }
  throw const FormatException('Deck JSON must be an array or {"items":[...]}');
}
