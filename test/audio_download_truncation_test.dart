import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';

import 'support/test_db.dart';

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
}
