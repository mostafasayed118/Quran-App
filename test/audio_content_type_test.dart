import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory root;
  late HttpServer server;

  setUp(() async {
    db = newTestDb();
    root = await Directory.systemTemp.createTemp('qy_audio_content_type');
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      req.response.headers.contentType = ContentType.html;
      req.response.write('<html>captive portal</html>');
      await req.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (await root.exists()) await root.delete(recursive: true);
    await db.close();
  });

  test('an HTML 200 page is rejected instead of promoted as MP3', () async {
    final reciter = ReciterRow(
      id: '1-1',
      reciterName: 'test',
      moshafName: 'test',
      server: 'http://127.0.0.1:${server.port}/',
      surahList: '1',
      surahTotal: 114,
    );
    final downloader = AudioDownloader(
      db,
      audioRootResolver: () async => root,
    );

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DownloadFailure>()),
    );

    final target = File('${root.path}/audio/1-1/001.mp3');
    expect(target.existsSync(), isFalse);
    expect(File('${target.path}.part').existsSync(), isFalse);
  });
}
