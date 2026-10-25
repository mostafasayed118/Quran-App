import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';
import 'content_version.dart';
import 'search_index.dart';

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
    await _seedContentFromFile(db, seedFile, bundledVersion);
  } on Object catch (error, stackTrace) {
    dev.log('content refresh failed',
        name: 'quran_yahdi/db', error: error, stackTrace: stackTrace);
  } finally {
    if (seedFile.existsSync()) seedFile.deleteSync();
  }
}

/// The row swap of the content re-seed: the seed file is ATTACHed, the two
/// content tables are replaced in ONE transaction and the seed is DETACHed.
///
/// ATTACH/DETACH cannot run inside a transaction (SQLite rule) — keep them
/// outside; only the row swaps are transactional. The SQL runs on drift's
/// background isolate, never on the UI isolate.
Future<void> _seedContentFromFile(
  AppDatabase db,
  File seedFile,
  int bundledVersion,
) async {
  await db.customStatement('ATTACH DATABASE ? AS seed', [seedFile.path]);
  try {
    await db.transaction(() async {
      await db.customStatement('DELETE FROM ayahs');
      await db.customStatement('DELETE FROM surahs');
      await db.customStatement('INSERT INTO surahs SELECT * FROM seed.surahs');
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
}

/// Loads the bundled asset on a WORKER isolate.
///
/// The DB asset is ~3.3 MB; loading and writing it on the UI isolate costs
/// a boot-time frame stall and a full-size allocation on the isolate that
/// renders the app. [rootBundle] cannot be used on a background isolate (a
/// background isolate has no ServicesBinding), so the worker talks to the
/// engine's asset channel through [BackgroundIsolateBinaryMessenger] — the
/// very same `flutter/assets` message [PlatformAssetBundle] sends.
///
/// Returns null when the asset does not exist or the worker path is
/// unavailable (no root-isolate token, e.g. in a test VM); the caller then
/// falls back to the UI-isolate path so the boot never breaks.
Future<Uint8List?> _loadAssetOnWorker(
        String assetKey, RootIsolateToken token) =>
    Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      final encoded = utf8.encode(Uri(path: Uri.encodeFull(assetKey)).path);
      final asset = await BackgroundIsolateBinaryMessenger.instance
          .send('flutter/assets', ByteData.sublistView(encoded));
      if (asset == null) return null;
      return asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes);
    });

/// Writes [assetKey] to [target] without touching the UI isolate.
///
/// The write goes to a `.part` file that is renamed onto the target: a
/// failed write must never leave a half-written database behind. When the
/// worker path is unavailable or fails, the historical UI-isolate path runs
/// (identical behavior, including the error a missing asset raises).
Future<void> _writeAssetOffUiIsolate(File target, String assetKey) async {
  if (target.existsSync()) return;
  final token = ServicesBinding.rootIsolateToken;
  if (token != null) {
    try {
      final bytes = await _loadAssetOnWorker(assetKey, token);
      if (bytes != null) {
        await target.parent.create(recursive: true);
        final part = File('${target.path}.part');
        try {
          await part.writeAsBytes(bytes, flush: true);
          await part.rename(target.path);
        } finally {
          if (part.existsSync()) await part.delete();
        }
        return;
      }
    } on Object catch (error, stackTrace) {
      dev.log('db asset copy on the worker isolate failed',
          name: 'quran_yahdi/db', error: error, stackTrace: stackTrace);
    }
  }
  await copyDbAssetIfAbsent(
    target: target,
    assetKey: assetKey,
    loadAsset: rootBundle.load,
  );
}

/// The production content re-seed: the asset is loaded and written on a
/// worker isolate, the row swap runs on drift's background isolate. Same
/// rows, same transaction, same best-effort contract as
/// [ensureContentCurrent].
Future<void> _ensureContentCurrentOffUiIsolate(
  QueryExecutor executor,
  Directory tempDir,
) async {
  final db = AppDatabase(executor);
  final installed = await db.installedContentVersion();
  if (installed >= kContentVersion) return;
  final seedFile = File(p.join(tempDir.path, 'quran_yahdi.seed.tmp'));
  try {
    await _writeAssetOffUiIsolate(seedFile, dbAssetKey);
    await _seedContentFromFile(db, seedFile, kContentVersion);
  } on Object catch (error, stackTrace) {
    dev.log('content refresh failed',
        name: 'quran_yahdi/db', error: error, stackTrace: stackTrace);
  } finally {
    if (seedFile.existsSync()) seedFile.deleteSync();
  }
}

/// Opens the app database.
///
/// The UI isolate only ever receives the executor: the asset copy and the
/// content re-seed run on a worker isolate (and on drift's background
/// isolate for the SQL), so the 3.3 MB asset never lands on the isolate
/// that renders the first frame.
Future<QueryExecutor> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'quran_yahdi.sqlite'));
  await _writeAssetOffUiIsolate(file, dbAssetKey);
  final executor = NativeDatabase.createInBackground(
    file,
    setup: (database) {
      database.execute('PRAGMA journal_mode = WAL;');
      database.execute('PRAGMA synchronous = NORMAL;');
    },
  );
  await _ensureContentCurrentOffUiIsolate(executor, dir);
  await _ensureSearchIndex(executor);
  return executor;
}

/// Builds the derived Quran search index when it is missing or stale.
///
/// Runs after the content refresh (same best-effort contract): a failure
/// logs and keeps whatever index was there — boot must never crash.
Future<void> _ensureSearchIndex(QueryExecutor executor) async {
  try {
    await ensureQuranSearchIndex(AppDatabase(executor));
  } on Object catch (error, stackTrace) {
    dev.log('search index build failed',
        name: 'quran_yahdi/db', error: error, stackTrace: stackTrace);
  }
}
