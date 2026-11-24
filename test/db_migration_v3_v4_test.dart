import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';

void main() {
  test(
    'a v3 file upgrades to v4 with the feelings table and old data intact',
    () async {
      final dir = await Directory.systemTemp.createTemp('qy_v3v4_');
      final file = File('${dir.path}/app.db');
      try {
        final v3 = AppDatabase(NativeDatabase(file));
        try {
          await v3
              .into(v3.bookmarks)
              .insert(BookmarksCompanion.insert(ayahId: 42));
          await v3.customStatement('PRAGMA user_version = 3');
        } finally {
          await v3.close();
        }

        final v4 = AppDatabase(NativeDatabase(file));
        try {
          expect(await _userVersion(v4), 4);
          final tables = await v4
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type='table' AND name='feeling_saved_verses'",
              )
              .get();
          expect(tables, hasLength(1), reason: 'new table exists');
          final bookmarks = await v4.select(v4.bookmarks).get();
          expect(bookmarks.single.ayahId, 42, reason: 'old data preserved');
          expect(await _indexExists(v4, 'idx_feeling_saved_ayah'), isTrue);
        } finally {
          await v4.close();
        }
      } finally {
        dir.deleteSync(recursive: true);
      }
    },
  );
}

Future<int> _userVersion(AppDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}

Future<bool> _indexExists(AppDatabase db, String name) async {
  final row = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
        variables: [Variable.withString(name)],
      )
      .getSingleOrNull();
  return row != null;
}
