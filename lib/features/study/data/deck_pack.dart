import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/study_item.dart';

// ---------------------------------------------------------------------------
// Pack catalogue (static list — no backend yet)
// TODO: fetch remote pack catalogue from Supabase (decks v2)
// ---------------------------------------------------------------------------

class DeckPackMeta {
  const DeckPackMeta({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.emoji,
  });

  final String id;
  final String name;
  final String description;

  /// Path within the Flutter asset bundle, e.g. "assets/decks/starter_pack.json".
  final String assetPath;
  final String emoji;

  static const List<DeckPackMeta> localPacks = [
    DeckPackMeta(
      id: 'starter_pack_v1',
      name: 'Starter Pack',
      description:
          '20 fascinating facts across science, history, psychology, and technology.',
      assetPath: 'assets/decks/starter_pack.json',
      emoji: '🌟',
    ),
    DeckPackMeta(
      id: 'exam_pack_sample_v1',
      name: 'Exam Pack Sample',
      description: '20 challenging exam-style questions to test your knowledge.',
      assetPath: 'assets/decks/exam_pack_sample.json',
      emoji: '🎯',
    ),
  ];
}

// ---------------------------------------------------------------------------
// DeckPackItem — mirrors the JSON schema
// ---------------------------------------------------------------------------

class DeckPackItem {
  const DeckPackItem({
    required this.id,
    required this.contentType,
    required this.category,
    this.topic,
    required this.promptText,
    this.explanationText,
    required this.options,
    required this.correctAnswerIndex,
  });

  final String id;
  final String contentType; // "micro_card" | "exam_question"
  final String category;
  final String? topic;
  final String promptText;
  final String? explanationText;
  final List<String> options;
  final int correctAnswerIndex;

  factory DeckPackItem.fromJson(Map<String, dynamic> j) => DeckPackItem(
        id: j['id'] as String,
        contentType: j['contentType'] as String? ?? 'micro_card',
        category: j['category'] as String,
        topic: j['topic'] as String?,
        promptText: j['promptText'] as String,
        explanationText: j['explanationText'] as String?,
        options: (j['options'] as List).map((e) => e as String).toList(),
        correctAnswerIndex: (j['correctAnswerIndex'] as num).toInt(),
      );

  StudyItem toStudyItem() => StudyItem(
        id: id,
        contentType: contentType == 'exam_question'
            ? ContentType.examQuestion
            : ContentType.microCard,
        category: category,
        topic: topic,
        promptText: promptText,
        explanationText: explanationText,
        options: options,
        correctAnswerIndex: correctAnswerIndex,
      );
}

// ---------------------------------------------------------------------------
// DeckPack — loaded and parsed deck
// ---------------------------------------------------------------------------

class DeckPack {
  const DeckPack({required this.meta, required this.items});

  final DeckPackMeta meta;
  final List<DeckPackItem> items;

  static Future<DeckPack> load(DeckPackMeta meta) async {
    final raw = await rootBundle.loadString(meta.assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final items = (json['items'] as List)
        .map((e) => DeckPackItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return DeckPack(meta: meta, items: items);
  }
}

// ---------------------------------------------------------------------------
// ImportResult
// ---------------------------------------------------------------------------

class ImportResult {
  const ImportResult({required this.added, required this.skipped});

  final int added;
  final int skipped;

  @override
  String toString() => '$added added · $skipped already in deck';
}
