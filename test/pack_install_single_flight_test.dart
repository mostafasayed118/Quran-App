import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

void main() {
  test('two concurrent installs of one pack share one request', () async {
    final db = newTestDb();
    final tempRoot = await Directory.systemTemp.createTemp('qy_pack_single');
    addTearDown(() => tempRoot.delete(recursive: true));

    var requests = 0;
    final gate = Completer<void>();
    final server = await HttpServer.bind('127.0.0.1', 0);
    addTearDown(() => server.close(force: true));
    server.listen((req) async {
      requests++;
      await gate.future;
      req.response.write('{"quran":[{"chapter":1,"verse":1,"text":"ب"}]}');
      await req.response.close();
    });

    final downloader = PackDownloader(
      db,
      dio: Dio(),
      libraryRootResolver: () async => tempRoot,
    );
    final pack = LibraryPackInfo(
      id: 'tp1',
      kind: LibraryPackKind.translation,
      language: 'ar',
      titleAr: 'حزمة',
      titleEn: 'Pack',
      sourceUrl: 'http://127.0.0.1:${server.port}/translation/tp1.min.json',
      approxSizeMb: 0.001,
      version: '1',
    );

    final first = downloader.install(pack);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = downloader.install(pack);
    gate.complete();

    final files = await Future.wait([first, second]);
    expect(requests, 1);
    expect(files[0].path, files[1].path);
    expect(File('${files[0].path}.part').existsSync(), isFalse);
  });
}
