import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

/// Serves one canned 200 body and records every dispatched request URI.
///
/// A guard that fires before the GET leaves [requested] empty, which is the
/// only observable difference between "rejected up front" and "rejected only
/// after the untrusted host was already contacted".
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);

  final List<int> body;
  final List<String> requested = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requested.add(options.uri.toString());
    return ResponseBody(
      Stream<Uint8List>.value(Uint8List.fromList(body)),
      200,
      headers: <String, List<String>>{
        Headers.contentLengthHeader: ['${body.length}'],
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const String _body = '{"quran":[{"chapter":1,"verse":1,"text":"بسم الله"}]}';

LibraryPackInfo _pack({String? sourceUrl, String? sha256Hex}) =>
    LibraryPackInfo(
      id: 'seed-guard',
      kind: LibraryPackKind.translation,
      language: 'ar',
      titleAr: 'حزمة',
      titleEn: 'Pack',
      sourceUrl: sourceUrl,
      approxSizeMb: 0.001,
      version: '1',
      sha256: sha256Hex,
    );

Future<Directory> _newRoot() async {
  final root = await Directory.systemTemp.createTemp('qy_pack_seed_guard');
  addTearDown(() => root.delete(recursive: true));
  return root;
}

/// The install must leave no dot-part behind when the seed is refused.
List<File> _partials(Directory root) => root.existsSync()
    ? root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.part'))
        .toList()
    : const <File>[];

void main() {
  group('pack seed guard', () {
    test('an untrusted https seed is rejected before any request is sent',
        () async {
      final db = newTestDb();
      final root = await _newRoot();
      final adapter = _RecordingAdapter(utf8.encode(_body));
      final downloader = PackDownloader(
        db,
        dio: Dio()..httpClientAdapter = adapter,
        libraryRootResolver: () async => root,
      );

      await expectLater(
        downloader.install(_pack(sourceUrl: 'https://evil.example/pack.json')),
        throwsA(isA<PackFailure>()),
      );

      expect(adapter.requested, isEmpty);
      expect(await downloader.installedPacks(), isEmpty);
      expect(_partials(root), isEmpty);
    });

    test('a plain-http seed on the trusted host is rejected before any request',
        () async {
      final db = newTestDb();
      final root = await _newRoot();
      final adapter = _RecordingAdapter(utf8.encode(_body));
      final downloader = PackDownloader(
        db,
        dio: Dio()..httpClientAdapter = adapter,
        libraryRootResolver: () async => root,
      );

      await expectLater(
        downloader.install(
          _pack(sourceUrl: 'http://cdn.jsdelivr.net/pack.json'),
        ),
        throwsA(isA<PackFailure>()),
      );

      expect(adapter.requested, isEmpty);
      expect(await downloader.installedPacks(), isEmpty);
      expect(_partials(root), isEmpty);
    });

    test('a trusted https jsDelivr seed still installs', () async {
      final db = newTestDb();
      final root = await _newRoot();
      final adapter = _RecordingAdapter(utf8.encode(_body));
      final downloader = PackDownloader(
        db,
        dio: Dio()..httpClientAdapter = adapter,
        libraryRootResolver: () async => root,
      );
      const url = 'https://cdn.jsdelivr.net/gh/owner/repo/pack.min.json';

      final file = await downloader.install(
        _pack(
          sourceUrl: url,
          sha256Hex: sha256.convert(utf8.encode(_body)).toString(),
        ),
      );

      expect(adapter.requested, [url]);
      expect(file.existsSync(), isTrue);
      expect(_partials(root), isEmpty);
      expect(await downloader.isInstalled('seed-guard', '1'), isTrue);
    });
  });
}
