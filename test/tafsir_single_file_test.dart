import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

class _FakeCdn implements HttpClientAdapter {
  _FakeCdn(this.body);

  final String body;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final bytes = Uint8List.fromList(utf8.encode(body));
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

const _body = '{"quran":[{"chapter":1,"verse":1,"text":"تفسير البسملة"}]}';

LibraryPackInfo _pack({String? sha256Hex}) => LibraryPackInfo(
      id: 'tafsir-single',
      kind: LibraryPackKind.tafsir,
      language: 'ar',
      titleAr: 'تفسير',
      titleEn: 'Tafsir',
      sourceUrl: 'https://cdn.jsdelivr.net/library/tafsir-single.min.json',
      approxSizeMb: 0.001,
      version: '1',
      sha256: sha256Hex,
    );

void main() {
  test('a single-file tafsir parses and its integrity contract uses sha256',
      () {
    final hash = sha256.convert(utf8.encode(_body)).toString();
    final pack = LibraryPackInfo.fromJson({
      'id': 'tafsir-single',
      'kind': 'tafsir',
      'language': 'ar',
      'titleAr': 'تفسير',
      'titleEn': 'Tafsir',
      'sourceUrl': 'https://cdn.jsdelivr.net/library/tafsir-single.min.json',
      'approxSizeMb': 0.001,
      'version': '1',
      'sha256': hash,
    });

    expect(pack.kind, LibraryPackKind.tafsir);
    expect(pack.urlTemplate, isNull);
    expect(catalogIntegrityGap(pack), isNull);
    expect(catalogIntegrityGap(_pack()), 'requires a sha256 hash');
  });

  test('a tafsir with neither a template nor a source is rejected', () {
    expect(
      () => LibraryPackInfo.fromJson({
        'id': 'bad-tafsir',
        'kind': 'tafsir',
        'language': 'ar',
        'titleAr': 'تفسير',
        'titleEn': 'Tafsir',
        'approxSizeMb': 0.001,
        'version': '1',
      }),
      throwsFormatException,
    );
  });

  test('installs a single-file tafsir and reads it back by ayah', () async {
    final db = newTestDb();
    final tempRoot = await Directory.systemTemp.createTemp('qy_tafsir_single');
    addTearDown(() => tempRoot.delete(recursive: true));
    final hash = sha256.convert(utf8.encode(_body)).toString();
    final downloader = PackDownloader(
      db,
      dio: Dio()..httpClientAdapter = _FakeCdn(_body),
      libraryRootResolver: () async => tempRoot,
    );

    final file = await downloader.install(_pack(sha256Hex: hash));

    expect(file.existsSync(), isTrue);
    expect(await downloader.installedPacks(), hasLength(1));
    expect(await downloader.tafsirFor('tafsir-single', 1, 1), 'تفسير البسملة');
    expect(await downloader.tafsirFor('tafsir-single', 1, 2), isNull);
  });

  test('a single-file tafsir with the wrong shape installs no row', () async {
    final db = newTestDb();
    final tempRoot = await Directory.systemTemp.createTemp('qy_tafsir_bad');
    addTearDown(() => tempRoot.delete(recursive: true));
    const body = '{"not_quran":[]}';
    final downloader = PackDownloader(
      db,
      dio: Dio()..httpClientAdapter = _FakeCdn(body),
      libraryRootResolver: () async => tempRoot,
    );

    await expectLater(
      downloader.install(_pack(
        sha256Hex: sha256.convert(utf8.encode(body)).toString(),
      )),
      throwsA(isA<PackFailure>()),
    );
    expect(await downloader.installedPacks(), isEmpty);
  });
}
