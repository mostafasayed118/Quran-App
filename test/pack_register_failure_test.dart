import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

void main() {
  test('a failed registry write does not leave a promoted pack orphan',
      () async {
    final db = newTestDb();
    final root = await Directory.systemTemp.createTemp('qy_pack_register');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
      await db.close();
    });
    final server = await HttpServer.bind('127.0.0.1', 0);
    addTearDown(() async => server.close(force: true));
    server.listen((req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.write(
        '{"quran":[{"chapter":1,"verse":1,"text":"text"}]}',
      );
      await req.response.close();
    });

    // Force the registry insert to fail after the file has been promoted.
    await db.customStatement(
      "CREATE TRIGGER fail_install BEFORE INSERT ON installed_packs "
      "BEGIN SELECT RAISE(ABORT, 'blocked'); END;",
    );
    final downloader = PackDownloader(
      db,
      libraryRootResolver: () async => root,
    );
    final pack = LibraryPackInfo(
      id: 'broken-register',
      kind: LibraryPackKind.translation,
      language: 'en',
      titleAr: 't',
      titleEn: 't',
      approxSizeMb: 0.001,
      version: '1',
      sourceUrl: 'http://127.0.0.1:${server.port}/pack.json',
    );

    await expectLater(downloader.install(pack), throwsA(anything));

    final promoted = File('${root.path}/library/broken-register.json');
    expect(promoted.existsSync(), isFalse);
    expect(File('${promoted.path}.part').existsSync(), isFalse);
  });
}
