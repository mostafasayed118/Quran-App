import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';

import 'support/test_db.dart';

const String _reciterId = '51-53';

/// One downloads row for [surahId] of the only reciter these tests use.
DownloadsCompanion _download({int surahId = 1}) => DownloadsCompanion.insert(
      reciterId: _reciterId,
      surahId: surahId,
      status: 'done',
      path: '',
      bytes: const Value(0),
    );

void main() {
  test('a duplicate (reciter, surah) insert is rejected by the database',
      () async {
    final db = newTestDb();
    await db.into(db.downloads).insert(_download());

    await expectLater(
      db.into(db.downloads).insert(_download()),
      throwsA(isA<SqliteException>()),
      reason: 'the (reciter_id, surah_id) pair is unique',
    );
    expect(await db.select(db.downloads).get(), hasLength(1));
  });

  test('a legacy file with duplicate download rows is repaired on every open',
      () async {
    final legacy = await _legacyDownloadsDbFile();

    for (var open = 1; open <= 2; open++) {
      final db = AppDatabase(NativeDatabase(legacy.file));
      try {
        final rows = await db.select(db.downloads).get();
        expect(rows, hasLength(1),
            reason: 'open $open must collapse the duplicate pair');
        expect(rows.single.id, legacy.oldestId,
            reason: 'open $open must keep the lowest id of the pair');
        expect(rows.single.reciterId, _reciterId);
        expect(rows.single.surahId, 1);
        await expectLater(
          db.into(db.downloads).insert(_download()),
          throwsA(isA<SqliteException>()),
          reason: 'open $open must reject a duplicate download row',
        );
      } finally {
        await db.close();
      }
    }
  });

  test('two concurrent downloads for one pair leave exactly one row', () async {
    final harness = await _Harness.start();

    await Future.wait([
      _settle(harness.downloader
          .downloadSurah(reciter: harness.reciter, surahNumber: 1)),
      _settle(harness.downloader
          .downloadSurah(reciter: harness.reciter, surahNumber: 1)),
    ]);

    expect(await harness.db.select(harness.db.downloads).get(), hasLength(1));
    final row = await (harness.db.select(harness.db.downloads)
          ..where((d) => d.reciterId.equals(_reciterId) & d.surahId.equals(1)))
        .getSingle();
    expect(row.reciterId, _reciterId);
    expect(row.surahId, 1);
  });

  test('a second download for another surah still creates its own row',
      () async {
    final harness = await _Harness.start();

    await harness.downloader
        .downloadSurah(reciter: harness.reciter, surahNumber: 1);
    await harness.downloader
        .downloadSurah(reciter: harness.reciter, surahNumber: 2);

    final rows = await (harness.db.select(harness.db.downloads)
          ..orderBy([(d) => OrderingTerm.asc(d.surahId)]))
        .get();
    expect(rows.map((r) => r.surahId), [1, 2]);
    expect(rows.map((r) => r.status), ['done', 'done']);
  });
}

typedef _LegacyDb = ({File file, int oldestId});

/// A file-backed database shaped like a pre-fix install: the pair index was
/// non-unique and two racing writers already left duplicate rows on disk.
Future<_LegacyDb> _legacyDownloadsDbFile() async {
  final dir = await Directory.systemTemp.createTemp('qy_downloads_repair');
  addTearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });
  final file = File('${dir.path}${Platform.pathSeparator}downloads.sqlite');

  final db = AppDatabase(NativeDatabase(file));
  try {
    await db.customStatement('DROP INDEX IF EXISTS idx_downloads_lookup');
    final oldestId = await db.into(db.downloads).insert(_download());
    await db.into(db.downloads).insert(_download());
    expect(await db.select(db.downloads).get(), hasLength(2),
        reason: 'the legacy file must actually contain duplicate rows');
    return (file: file, oldestId: oldestId);
  } finally {
    await db.close();
  }
}

/// Settles [future] into its value or error so a racing download cannot leave
/// an unhandled asynchronous error behind. The row invariant is the subject.
Future<Object> _settle(Future<File> future) async {
  try {
    return await future;
  } on Object catch (error) {
    return error;
  }
}

/// In-memory DB, a temp audio root and a local HTTP server serving one body to
/// every request — the downloader is wired exactly as the app wires it.
class _Harness {
  _Harness._(this.db, this.root, this.server, this.reciter);

  final AppDatabase db;
  final Directory root;
  final HttpServer server;
  final ReciterRow reciter;

  late final AudioDownloader downloader = AudioDownloader(
    db,
    dio: Dio(),
    audioRootResolver: () async => root,
  );

  static Future<_Harness> start() async {
    final db = newTestDb();
    final root = await Directory.systemTemp.createTemp('qy_downloads_pair');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    unawaited(server.forEach((req) async {
      final body = List<int>.generate(2048, (i) => i % 251);
      req.response.contentLength = body.length;
      req.response.add(body);
      await req.response.close();
    }));
    await db.into(db.reciters).insert(RecitersCompanion.insert(
          id: _reciterId,
          reciterName: 'عبدالباسط عبدالصمد',
          moshafName: 'حفص مرتل',
          server: 'http://127.0.0.1:${server.port}',
          surahList: '1,2',
          surahTotal: 114,
        ));
    final reciter = await (db.select(db.reciters)).getSingle();
    return _Harness._(db, root, server, reciter);
  }
}
