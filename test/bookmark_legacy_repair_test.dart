import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';

void main() {
  test('a legacy database with duplicate bookmarks is repaired on every open',
      () async {
    final legacy = await _legacyDbFile();
    final file = legacy.file;

    for (var open = 1; open <= 2; open++) {
      final db = AppDatabase(NativeDatabase(file));
      try {
        final rows = await (db.select(db.bookmarks)
              ..orderBy([(b) => OrderingTerm.asc(b.ayahId)]))
            .get();
        expect(rows, hasLength(2),
            reason: 'open $open must keep one row per ayah');
        expect(rows.map((r) => r.ayahId), [8, 9],
            reason: 'open $open must keep both distinct ayahs');
        expect(rows[0].id, legacy.oldestAyah8,
            reason: 'open $open must keep the lowest id for ayah 8');
        expect(rows[1].id, legacy.oldestAyah9,
            reason: 'open $open must keep the lowest id for ayah 9');
        await expectLater(
          db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 8)),
          throwsA(isA<SqliteException>()),
          reason: 'open $open must reject a duplicate bookmark',
        );
      } finally {
        await db.close();
      }
    }
  });
}

/// Creates a file-backed database that looks like a pre-fix install: the
/// non-unique index would have allowed two rows for the same ayah, and the
/// duplicate rows already exist on disk.
typedef _LegacyDb = ({File file, int oldestAyah8, int oldestAyah9});

Future<_LegacyDb> _legacyDbFile() async {
  final dir = await Directory.systemTemp.createTemp('qy_bookmark_repair');
  addTearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  final file = File('${dir.path}${Platform.pathSeparator}legacy.sqlite');

  final db = AppDatabase(NativeDatabase(file));
  try {
    await db.customStatement('DROP INDEX IF EXISTS idx_bookmarks_ayah');
    final oldestAyah8 = await db
        .into(db.bookmarks)
        .insert(BookmarksCompanion.insert(ayahId: 8));
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 8));
    final oldestAyah9 = await db
        .into(db.bookmarks)
        .insert(BookmarksCompanion.insert(ayahId: 9));
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 9));
    expect(await db.select(db.bookmarks).get(), hasLength(4),
        reason: 'the legacy file must actually contain duplicate rows');
    return (file: file, oldestAyah8: oldestAyah8, oldestAyah9: oldestAyah9);
  } finally {
    await db.close();
  }
}
