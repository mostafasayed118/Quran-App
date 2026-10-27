import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart'
    show surahAudioFileName;

import 'support/test_db.dart';

Future<ReciterRow> _seedReciter(AppDatabase db) async {
  await db.into(db.reciters).insert(RecitersCompanion.insert(
        id: '51-53',
        reciterName: 'عبدالباسط عبدالصمد',
        moshafName: 'حفص مرتل',
        server: 'https://server.example/mp3',
        surahList: '1',
        surahTotal: 114,
      ));
  return (db.select(db.reciters)).getSingle();
}

File _surahFile(Directory root, ReciterRow reciter, int surahNumber) => File(
    '${root.path}${Platform.pathSeparator}${AudioDownloader.audioFolderName}'
    '${Platform.pathSeparator}${reciter.id}'
    '${Platform.pathSeparator}${surahAudioFileName(surahNumber)}');

Future<void> _seedDoneRow(
    AppDatabase db, ReciterRow reciter, File target) async {
  await db.into(db.downloads).insert(DownloadsCompanion.insert(
        reciterId: reciter.id,
        surahId: 1,
        status: 'done',
        path: target.path,
        bytes: Value(await target.length()),
      ));
}

class _FixedBodyAdapter implements HttpClientAdapter {
  _FixedBodyAdapter(this.body);

  final List<int> body;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody(
      Stream.fromIterable([Uint8List.fromList(body)]),
      200,
      headers: {
        Headers.contentLengthHeader: ['${body.length}'],
        Headers.contentTypeHeader: ['audio/mpeg'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ShortAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody(
      Stream.fromIterable([Uint8List.fromList(List<int>.filled(10, 7))]),
      200,
      headers: {
        Headers.contentLengthHeader: ['1000'],
        Headers.contentTypeHeader: ['audio/mpeg'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a body shorter than content-length is failed and leaves no file',
      () async {
    final db = newTestDb();
    final root = await Directory.systemTemp.createTemp('qy_audio_short');
    addTearDown(() => root.delete(recursive: true));
    await db.into(db.reciters).insert(RecitersCompanion.insert(
          id: '51-53',
          reciterName: 'عبدالباسط عبدالصمد',
          moshafName: 'حفص مرتل',
          server: 'https://server.example/mp3',
          surahList: '1',
          surahTotal: 114,
        ));
    final reciter = await (db.select(db.reciters)).getSingle();
    final downloader = AudioDownloader(
      db,
      dio: Dio()..httpClientAdapter = _ShortAdapter(),
      audioRootResolver: () async => root,
    );

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DownloadFailure>()),
    );

    final row = await (db.select(db.downloads)).getSingle();
    expect(row.status, 'failed');
    expect(File(row.path).existsSync(), isFalse);
    expect(File('${row.path}.part').existsSync(), isFalse);
  });

  test('a failed retry keeps the previously downloaded file intact', () async {
    final db = newTestDb();
    final root = await Directory.systemTemp.createTemp('qy_audio_retry_short');
    addTearDown(() => root.delete(recursive: true));
    final reciter = await _seedReciter(db);
    final target = _surahFile(root, reciter, 1);
    await target.parent.create(recursive: true);
    final oldBytes = List<int>.generate(64, (i) => (i * 7) % 251);
    await target.writeAsBytes(oldBytes);
    await _seedDoneRow(db, reciter, target);
    final downloader = AudioDownloader(
      db,
      dio: Dio()..httpClientAdapter = _ShortAdapter(),
      audioRootResolver: () async => root,
    );

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DownloadFailure>()),
    );

    expect(target.existsSync(), isTrue,
        reason: 'a failed retry must not delete the previous file');
    expect(await target.readAsBytes(), oldBytes);
    expect(File('${target.path}.part').existsSync(), isFalse);
    final row = await (db.select(db.downloads)).getSingle();
    expect(row.status, 'failed');
    expect(row.path, target.path);
  });

  test(
      'a successful retry replaces the previous file and removes staging files',
      () async {
    final db = newTestDb();
    final root = await Directory.systemTemp.createTemp('qy_audio_retry_full');
    addTearDown(() => root.delete(recursive: true));
    final reciter = await _seedReciter(db);
    final target = _surahFile(root, reciter, 1);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(List<int>.filled(64, 1));
    await _seedDoneRow(db, reciter, target);
    final backup = File('${target.path}.bak');
    await backup.writeAsBytes([9, 9, 9]);
    final newBytes = List<int>.generate(128, (i) => i % 251);
    final downloader = AudioDownloader(
      db,
      dio: Dio()..httpClientAdapter = _FixedBodyAdapter(newBytes),
      audioRootResolver: () async => root,
    );

    final file =
        await downloader.downloadSurah(reciter: reciter, surahNumber: 1);

    expect(file.path, target.path);
    expect(await target.readAsBytes(), newBytes);
    expect(File('${target.path}.part').existsSync(), isFalse);
    expect(backup.existsSync(), isFalse);
    final row = await (db.select(db.downloads)).getSingle();
    expect(row.status, 'done');
    expect(row.bytes, newBytes.length);
  });
}
