import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;
import 'package:file_picker/file_picker.dart';

class BackupService {
  static const _version = 1;
  static const _exportableBoxes = [
    'goals_box',
    'habits_box',
    'journal_box',
    'reflection_box',
    'reading_box',
  ];

  /// Export all growth data to a JSON file and share it.
  static Future<void> exportAndShare(BuildContext context) async {
    try {
      final data = <String, dynamic>{
        'version': _version,
        'exportedAt': DateTime.now().toIso8601String(),
      };

      for (final boxName in _exportableBoxes) {
        final box = Hive.box(boxName);
        final entries = <String, dynamic>{};
        for (final key in box.keys) {
          final value = box.get(key);
          if (value is Map) {
            entries[key.toString()] = Map<String, dynamic>.from(value);
          }
        }
        data[boxName] = entries;
      }

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().substring(0, 10);
      final file = File('${dir.path}/wolflab_backup_$timestamp.json');
      await file.writeAsString(json);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Wolf Lab Backup $timestamp',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore export: $e')),
        );
      }
    }
  }

  /// Import data from a JSON backup file.
  static Future<bool> importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return false;

      final path = result.files.first.path;
      if (path == null) return false;

      final content = await File(path).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final version = data['version'] as int? ?? 0;
      if (version != _version) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formato backup non compatibile')),
          );
        }
        return false;
      }

      for (final boxName in _exportableBoxes) {
        if (!data.containsKey(boxName)) continue;
        final box = Hive.box(boxName);
        final entries = data[boxName] as Map<String, dynamic>;
        for (final entry in entries.entries) {
          await box.put(
            entry.key,
            Map<dynamic, dynamic>.from(entry.value as Map),
          );
        }
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore import: $e')),
        );
      }
      return false;
    }
  }
}
