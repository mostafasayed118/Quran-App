import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

/// Holds every response behind [gate] and counts the dispatched requests.
///
/// Same fake-adapter idiom as `pack_redirect_guard_test.dart`; the pack seed
/// must be a trusted `https://cdn.jsdelivr.net` URL now.
class _GatedCdn implements HttpClientAdapter {
  final Completer<void> gate = Completer<void>();
  int requests = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests++;
    await gate.future;
    final bytes = Uint8List.fromList(
        utf8.encode('{"quran":[{"chapter":1,"verse":1,"text":"ب"}]}'));
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
  test('two concurrent installs of one pack share one request', () async {
    final db = newTestDb();
    final tempRoot = await Directory.systemTemp.createTemp('qy_pack_single');
    addTearDown(() => tempRoot.delete(recursive: true));

    final adapter = _GatedCdn();

    final downloader = PackDownloader(
      db,
      dio: Dio()..httpClientAdapter = adapter,
      libraryRootResolver: () async => tempRoot,
    );
    const pack = LibraryPackInfo(
      id: 'tp1',
      kind: LibraryPackKind.translation,
      language: 'ar',
      titleAr: 'حزمة',
      titleEn: 'Pack',
      sourceUrl: 'https://cdn.jsdelivr.net/library/translation/tp1.min.json',
      approxSizeMb: 0.001,
      version: '1',
    );

    final first = downloader.install(pack);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = downloader.install(pack);
    adapter.gate.complete();

    final files = await Future.wait([first, second]);
    expect(adapter.requests, 1);
    expect(files[0].path, files[1].path);
    expect(File('${files[0].path}.part').existsSync(), isFalse);
  });
}
