import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_meta.dart';
import 'package:quran_yahdi/features/quran/data/bookmark_meta_repository.dart';

import 'support/test_db.dart';

void main() {
  test('the metadata store defaults to empty and round-trips', () async {
    final db = newTestDb();
    final repo = BookmarkMetaRepository(db);

    expect(await repo.load(), isEmpty);

    await repo.save({
      9: const BookmarkMetaEntry(folder: 'تفسير', note: 'ملاحظة'),
    });

    expect(
      await BookmarkMetaRepository(db).load(),
      {9: const BookmarkMetaEntry(folder: 'تفسير', note: 'ملاحظة')},
    );
  });

  test('normalize trims and drops entries with no folder and no note',
      () async {
    final normalized = BookmarkMetaRepository.normalize({
      1: const BookmarkMetaEntry(folder: '  تفسير  ', note: '  '),
      2: const BookmarkMetaEntry(folder: ' ', note: ' '),
      3: const BookmarkMetaEntry(note: 'ملاحظة'),
    });

    expect(normalized, {
      1: const BookmarkMetaEntry(folder: 'تفسير'),
      3: const BookmarkMetaEntry(note: 'ملاحظة'),
    });
  });

  test('malformed stored JSON degrades to empty', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: BookmarkMetaRepository.key,
            value: 'not-json',
          ),
        );

    expect(await BookmarkMetaRepository(db).load(), isEmpty);

    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: BookmarkMetaRepository.key,
            value: '{"9":{"folder":"تفسير"},"bad":{}}',
          ),
        );

    expect(
      await BookmarkMetaRepository(db).load(),
      {9: const BookmarkMetaEntry(folder: 'تفسير')},
    );
  });
}
