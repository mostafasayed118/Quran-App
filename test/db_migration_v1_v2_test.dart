import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';

void main() {
  test('v1 → v2 upgrade creates reciters and keeps existing rows', () async {
    final file = await _tempDbFile();
    final db = AppDatabase(NativeDatabase(file));
    late final Bookmark bookmarkBefore;
    late final SettingsTableData settingBefore;

    try {
      await _seedUserRows(db);
      bookmarkBefore = await db.select(db.bookmarks).getSingle();
      settingBefore = await db.select(db.settingsTable).getSingle();

      // Turn the freshly created v2 file into an exact v1 file: the only v2
      // delta is the reciters table.
      await _downgradeToV1(db);

      expect(await _tableExists(db, 'reciters'), isFalse);
      expect(await _userVersion(db), 1);
    } finally {
      await db.close();
    }

    // Reopening runs onUpgrade(1 → 2); createAll must be safe on the v1 file.
    final reopened = AppDatabase(NativeDatabase(file));
    try {
      expect(
        await _tableExists(reopened, 'reciters'),
        isTrue,
        reason: 'onUpgrade(from: 1) must create the reciters table',
      );
      expect(await reopened.select(reopened.reciters).get(), isEmpty);
      expect(await reopened.select(reopened.bookmarks).getSingle(),
          bookmarkBefore);
      expect(await reopened.select(reopened.settingsTable).getSingle(),
          settingBefore);
      expect(await _userVersion(reopened), 2);
    } finally {
      await reopened.close();
    }
  });

  test('reopening the upgraded v2 file is a no-op with data intact', () async {
    final file = await _tempDbFile();

    final first = AppDatabase(NativeDatabase(file));
    late final Bookmark bookmarkBefore;
    late final SettingsTableData settingBefore;
    try {
      await _seedUserRows(first);
      bookmarkBefore = await first.select(first.bookmarks).getSingle();
      settingBefore = await first.select(first.settingsTable).getSingle();
      await _downgradeToV1(first);
    } finally {
      await first.close();
    }

    final upgraded = AppDatabase(NativeDatabase(file));
    try {
      expect(await _tableExists(upgraded, 'reciters'), isTrue);
      expect(await _userVersion(upgraded), 2);
    } finally {
      await upgraded.close();
    }

    // Third open: schema version already matches, so no migration runs.
    final reopened = AppDatabase(NativeDatabase(file));
    try {
      expect(await _userVersion(reopened), 2);
      expect(await reopened.select(reopened.reciters).get(), isEmpty);
      expect(await reopened.select(reopened.bookmarks).getSingle(),
          bookmarkBefore);
      expect(await reopened.select(reopened.settingsTable).getSingle(),
          settingBefore);
    } finally {
      await reopened.close();
    }
  });
}

Future<File> _tempDbFile() async {
  final dir = await Directory.systemTemp.createTemp('qy_db_migration');
  addTearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  return File('${dir.path}${Platform.pathSeparator}app.sqlite');
}

Future<void> _seedUserRows(AppDatabase db) async {
  await db.into(db.bookmarks).insert(
        BookmarksCompanion.insert(ayahId: 42),
      );
  await db.into(db.settingsTable).insert(
        SettingsTableCompanion.insert(key: 'last_read_page', value: '42'),
      );
}

/// Leaves the open database looking like a real v1 file on disk.
Future<void> _downgradeToV1(AppDatabase db) async {
  await db.customStatement('DROP TABLE reciters');
  await db.customStatement('PRAGMA user_version = 1');
}

Future<bool> _tableExists(AppDatabase db, String name) async {
  final rows = await db.customSelect(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    variables: [Variable.withString(name)],
  ).get();
  return rows.isNotEmpty;
}

Future<int> _userVersion(AppDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}
