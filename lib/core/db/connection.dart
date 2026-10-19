import 'dart:developer' as dev;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'content_version.dart';

const dbAssetKey = 'assets/db/quran.sqlite';

@visibleForTesting
Future<void> copyDbAssetIfAbsent({
  required File target,
  required String assetKey,
  required Future<ByteData> Function(String) loadAsset,
}) async {
  if (target.existsSync()) return;
  await target.parent.create(recursive: true);
  final data = await loadAsset(assetKey);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  await target.writeAsBytes(bytes, flush: true);
}

/// Re-seeds the two content tables (`surahs`/`ayahs`) from the bundled asset
/// when the installed content version is older than [bundledVersion]. User
/// tables are never touched; ayah ids are stable so bookmarks stay valid.
/// Best-effort: a failure logs and keeps the previous content (boot must
/// never crash — house discipline, same class as the reminder boot glue).
@visibleForTesting
Future<void> ensureContentCurrent(
  QueryExecutor executor, {
  required Future<ByteData> Function(String assetKey) loadAsset,
  required Directory tempDir,
  int bundledVersion = kContentVersion,
}) async {
  final db = AppDatabase(executor);
  final installed = await db.installedContentVersion();
  if (installed >= bundledVersion) return;
  final seedFile = File(p.join(tempDir.path, 'quran_yahdi.seed.tmp'));
  try {
    final data = await loadAsset(dbAssetKey);
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await seedFile.writeAsBytes(bytes, flush: true);
    // ATTACH/DETACH cannot run inside a transaction (SQLite rule) — keep them
    // outside; only the row swaps are transactional.
    await db.customStatement('ATTACH DATABASE ? AS seed', [seedFile.path]);
    try {
      await db.transaction(() async {
        await db.customStatement('DELETE FROM ayahs');
        await db.customStatement('DELETE FROM surahs');
        await db
            .customStatement('INSERT INTO surahs SELECT * FROM seed.surahs');
        await db.customStatement('INSERT INTO ayahs SELECT * FROM seed.ayahs');
        // INSERT OR REPLACE, not upsert syntax: API 24 devices ship an old
        // system SQLite where ON CONFLICT DO UPDATE is unavailable.
        await db.customStatement(
          'INSERT OR REPLACE INTO settings_table(key, value) VALUES (?, ?)',
          [kContentVersionKey, '$bundledVersion'],
        );
      });
    } finally {
      await db.customStatement('DETACH DATABASE seed');
    }
  } on Object catch (error, stackTrace) {
    dev.log('content refresh failed',
        name: 'quran_yahdi/db', error: error, stackTrace: stackTrace);
  } finally {
    if (seedFile.existsSync()) seedFile.deleteSync();
  }
}

Future<QueryExecutor> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'quran_yahdi.sqlite'));
  await copyDbAssetIfAbsent(
    target: file,
    assetKey: dbAssetKey,
    loadAsset: rootBundle.load,
  );
  final executor = NativeDatabase.createInBackground(
    file,
    setup: (database) {
      database.execute('PRAGMA journal_mode = WAL;');
      database.execute('PRAGMA synchronous = NORMAL;');
    },
  );
  await ensureContentCurrent(executor,
      loadAsset: rootBundle.load, tempDir: dir);
  return executor;
}
