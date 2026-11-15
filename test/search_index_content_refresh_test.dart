import 'dart:io';

import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/content_version.dart';
import 'package:quran_yahdi/core/db/search_index.dart';

import 'support/test_db.dart';

AyahsCompanion _ayah(int id, String text) => AyahsCompanion.insert(
      id: Value(id),
      surahId: 1,
      numberInSurah: id,
      juz: 1,
      page: 1,
      textUthmani: text,
      textImlaei: text,
    );

Future<void> _setInstalledVersion(AppDatabase db, int version) =>
    db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: kContentVersionKey,
            value: '$version',
          ),
        );

Future<void> _setAyahText(AppDatabase db, String text) =>
    (db.update(db.ayahs)..where((a) => a.id.equals(1)))
        .write(AyahsCompanion(textImlaei: Value(text)));

Future<String> _indexedText(AppDatabase db) async {
  final row = await db
      .customSelect('SELECT text_norm FROM ayah_search WHERE rowid = 1')
      .getSingle();
  return row.read<String>('text_norm');
}

Future<int?> _contentStamp(AppDatabase db) async {
  final row = await db.customSelect(
      'SELECT value FROM settings_table WHERE key = ?',
      variables: [const Variable(kSearchIndexContentKey)]).getSingleOrNull();
  return row == null ? null : int.tryParse(row.read<String>('value'));
}

void main() {
  test('a completed content refresh rebuilds an index built from older content',
      () async {
    final db = newTestDb();
    await db.into(db.ayahs).insert(_ayah(1, 'النص القديم'));
    await _setInstalledVersion(db, 1);
    await ensureQuranSearchIndex(db);

    // The first boot after the update failed to refresh the content, so the
    // index was built from v1 while the app constant already said v2. A later
    // boot completes the refresh: the ayah text changes to v2.
    await _setAyahText(db, 'النص الجديد');
    await _setInstalledVersion(db, 2);

    await ensureQuranSearchIndex(db);

    expect(await _indexedText(db), contains('الجديد'),
        reason: 'the stamp must follow the installed content version; with the '
            'app constant it stays "current" and the index is never rebuilt');
  });

  test('an install with only the format stamp rebuilds exactly once', () async {
    final db = newTestDb();
    await db.into(db.ayahs).insert(_ayah(1, 'النص أ'));
    await _setInstalledVersion(db, kContentVersion);
    await ensureQuranSearchIndex(db);
    expect(await _contentStamp(db), kContentVersion);

    // Every install before this change has the format stamp but no content
    // stamp. Reproduce that shape, then change the text without moving the
    // version: the missing stamp must force one rebuild.
    await db.customStatement(
      'DELETE FROM settings_table WHERE key = ?',
      [kSearchIndexContentKey],
    );
    await _setAyahText(db, 'النص ب');

    await ensureQuranSearchIndex(db);
    expect(await _indexedText(db), contains('ب'),
        reason: 'a missing content stamp is a rebuild, not a skip');
    expect(await _contentStamp(db), kContentVersion);

    // Stamped now: a silent text change without a version bump is the
    // documented boundary and must not rebuild on every boot.
    await _setAyahText(db, 'النص ج');
    await ensureQuranSearchIndex(db);
    expect(await _indexedText(db), contains('ب'),
        reason: 'a stamped index is not rebuilt on every boot');
  });

  test('the rebuild runs through the injected runner, the skip does not',
      () async {
    final db = newTestDb();
    await db.into(db.ayahs).insert(_ayah(1, 'نص'));
    var runs = 0;

    await ensureQuranSearchIndex(db, run: <R>(R Function() computation) async {
      runs++;
      return computation();
    });
    expect(runs, 1, reason: 'the normalization must leave the caller isolate');

    await ensureQuranSearchIndex(db, run: <R>(R Function() computation) async {
      runs++;
      return computation();
    });
    expect(runs, 1, reason: 'a stamped index is not rebuilt');
  });

  test('the shipped asset carries the content stamp (fresh installs skip)',
      () async {
    final dir = Directory.systemTemp.createTempSync('qy_search_content_stamp');
    addTearDown(() => dir.deleteSync(recursive: true));
    final copy = File(p.join(dir.path, 'asset.sqlite'))
      ..writeAsBytesSync(File('assets/db/quran.sqlite').readAsBytesSync());
    final db = AppDatabase(NativeDatabase(copy));
    addTearDown(db.close);

    await ensureQuranSearchIndex(
      db,
      run: <R>(_) => throw StateError('the shipped index must not rebuild'),
    );
  });
}
