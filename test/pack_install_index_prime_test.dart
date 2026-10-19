import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

/// Install-path memory contract: a per-surah-hash-pinned tafsir install must
/// build its ayah index from the loop bodies (zero extra decodes), while an
/// unpinned tafsir keeps exactly ONE wrapper sniff as its validation gate.
void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late HttpServer server;
  var serverBound = false;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_install_prime');
    serverBound = false;
  });

  tearDown(() async {
    if (serverBound) {
      await server.close(force: true);
    }
    await tempRoot.delete(recursive: true);
  });

  String shaOf(String body) => sha256.convert(utf8.encode(body)).toString();

  Future<PackDownloader> serveTafsir(
    List<String> bodies,
    Future<dynamic> Function(String path) decoder,
  ) async {
    server = await HttpServer.bind('127.0.0.1', 0);
    serverBound = true;
    server.listen((req) async {
      final match = RegExp(r'/([0-9]+)\.json$').firstMatch(req.uri.path);
      final n = int.tryParse(match?.group(1) ?? '');
      if (n == null || n < 1 || n > bodies.length) {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      req.response.headers.contentType = ContentType.json;
      req.response.write(bodies[n - 1]);
      await req.response.close();
    });
    return PackDownloader(
      db,
      dio: Dio(),
      libraryRootResolver: () async => tempRoot,
      fileDecoder: decoder,
    );
  }

  LibraryPackInfo tafsirPack({
    required int fileCount,
    List<String>? perSurah,
  }) =>
      LibraryPackInfo(
        id: 'tip',
        kind: LibraryPackKind.tafsir,
        language: 'ar',
        titleAr: 'تفسير',
        titleEn: 'Tafsir',
        urlTemplate: 'http://127.0.0.1:${server.port}/tafsir/{n}.json',
        fileCount: fileCount,
        approxSizeMb: 0.001,
        version: 'v1',
        sha256PerSurah: perSurah,
      );

  List<String> surahBodies() => [
        '[{"text":"tafsir 1:1","ayah":1,"surah":1},'
            '{"text":"tafsir 1:2","ayah":2,"surah":1}]',
        '[{"text":"tafsir 2:1","ayah":1,"surah":2},'
            '{"text":"tafsir 2:2","ayah":2,"surah":2}]',
      ];

  test('hash-pinned tafsir install decodes nothing and primes the index',
      () async {
    final bodies = surahBodies();
    var decoderCalls = 0;
    final downloader = await serveTafsir(bodies, (path) async {
      decoderCalls++;
      return jsonDecode(File(path).readAsStringSync());
    });

    final file = await downloader.install(tafsirPack(
      fileCount: bodies.length,
      perSurah: bodies.map(shaOf).toList(),
    ));

    // No end-of-install wrapper decode: the per-surah hashes plus the splice
    // guards are the integrity proof.
    expect(decoderCalls, 0);

    // The merged per-surah index is primed, so reads are served from it.
    expect(await downloader.tafsirFor('tip', 1, 1), 'tafsir 1:1');
    expect(await downloader.tafsirFor('tip', 2, 2), 'tafsir 2:2');
    expect(await downloader.tafsirFor('tip', 3, 1), isNull);
    expect(decoderCalls, 0);

    // The documented wrapper on disk is unchanged and parses.
    final wrapper = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(wrapper['pack'], 'tip');
    expect(wrapper['tafsirs'] as List, hasLength(4));
  });

  test('unpinned tafsir install keeps exactly ONE wrapper sniff', () async {
    final bodies = surahBodies();
    var decoderCalls = 0;
    final downloader = await serveTafsir(bodies, (path) async {
      decoderCalls++;
      return jsonDecode(File(path).readAsStringSync());
    });

    final file = await downloader.install(tafsirPack(
      fileCount: bodies.length,
    ));

    expect(decoderCalls, 1);

    expect(await downloader.tafsirFor('tip', 1, 1), 'tafsir 1:1');
    expect(await downloader.tafsirFor('tip', 2, 2), 'tafsir 2:2');
    expect(decoderCalls, 1);

    final wrapper = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(wrapper['pack'], 'tip');
    expect(wrapper['tafsirs'] as List, hasLength(4));
  });
}
