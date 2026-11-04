import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

/// One canned CDN response: a status code and a JSON body.
typedef _Reply = ({int status, String body});

_Reply _ok(String body) => (status: 200, body: body);
_Reply _status(int status) => (status: status, body: '');

/// Serves the scripted [handler] for every request and records the dispatched
/// URIs. Same fake-adapter idiom as `pack_redirect_guard_test.dart`.
///
/// The downloader now refuses a seed outside `https://cdn.jsdelivr.net`, so the
/// transport is faked instead of bound to a loopback HTTP server.
class _FakeCdn implements HttpClientAdapter {
  Future<_Reply> Function(RequestOptions request)? handler;
  final List<String> requested = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requested.add(options.uri.toString());
    final scripted = handler;
    if (scripted == null) {
      throw StateError('unexpected request: ${options.uri}');
    }
    final reply = await scripted(options);
    final bytes = Uint8List.fromList(utf8.encode(reply.body));
    return ResponseBody(
      Stream<Uint8List>.value(bytes),
      reply.status,
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
  late AppDatabase db;
  late Directory tempRoot;
  late _FakeCdn adapter;
  late PackDownloader downloader;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_library_test');
    adapter = _FakeCdn();
  });

  tearDown(() async {
    await tempRoot.delete(recursive: true);
  });

  /// Pins the CDN script for this test and builds the downloader on top of it.
  /// A test that never fetches calls [serve] with no handler.
  Future<void> serve([
    Future<_Reply> Function(RequestOptions request)? handler,
  ]) async {
    adapter.handler = handler;
    downloader = PackDownloader(
      db,
      dio: Dio()..httpClientAdapter = adapter,
      libraryRootResolver: () async => tempRoot,
    );
  }

  const surahArrayFixture =
      '[{"text":"text one","ayah":1,"surah":1},{"text":"text two","ayah":2,"surah":1}]';

  LibraryPackInfo translationPack({String id = 'tp1', String? url}) =>
      LibraryPackInfo(
        id: id,
        kind: LibraryPackKind.translation,
        language: 'ar',
        titleAr: 'حزمة',
        titleEn: 'Pack',
        sourceUrl:
            url ?? 'https://cdn.jsdelivr.net/library/translation/$id.min.json',
        approxSizeMb: 0.001,
        version: '1',
      );

  test('single-file install streams the file, promotes, writes the row',
      () async {
    await serve((_) async =>
        _ok('{"quran":[{"chapter":1,"verse":1,"text":"بسم الله"}]}'));
    final pack = translationPack();
    final file = await downloader.install(pack);

    expect(file.existsSync(), isTrue);
    expect(file.path.endsWith('tp1.json'), isTrue);
    expect(File('${file.path}.part').existsSync(), isFalse);
    final rows = await downloader.installedPacks();
    expect(rows, hasLength(1));
    expect(rows.single.packId, 'tp1');
    expect(rows.single.kind, 'translation');
    expect(rows.single.version, '1');
    expect(rows.single.sizeMb, greaterThan(0));
    expect(await downloader.isInstalled('tp1', '1'), isTrue);
    expect(await downloader.isInstalled('tp1', '9'), isFalse);
    expect(await downloader.isInstalledAny('tp1'), isTrue);
  });

  test('404 installs no row and leaves no partial file', () async {
    await serve((_) async => _status(404));
    final pack = translationPack();

    await expectLater(downloader.install(pack), throwsA(isA<DioException>()));

    expect(await downloader.installedPacks(), isEmpty);
    final leftovers = Directory('${tempRoot.path}/library').listSync();
    expect(leftovers, isEmpty);
  });

  test('corrupt JSON body fails the integrity sniff, deletes the partial',
      () async {
    await serve((_) async => _ok('not json at all {'));
    final pack = translationPack();

    await expectLater(downloader.install(pack), throwsA(isA<PackFailure>()));
    expect(adapter.requested, isNotEmpty,
        reason: 'the body must be fetched before it can fail the sniff');

    expect(await downloader.installedPacks(), isEmpty);
    expect(Directory('${tempRoot.path}/library').existsSync(), isTrue);
    final leftovers = Directory('${tempRoot.path}/library').listSync();
    expect(leftovers, isEmpty);
  });

  test('valid JSON with the wrong shape fails as PackFailure, not TypeError',
      () async {
    await serve((_) async => _ok('[]'));

    await expectLater(downloader.install(translationPack(id: 'tshape')),
        throwsA(isA<PackFailure>()));
    expect(adapter.requested, isNotEmpty,
        reason: 'the body must be fetched before it can fail the sniff');

    expect(await downloader.installedPacks(), isEmpty);
    final leftovers = Directory('${tempRoot.path}/library').listSync();
    expect(leftovers, isEmpty);
  });

  test('tafsir install loops the template into the documented wrapper',
      () async {
    final requestLines = <String>[];
    await serve((req) async {
      requestLines.add(req.uri.path);
      if (RegExp(r'/tafsir/tp3/[0-9]+\.json$').hasMatch(req.uri.path)) {
        return _ok(surahArrayFixture);
      }
      return _status(404);
    });
    const pack = LibraryPackInfo(
      id: 'tp3',
      kind: LibraryPackKind.tafsir,
      language: 'ar',
      titleAr: 'تفسير',
      titleEn: 'Tafsir',
      urlTemplate: 'https://cdn.jsdelivr.net/library/tafsir/tp3/{n}.json',
      fileCount: 3,
      approxSizeMb: 0.001,
      version: 'v1.2.2',
    );
    final progress = <int>[];
    final file = await downloader.install(pack,
        onProgress: (received, total) => progress.add(received));

    expect(requestLines.map((p) => p.split('/').last),
        containsAllInOrder(<String>['1.json', '2.json', '3.json']));
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(decoded['pack'], 'tp3');
    final tafsirs = decoded['tafsirs'] as List;
    expect(tafsirs, hasLength(6)); // 3 surah files x 2 ayahs
    expect((tafsirs.first as Map)['surah'], 1);
    expect((tafsirs.last as Map)['surah'], 1);
    expect(
        await downloader.installedPacks().then((r) => r.single.kind), 'tafsir');
    expect(progress, isNotEmpty);
  });

  test('tafsir loop failure deletes the part and installs no row', () async {
    var served = 0;
    await serve((_) async {
      served++;
      return served == 1 ? _ok(surahArrayFixture) : _status(500);
    });
    const pack = LibraryPackInfo(
      id: 'tp4',
      kind: LibraryPackKind.tafsir,
      language: 'ar',
      titleAr: 'تفسير',
      titleEn: 'Tafsir',
      urlTemplate: 'https://cdn.jsdelivr.net/library/tafsir/tp4/{n}.json',
      fileCount: 2,
      approxSizeMb: 0.001,
      version: 'v1.2.2',
    );

    await expectLater(downloader.install(pack), throwsA(anything));
    expect(served, greaterThanOrEqualTo(2),
        reason: 'the failing surah must be requested, not skipped');

    expect(await downloader.installedPacks(), isEmpty);
    final leftovers = Directory('${tempRoot.path}/library').listSync();
    expect(leftovers, isEmpty);
  });

  /// Registers a minimal InstalledPacks row (adapters read row-backed packs).
  Future<void> seedRow(String packId, LibraryPackKind kind) async {
    await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
          packId: packId,
          kind: kind.name,
          language: 'ar',
          title: 't',
          sizeMb: 0.1,
          version: '1',
        ));
  }

  test('translationFor reads a real fixture excerpt for a known ayah (1:1)',
      () async {
    final fixture =
        File('test/fixtures/translation_ara_sirajtafseer_excerpt.json');
    if (!fixture.existsSync()) {
      markTestSkipped('fixtures dir does not resolve from this runner');
    }
    await serve();
    final libraryDir = Directory('${tempRoot.path}/library');
    await libraryDir.create(recursive: true);
    await fixture.copy('${libraryDir.path}/tp1.json');
    await seedRow('tp1', LibraryPackKind.translation);

    final text = await downloader.translationFor('tp1', 1, 1);
    expect(text, isNotNull);
    expect(await downloader.translationFor('tp1', 114, 6), isNull);
  });

  test('tafsirFor reads the real wrapper fixture (surah 1 ayah 1)', () async {
    final fixture = File('test/fixtures/tafsir_wrapper_sample.json');
    if (!fixture.existsSync()) {
      markTestSkipped('fixtures dir does not resolve from this runner');
    }
    await serve();
    final libraryDir = Directory('${tempRoot.path}/library');
    await libraryDir.create(recursive: true);
    await fixture.copy('${libraryDir.path}/wm1.json');
    await seedRow('wm1', LibraryPackKind.tafsir);

    final text = await downloader.tafsirFor('wm1', 1, 1);
    expect(text, isNotNull);
    expect(await downloader.tafsirFor('wm1', 2, 1), isNull);
    expect(await downloader.tafsirFor('missing-pack', 1, 1), isNull);
  });

  test('hadithPage tolerates malformed entries instead of throwing', () async {
    await serve();
    final libraryDir = Directory('${tempRoot.path}/library')
      ..createSync(recursive: true);
    File('${libraryDir.path}/hm-bad.json').writeAsStringSync(
        '{"hadiths":[{"hadithnumber":"nope","text":"x"},{"hadithnumber":1,"text":"ok"},42]}');
    await seedRow('hm-bad', LibraryPackKind.hadith);

    final page = await downloader.hadithPage('hm-bad', 0, 10);

    expect(page.$1, [(1, 'ok')]);
    expect(page.$2, isFalse);
  });

  test('uninstall refuses unsafe pack ids (path traversal defense)', () async {
    await serve();
    final outside = File('${tempRoot.path}/outside.json')
      ..writeAsStringSync('keep');

    await expectLater(
        downloader.uninstall('../outside'), throwsA(isA<PackFailure>()));

    expect(outside.existsSync(), isTrue);
  });

  test('hadithPage windows the real fixture and flips hasMore', () async {
    final fixture = File('test/fixtures/hadith_eng_muslim_excerpt.json');
    if (!fixture.existsSync()) {
      markTestSkipped('fixtures dir does not resolve from this runner');
    }
    await serve();
    final libraryDir = Directory('${tempRoot.path}/library');
    await libraryDir.create(recursive: true);
    await fixture.copy('${libraryDir.path}/hm1.json');
    await seedRow('hm1', LibraryPackKind.hadith);

    final first = await downloader.hadithPage('hm1', 0, 5);
    expect(first.$1, hasLength(5));
    expect(first.$2, isTrue);
    final last = await downloader.hadithPage('hm1', 10, 5);
    expect(last.$1, hasLength(2));
    expect(last.$2, isFalse);
    final beyond = await downloader.hadithPage('hm1', 99, 5);
    expect(beyond.$1, isEmpty);
    expect(beyond.$2, isFalse);
  });

  test('repeated reads are served from cache, not re-decoded', () async {
    final fixture =
        File('test/fixtures/translation_ara_sirajtafseer_excerpt.json');
    if (!fixture.existsSync()) {
      markTestSkipped('fixtures dir does not resolve from this runner');
    }
    await serve();
    final libraryDir = Directory('${tempRoot.path}/library');
    await libraryDir.create(recursive: true);
    await fixture.copy('${libraryDir.path}/tp1.json');
    await seedRow('tp1', LibraryPackKind.translation);

    final first = await downloader.translationFor('tp1', 1, 1);
    expect(first, isNotNull);

    // Mutate the file behind the downloader's back: a cached read must still
    // serve the original text, proving the file was not re-read.
    File('${libraryDir.path}/tp1.json').writeAsStringSync(
        '{"quran":[{"chapter":1,"verse":1,"text":"MUTATED"}]}');
    expect(await downloader.translationFor('tp1', 1, 1), first);

    // Uninstall clears the cache: the same id resolves from a fresh file.
    await downloader.uninstall('tp1');
    File('${libraryDir.path}/tp1.json').writeAsStringSync(
        '{"quran":[{"chapter":1,"verse":1,"text":"FRESH"}]}');
    await seedRow('tp1', LibraryPackKind.translation);
    expect(await downloader.translationFor('tp1', 1, 1), 'FRESH');
  });

  test('install primes the read cache (no re-read after install)', () async {
    await serve((_) async =>
        _ok('{"quran":[{"chapter":1,"verse":1,"text":"INSTALLED"}]}'));
    final file = await downloader.install(translationPack(id: 'tpc'));
    file.writeAsStringSync(
        '{"quran":[{"chapter":1,"verse":1,"text":"MUTATED"}]}');
    expect(await downloader.translationFor('tpc', 1, 1), 'INSTALLED');
  });

  test('oversized single-file stream is aborted before promotion', () async {
    await serve((_) async {
      final filler = 'a' * (200 * 1024);
      return _ok('{"quran":[{"chapter":1,"verse":1,"text":"$filler"}]}');
    });
    await expectLater(downloader.install(translationPack(id: 'tover')),
        throwsA(isA<PackFailure>()));
    expect(adapter.requested, isNotEmpty,
        reason: 'the oversized stream must be fetched before the cap fires');
    expect(await downloader.installedPacks(), isEmpty);
    final leftovers = Directory('${tempRoot.path}/library').listSync();
    expect(leftovers, isEmpty);
  });

  test('uninstall removes both the file and the registry row', () async {
    await serve(
        (_) async => _ok('{"quran":[{"chapter":1,"verse":1,"text":"text"}]}'));
    await downloader.install(translationPack(id: 'tp9'));
    expect(await downloader.isInstalledAny('tp9'), isTrue);

    await downloader.uninstall('tp9');

    expect(await downloader.installedPacks(), isEmpty);
    expect(Directory('${tempRoot.path}/library').listSync(), isEmpty);
    expect(await downloader.packPath('tp9'), isNull);
  });

  test('decoded cache is bounded: a third pack evicts the least recently used',
      () async {
    await serve((_) async =>
        _ok('{"quran":[{"chapter":1,"verse":1,"text":"CACHED"}]}'));
    final libraryDir = Directory('${tempRoot.path}/library');
    await libraryDir.create(recursive: true);
    await downloader.install(translationPack(id: 'lru-a'));
    await downloader.install(translationPack(id: 'lru-b'));
    await downloader.install(translationPack(id: 'lru-c'));

    // 'lru-a' was the least recently used and must have been evicted: a
    // mutated file proves the read re-decoded from disk.
    File('${libraryDir.path}/lru-a.json').writeAsStringSync(
        '{"quran":[{"chapter":1,"verse":1,"text":"FRESH-A"}]}');
    expect(await downloader.translationFor('lru-a', 1, 1), 'FRESH-A');

    // 'lru-c' is still cached: the mutated file must NOT be re-read.
    File('${libraryDir.path}/lru-c.json').writeAsStringSync(
        '{"quran":[{"chapter":1,"verse":1,"text":"MUTATED"}]}');
    expect(await downloader.translationFor('lru-c', 1, 1), 'CACHED');
  });

  test('cold reads decode via the injected fileDecoder; warm reads do not',
      () async {
    await serve();
    final decodedPaths = <String>[];
    final seam = PackDownloader(
      db,
      dio: Dio(),
      libraryRootResolver: () async => tempRoot,
      fileDecoder: (path) async {
        decodedPaths.add(path);
        return jsonDecode(File(path).readAsStringSync());
      },
    );
    final libraryDir = Directory('${tempRoot.path}/library');
    await libraryDir.create(recursive: true);
    await File('test/fixtures/translation_ara_sirajtafseer_excerpt.json')
        .copy('${libraryDir.path}/tp1.json');
    await seedRow('tp1', LibraryPackKind.translation);

    expect(await seam.translationFor('tp1', 1, 1), isNotNull);
    expect(decodedPaths, hasLength(1));
    expect(await seam.translationFor('tp1', 1, 1), isNotNull);
    expect(decodedPaths, hasLength(1));
  });

  test('oversized tafsir surah body aborts before promotion', () async {
    await serve((_) async {
      final filler = 'a' * (200 * 1024);
      return _ok('[{"text":"$filler","ayah":1,"surah":1}]');
    });
    const pack = LibraryPackInfo(
      id: 'tpover',
      kind: LibraryPackKind.tafsir,
      language: 'ar',
      titleAr: 'تفسير',
      titleEn: 'Tafsir',
      urlTemplate: 'https://cdn.jsdelivr.net/library/tafsir/tpover/{n}.json',
      fileCount: 2,
      approxSizeMb: 0.001,
      version: 'v1.2.2',
    );

    await expectLater(downloader.install(pack), throwsA(isA<PackFailure>()));
    expect(adapter.requested, isNotEmpty,
        reason: 'the oversized surah must be fetched before the cap fires');

    expect(await downloader.installedPacks(), isEmpty);
    final leftovers = Directory('${tempRoot.path}/library').listSync();
    expect(leftovers, isEmpty);
  });
}
