import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

/// Serves one valid pack body and records the dispatched URIs.
///
/// Same fake-adapter idiom as `pack_redirect_guard_test.dart`; the pack seed
/// must be a trusted `https://cdn.jsdelivr.net` URL now.
class _FakeCdn implements HttpClientAdapter {
  final List<String> requested = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requested.add(options.uri.toString());
    final bytes = Uint8List.fromList(
        utf8.encode('{"quran":[{"chapter":1,"verse":1,"text":"text"}]}'));
    return ResponseBody(
      Stream<Uint8List>.value(bytes),
      200,
      headers: <String, List<String>>{
        Headers.contentLengthHeader: ['${bytes.length}'],
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a failed registry write does not leave a promoted pack orphan',
      () async {
    final db = newTestDb();
    final root = await Directory.systemTemp.createTemp('qy_pack_register');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
      await db.close();
    });
    final adapter = _FakeCdn();

    // Force the registry insert to fail after the file has been promoted.
    await db.customStatement(
      "CREATE TRIGGER fail_install BEFORE INSERT ON installed_packs "
      "BEGIN SELECT RAISE(ABORT, 'blocked'); END;",
    );
    final downloader = PackDownloader(
      db,
      dio: Dio()..httpClientAdapter = adapter,
      libraryRootResolver: () async => root,
    );
    const pack = LibraryPackInfo(
      id: 'broken-register',
      kind: LibraryPackKind.translation,
      language: 'en',
      titleAr: 't',
      titleEn: 't',
      approxSizeMb: 0.001,
      version: '1',
      sourceUrl: 'https://cdn.jsdelivr.net/library/broken-register.json',
    );

    await expectLater(downloader.install(pack), throwsA(anything));
    // The registry write is only reachable after the body was fetched and the
    // part file was promoted, so exactly one request must have been dispatched.
    expect(adapter.requested, hasLength(1));

    final promoted = File('${root.path}/library/broken-register.json');
    expect(promoted.existsSync(), isFalse);
    expect(File('${promoted.path}.part').existsSync(), isFalse);
  });
}
