import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late HttpServer server;
  var serverBound = false;
  late PackDownloader downloader;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    tempRoot = await Directory.systemTemp.createTemp('qy_library_test');
  });

  tearDown(() async {
    if (serverBound) {
      await server.close(force: true);
    }
    await tempRoot.delete(recursive: true);
    await db.close();
  });

  Future<void> serve(Future<void> Function(HttpRequest request) handler) async {
    server = await HttpServer.bind('127.0.0.1', 0);
    serverBound = true;
    server.listen(handler);
    downloader = PackDownloader(
      db,
      dio: Dio(),
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
        sourceUrl: url ??
            'http://127.0.0.1:${server.port}/translation/$id.min.json',
        approxSizeMb: 0.001,
        version: '1',
      );

  test('single-file install streams the file, promotes, writes the row',
      () async {
    await serve((req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.write(
          '{"quran":[{"chapter":1,"verse":1,"text":"بسم الله"}]}');
      await req.response.close();
    });
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
    await serve((req) async {
      req.response.statusCode = 404;
      await req.response.close();
    });
    final pack = translationPack();

    await expectLater(downloader.install(pack), throwsA(isA<DioException>()));

    expect(await downloader.installedPacks(), isEmpty);
    final leftovers = Directory('${tempRoot.path}/library').listSync();
    expect(leftovers, isEmpty);
  });

  test('corrupt JSON body fails the integrity sniff, deletes the partial',
      () async {
    await serve((req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.write('not json at all {');
      await req.response.close();
    });
    final pack = translationPack();

    await expectLater(downloader.install(pack), throwsA(isA<PackFailure>()));

    expect(await downloader.installedPacks(), isEmpty);
    expect(Directory('${tempRoot.path}/library').existsSync(), isTrue);
    final leftovers = Directory('${tempRoot.path}/library').listSync();
    expect(leftovers, isEmpty);
  });

  test('tafsir install loops the template into the documented wrapper',
      () async {
    final requestLines = <String>[];
    await serve((req) async {
      requestLines.add(req.uri.path);
      if (RegExp(r'/tafsir/tp3/[0-9]+\.json$').hasMatch(req.uri.path)) {
        req.response.headers.contentType = ContentType.json;
        req.response.write(surahArrayFixture);
        await req.response.close();
      } else {
        req.response.statusCode = 404;
        await req.response.close();
      }
    });
    final pack = LibraryPackInfo(
      id: 'tp3',
      kind: LibraryPackKind.tafsir,
      language: 'ar',
      titleAr: 'تفسير',
      titleEn: 'Tafsir',
      urlTemplate:
          'http://127.0.0.1:${server.port}/tafsir/tp3/{n}.json',
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
    final decoded =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(decoded['pack'], 'tp3');
    final tafsirs = decoded['tafsirs'] as List;
    expect(tafsirs, hasLength(6)); // 3 surah files x 2 ayahs
    expect((tafsirs.first as Map)['surah'], 1);
    expect((tafsirs.last as Map)['surah'], 1);
    expect(await downloader.installedPacks().then((r) => r.single.kind),
        'tafsir');
    expect(progress, isNotEmpty);
  });

  test('tafsir loop failure deletes the part and installs no row', () async {
    var served = 0;
    await serve((req) async {
      served++;
      if (served == 1) {
        req.response.headers.contentType = ContentType.json;
        req.response.write(surahArrayFixture);
        await req.response.close();
      } else {
        req.response.statusCode = 500;
        await req.response.close();
      }
    });
    final pack = LibraryPackInfo(
      id: 'tp4',
      kind: LibraryPackKind.tafsir,
      language: 'ar',
      titleAr: 'تفسير',
      titleEn: 'Tafsir',
      urlTemplate: 'http://127.0.0.1:${server.port}/tafsir/tp4/{n}.json',
      fileCount: 2,
      approxSizeMb: 0.001,
      version: 'v1.2.2',
    );

    await expectLater(downloader.install(pack), throwsA(anything));

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

  test(
      'translationFor reads a real fixture excerpt for a known ayah (1:1)',
      () async {
    final fixture = File('test/fixtures/translation_ara_sirajtafseer_excerpt.json');
    if (!fixture.existsSync()) {
      markTestSkipped('fixtures dir does not resolve from this runner');
    }
    await serve((_) async {});
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
    await serve((_) async {});
    final libraryDir = Directory('${tempRoot.path}/library');
    await libraryDir.create(recursive: true);
    await fixture.copy('${libraryDir.path}/wm1.json');
    await seedRow('wm1', LibraryPackKind.tafsir);

    final text = await downloader.tafsirFor('wm1', 1, 1);
    expect(text, isNotNull);
    expect(await downloader.tafsirFor('wm1', 2, 1), isNull);
    expect(await downloader.tafsirFor('missing-pack', 1, 1), isNull);
  });

  test('hadithPage windows the real fixture and flips hasMore', () async {
    final fixture = File('test/fixtures/hadith_eng_muslim_excerpt.json');
    if (!fixture.existsSync()) {
      markTestSkipped('fixtures dir does not resolve from this runner');
    }
    await serve((_) async {});
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
    await serve((_) async {});
    final libraryDir = Directory('${tempRoot.path}/library');
    await libraryDir.create(recursive: true);
    await fixture.copy('${libraryDir.path}/tp1.json');
    await seedRow('tp1', LibraryPackKind.translation);

    final first = await downloader.translationFor('tp1', 1, 1);
    expect(first, isNotNull);

    // Mutate the file behind the downloader's back: a cached read must still
    // serve the original text, proving the file was not re-read.
    File('${libraryDir.path}/tp1.json')
        .writeAsStringSync('{"quran":[{"chapter":1,"verse":1,"text":"MUTATED"}]}');
    expect(await downloader.translationFor('tp1', 1, 1), first);

    // Uninstall clears the cache: the same id resolves from a fresh file.
    await downloader.uninstall('tp1');
    File('${libraryDir.path}/tp1.json')
        .writeAsStringSync('{"quran":[{"chapter":1,"verse":1,"text":"FRESH"}]}');
    await seedRow('tp1', LibraryPackKind.translation);
    expect(await downloader.translationFor('tp1', 1, 1), 'FRESH');
  });

  test('install primes the read cache (no re-read after install)', () async {
    await serve((req) async {
      req.response.headers.contentType = ContentType.json;
      req.response
          .write('{"quran":[{"chapter":1,"verse":1,"text":"INSTALLED"}]}');
      await req.response.close();
    });
    final file = await downloader.install(translationPack(id: 'tpc'));
    file
        .writeAsStringSync('{"quran":[{"chapter":1,"verse":1,"text":"MUTATED"}]}');
    expect(await downloader.translationFor('tpc', 1, 1), 'INSTALLED');
  });

  test('uninstall removes both the file and the registry row', () async {
    await serve((req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.write(
          '{"quran":[{"chapter":1,"verse":1,"text":"text"}]}');
      await req.response.close();
    });
    await downloader.install(translationPack(id: 'tp9'));
    expect(await downloader.isInstalledAny('tp9'), isTrue);

    await downloader.uninstall('tp9');

    expect(await downloader.installedPacks(), isEmpty);
    expect(Directory('${tempRoot.path}/library').listSync(), isEmpty);
    expect(await downloader.packPath('tp9'), isNull);
  });
}
