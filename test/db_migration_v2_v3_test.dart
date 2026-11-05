import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';

void main() {
  test('a v2 file with duplicate rows upgrades to v3 and repairs them',
      () async {
    final file = await _tempDbFile();

    final v2 = AppDatabase(NativeDatabase(file));
    try {
      // One good row of each user-visible identity.
      await v2.into(v2.bookmarks).insert(BookmarksCompanion.insert(ayahId: 7));
      await v2.into(v2.downloads).insert(
            DownloadsCompanion.insert(
              reciterId: 'r1',
              surahId: 1,
              status: 'done',
              path: '/audio/r1/001.mp3',
            ),
          );

      // Simulate a file written before the unique indexes existed: drop them
      // and insert the duplicates the old read-then-write paths could leave.
      await v2.customStatement('DROP INDEX idx_bookmarks_ayah');
      await v2.customStatement('DROP INDEX idx_downloads_lookup');
      await v2.into(v2.bookmarks).insert(BookmarksCompanion.insert(ayahId: 7));
      await v2.into(v2.downloads).insert(
            DownloadsCompanion.insert(
              reciterId: 'r1',
              surahId: 1,
              status: 'queued',
              path: '',
            ),
          );
      await v2.customStatement('PRAGMA user_version = 2');
    } finally {
      await v2.close();
    }

    // Reopening runs onUpgrade(2 → 3): repair, then the unique indexes.
    final v3 = AppDatabase(NativeDatabase(file));
    try {
      expect(await _userVersion(v3), v3.schemaVersion);

      final bookmarks = await v3.select(v3.bookmarks).get();
      expect(bookmarks, hasLength(1), reason: 'one bookmark per ayah');
      expect(bookmarks.single.ayahId, 7);

      final downloads = await v3.select(v3.downloads).get();
      expect(downloads, hasLength(1), reason: 'one row per (reciter, surah)');
      expect(
        downloads.single.path,
        '/audio/r1/001.mp3',
        reason: 'the oldest row wins: it is the one that owns the file',
      );

      expect(await _uniqueIndexExists(v3, 'idx_bookmarks_ayah'), isTrue);
      expect(await _uniqueIndexExists(v3, 'idx_downloads_lookup'), isTrue);
    } finally {
      await v3.close();
    }
  });

  test('a fresh v3 file carries every derived object', () async {
    final file = await _tempDbFile();
    final db = AppDatabase(NativeDatabase(file));
    try {
      expect(await _userVersion(db), 3);
      expect(await _tableExists(db, 'ayah_search'), isTrue);
      expect(await _tableExists(db, 'hadith_entries'), isTrue);
      expect(await _indexExists(db, 'idx_ayahs_surah'), isTrue);
      expect(await _indexExists(db, 'idx_ayahs_page'), isTrue);
      expect(await _uniqueIndexExists(db, 'idx_bookmarks_ayah'), isTrue);
      expect(await _uniqueIndexExists(db, 'idx_downloads_lookup'), isTrue);
      expect(await _indexExists(db, 'idx_downloads_status'), isTrue);
    } finally {
      await db.close();
    }
  });

  test('reopening a v3 file keeps the rows and adds nothing', () async {
    final file = await _tempDbFile();

    final first = AppDatabase(NativeDatabase(file));
    try {
      await first.into(first.bookmarks).insert(
            BookmarksCompanion.insert(ayahId: 42),
          );
      await first.into(first.settingsTable).insert(
            SettingsTableCompanion.insert(key: 'selected_city', value: 'cairo'),
          );
    } finally {
      await first.close();
    }

    final second = AppDatabase(NativeDatabase(file));
    try {
      expect(await _userVersion(second), 3);
      expect(await second.select(second.bookmarks).get(), hasLength(1));
      expect(await second.select(second.settingsTable).get(), hasLength(1));
    } finally {
      await second.close();
    }
  });
}

Future<File> _tempDbFile() async {
  final dir = await Directory.systemTemp.createTemp('qy_db_v2_v3');
  addTearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  return File('${dir.path}${Platform.pathSeparator}app.sqlite');
}

Future<int> _userVersion(AppDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}

Future<bool> _tableExists(AppDatabase db, String name) async {
  final rows = await db.customSelect(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    variables: [Variable.withString(name)],
  ).get();
  return rows.isNotEmpty;
}

Future<String?> _indexSql(AppDatabase db, String name) async {
  final row = await db.customSelect(
    "SELECT sql FROM sqlite_master WHERE type = 'index' AND name = ?",
    variables: [Variable.withString(name)],
  ).getSingleOrNull();
  return row?.readNullable<String>('sql');
}

Future<bool> _indexExists(AppDatabase db, String name) async =>
    await _indexSql(db, name) != null;

Future<bool> _uniqueIndexExists(AppDatabase db, String name) async =>
    (await _indexSql(db, name) ?? '').toUpperCase().contains('UNIQUE');
