import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wolf_lab/features/bookmarks/data/bookmarks_repository.dart';

void main() {
  late Box box;
  late HiveBookmarksRepository repository;
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('wolf_lab_bookmarks_test');
    Hive.init(hiveDir.path);
    box = await Hive.openBox('bookmarks_test_box');
    repository = HiveBookmarksRepository(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('stores bookmarks per active deck', () async {
    await repository.toggleBookmark('q1', deckId: 'security-plus');
    await repository.toggleBookmark('q1', deckId: 'aws-clf');

    expect(
      repository.getBookmarkedIds(deckId: 'security-plus'),
      equals(['q1']),
    );
    expect(repository.getBookmarkedIds(deckId: 'aws-clf'), equals(['q1']));
    expect(repository.getBookmarkedIds(deckId: null), isEmpty);
  });

  test('keeps legacy unscoped bookmarks visible only for legacy deckless data', () async {
    await box.put('ids', ['legacy-q1']);

    expect(repository.getBookmarkedIds(deckId: null), equals(['legacy-q1']));
    expect(repository.getBookmarkedIds(deckId: 'security-plus'), isEmpty);
    expect(
      repository.getBookmarkedIds(
        deckId: 'security-plus',
        includeLegacy: true,
      ),
      equals(['legacy-q1']),
    );
  });
}
