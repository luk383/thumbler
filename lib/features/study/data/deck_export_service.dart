import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'deck_pack.dart';

class DeckExportService {
  const DeckExportService();

  Future<File> exportDeckToJsonFile(DeckPackMeta meta) async {
    final raw = await DeckPack.loadRawJson(meta);
    if (raw == null) {
      throw FormatException('Missing deck data for "${meta.title}"');
    }

    final exportsDir = await _exportsDirectory();
    final file = File('${exportsDir.path}/${_safeFilename(meta)}.json');
    await file.writeAsString(raw);
    return file;
  }

  Future<void> shareDeck(DeckPackMeta meta) async {
    final file = await exportDeckToJsonFile(meta);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: meta.title,
        text: 'Wolf Lab deck: ${meta.title}',
      ),
    );
  }

  Future<void> exportDeck(DeckPackMeta meta) async {
    final file = await exportDeckToJsonFile(meta);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '${meta.title} JSON export',
        text: 'Exported Wolf Lab deck JSON: ${meta.title}',
      ),
    );
  }

  Future<Directory> _exportsDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${baseDir.path}/deck_exports');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _safeFilename(DeckPackMeta meta) {
    final slug = meta.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return slug.isEmpty ? meta.id : slug;
  }
}
