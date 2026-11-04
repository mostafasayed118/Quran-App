import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

/// One canned CDN response: a status code and a JSON body.
typedef _Reply = ({int status, String body});

_Reply _ok(String body) => (status: 200, body: body);

/// Serves the scripted [handler] for every request and records the dispatched
/// URIs. Same fake-adapter idiom as `pack_redirect_guard_test.dart`; the pack
/// seed must be a trusted `https://cdn.jsdelivr.net` URL now.
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

Map<String, dynamic> singleEntry({Object? sha256}) => {
      'id': 'tpin',
      'kind': 'translation',
      'language': 'ar',
      'titleAr': 'حزمة',
      'titleEn': 'Pack',
      'sourceUrl': 'https://cdn.example/tpin.min.json',
      'approxSizeMb': 1.0,
      'version': '1',
      if (sha256 != null) 'sha256': sha256,
    };

Map<String, dynamic> tafsirEntry(Object? perSurah, {int fileCount = 2}) => {
      'id': 'tpin-tafsir',
      'kind': 'tafsir',
      'language': 'ar',
      'titleAr': 'تفسير',
      'titleEn': 'Tafsir',
      'urlTemplate': 'https://cdn.example/tpin-tafsir/{n}.json',
      'fileCount': fileCount,
      'approxSizeMb': 1.0,
      'version': '1',
      if (perSurah != null) 'sha256PerSurah': perSurah,
    };

void main() {
  final goodHash = 'a' * 64;

  group('LibraryPackInfo hash fields', () {
    test('a well-formed sha256 parses normally', () {
      expect(() => LibraryPackInfo.fromJson(singleEntry(sha256: goodHash)),
          returnsNormally);
    });

    test('short, uppercase, non-hex, and non-string sha256 values are rejected',
        () {
      final bad = <Object>['a' * 63, 'A' * 64, 'g' * 64, 'a' * 65, 42];
      for (final value in bad) {
        expect(() => LibraryPackInfo.fromJson(singleEntry(sha256: value)),
            throwsFormatException,
            reason: 'sha256=$value must be rejected');
      }
    });

    test('a complete sha256PerSurah parses when its length matches fileCount',
        () {
      expect(
          () => LibraryPackInfo.fromJson(
              tafsirEntry(<String>['b' * 64, 'c' * 64])),
          returnsNormally);
    });

    test('sha256PerSurah length mismatch with fileCount is rejected', () {
      expect(
          () => LibraryPackInfo.fromJson(
              tafsirEntry(<String>['b' * 64], fileCount: 2)),
          throwsFormatException);
    });

    test('a malformed element inside sha256PerSurah is rejected', () {
      expect(
          () =>
              LibraryPackInfo.fromJson(tafsirEntry(<String>['b' * 64, 'NOPE'])),
          throwsFormatException);
    });

    test('a non-list sha256PerSurah is rejected', () {
      expect(() => LibraryPackInfo.fromJson(tafsirEntry('not-a-list')),
          throwsFormatException);
    });
  });

  group('PackDownloader sha256 gate', () {
    late AppDatabase db;
    late Directory tempRoot;
    late _FakeCdn adapter;
    late PackDownloader downloader;

    setUp(() async {
      db = newTestDb();
      tempRoot = await Directory.systemTemp.createTemp('qy_pack_integrity');
      adapter = _FakeCdn();
    });

    tearDown(() async {
      await tempRoot.delete(recursive: true);
    });

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

    String shaOf(String body) => sha256.convert(utf8.encode(body)).toString();

    const body = '{"quran":[{"chapter":1,"verse":1,"text":"بسم الله"}]}';

    LibraryPackInfo pack({String? sha256Hex}) => LibraryPackInfo(
          id: 'hip',
          kind: LibraryPackKind.translation,
          language: 'ar',
          titleAr: 'حزمة',
          titleEn: 'Pack',
          sourceUrl: 'https://cdn.jsdelivr.net/library/hip.min.json',
          approxSizeMb: 0.001,
          version: '1',
          sha256: sha256Hex,
        );

    test('single-file install succeeds when the sha256 matches', () async {
      await serve((_) async => _ok(body));
      final file = await downloader.install(pack(sha256Hex: shaOf(body)));

      expect(file.existsSync(), isTrue);
      expect(await downloader.installedPacks(), hasLength(1));
      expect(adapter.requested, hasLength(1));
    });

    test('single-file hash mismatch: PackFailure, no partial, no row',
        () async {
      await serve((_) async => _ok(body));
      final wrong =
          shaOf('{"quran":[{"chapter":1,"verse":1,"text":"tampered"}]}');

      await expectLater(downloader.install(pack(sha256Hex: wrong)),
          throwsA(isA<PackFailure>()));
      expect(adapter.requested, isNotEmpty,
          reason:
              'the body must be fetched before the hash gate can reject it');

      expect(await downloader.installedPacks(), isEmpty);
      final leftovers = Directory('${tempRoot.path}/library').listSync();
      expect(leftovers, isEmpty);
    });

    const surahBody = '[{"text":"text one","ayah":1,"surah":1}]';

    LibraryPackInfo tafsirPack({List<String>? perSurah}) => LibraryPackInfo(
          id: 'hip-tafsir',
          kind: LibraryPackKind.tafsir,
          language: 'ar',
          titleAr: 'تفسير',
          titleEn: 'Tafsir',
          urlTemplate: 'https://cdn.jsdelivr.net/library/tafsir/{n}.json',
          fileCount: 2,
          approxSizeMb: 0.001,
          version: 'v1',
          sha256PerSurah: perSurah,
        );

    test('tafsir install succeeds when every surah hash matches', () async {
      await serve((_) async => _ok(surahBody));
      final file = await downloader
          .install(tafsirPack(perSurah: [shaOf(surahBody), shaOf(surahBody)]));

      expect(file.existsSync(), isTrue);
      expect(await downloader.installedPacks(), hasLength(1));
      expect(adapter.requested, hasLength(2));
    });

    test('one bad surah hash aborts the install and cleans partials', () async {
      await serve((_) async => _ok(surahBody));

      await expectLater(
          downloader
              .install(tafsirPack(perSurah: [shaOf(surahBody), 'f' * 64])),
          throwsA(isA<PackFailure>()));
      expect(adapter.requested, isNotEmpty,
          reason: 'the surah bodies must be fetched before the hash gate runs');

      expect(await downloader.installedPacks(), isEmpty);
      final leftovers = Directory('${tempRoot.path}/library').listSync();
      expect(leftovers, isEmpty);
    });
  });

  group('shipped catalog integrity', () {
    test('every shipped pack is immutably pinned and fully hashed', () async {
      final file = File('assets/data/library_catalog.json');
      if (!file.existsSync()) {
        markTestSkipped(
            'working dir does not resolve the bundled asset from this runner');
      }
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final list = (json['packs'] as List).cast<Map<String, dynamic>>();
      final packs = await BundledCatalogSource(loader: () async => list).all();

      expect(packs, hasLength(3), reason: 'every shipped entry must parse');
      expect(packs.map((p) => p.id).toSet(), hasLength(3));

      final hex = RegExp(r'^[0-9a-f]{64}$');
      for (final pack in packs) {
        final url = pack.sourceUrl ?? pack.urlTemplate;
        expect(url, isNotNull);
        expect(url!, isNot(contains('@1/')),
            reason: 'pack ${pack.id} must not float on the bare @1 ref');
      }

      final tafsirs = packs.where((p) => p.kind == LibraryPackKind.tafsir);
      expect(tafsirs, hasLength(0));
      for (final pack in tafsirs) {
        final hashes = pack.sha256PerSurah;
        expect(hashes, isNotNull,
            reason: 'pack ${pack.id} needs per-surah hashes');
        expect(hashes, hasLength(pack.fileCount));
        expect(hashes, hasLength(114));
        for (final hash in hashes!) {
          expect(hex.hasMatch(hash), isTrue,
              reason: 'pack ${pack.id} has a malformed surah hash');
        }
      }

      final singles = packs.where((p) => p.kind != LibraryPackKind.tafsir);
      expect(singles, hasLength(3));
      for (final pack in singles) {
        final hash = pack.sha256;
        expect(hash, isNotNull, reason: 'pack ${pack.id} needs a sha256');
        expect(hex.hasMatch(hash!), isTrue,
            reason: 'pack ${pack.id} has a malformed sha256');
      }
    });
  });
}
