import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';
import 'package:quran_yahdi/features/library/data/pack_redirect_guard.dart';

import 'support/test_db.dart';

/// One canned response served for a requested URI.
class _Hop {
  _Hop.redirect(this.status, String this.location) : body = const <int>[];

  final int status;
  final String? location;
  final List<int> body;
}

/// Serves [hops] by exact request URI; an unscripted URI fails the test.
class _HopAdapter implements HttpClientAdapter {
  _HopAdapter(this.hops);

  final Map<String, _Hop> hops;
  final List<String> requested = <String>[];
  final List<bool?> followRedirectFlags = <bool?>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final uri = options.uri.toString();
    requested.add(uri);
    followRedirectFlags.add(options.followRedirects);
    final hop = hops[uri];
    if (hop == null) throw StateError('unexpected request: $uri');
    final headers = <String, List<String>>{
      Headers.contentLengthHeader: ['${hop.body.length}'],
      Headers.contentTypeHeader: ['application/json'],
    };
    final location = hop.location;
    if (location != null) headers['location'] = [location];
    return ResponseBody(
      Stream<Uint8List>.value(Uint8List.fromList(hop.body)),
      hop.status,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

LibraryPackInfo _pack(String sourceUrl) => LibraryPackInfo(
      id: 'redirect-test',
      kind: LibraryPackKind.translation,
      language: 'en',
      titleAr: 't',
      titleEn: 't',
      approxSizeMb: 0.001,
      version: '1',
      sourceUrl: sourceUrl,
      sha256: List.filled(64, 'a').join(),
    );

Future<Directory> _newRoot() async {
  final root = await Directory.systemTemp.createTemp('qy_pack_redirect');
  addTearDown(() => root.delete(recursive: true));
  return root;
}

void main() {
  group('pack redirect guard', () {
    test('trusted HTTPS jsDelivr is allowed', () {
      expect(
        isTrustedPackUri(Uri.parse('https://cdn.jsdelivr.net/pack.json')),
        isTrue,
      );
    });

    test('http, foreign hosts, and non-443 ports are rejected', () {
      expect(
        isTrustedPackUri(Uri.parse('http://cdn.jsdelivr.net/pack.json')),
        isFalse,
      );
      expect(
        isTrustedPackUri(Uri.parse('https://evil.example/pack.json')),
        isFalse,
      );
      expect(
        isTrustedPackUri(
          Uri.parse('https://cdn.jsdelivr.net.evil.example/pack.json'),
        ),
        isFalse,
      );
      expect(
        isTrustedPackUri(
          Uri.parse('https://cdn.jsdelivr.net:8443/pack.json'),
        ),
        isFalse,
      );
    });

    test('relative and absolute trusted redirects resolve', () {
      final current = Uri.parse('https://cdn.jsdelivr.net/a/start.json');
      expect(
        resolveTrustedPackRedirect(current, '../final.json').toString(),
        'https://cdn.jsdelivr.net/final.json',
      );
      expect(
        resolveTrustedPackRedirect(
          current,
          'https://cdn.jsdelivr.net/b/final.json',
        ).toString(),
        'https://cdn.jsdelivr.net/b/final.json',
      );
    });

    test('a foreign absolute redirect throws', () {
      expect(
        () => resolveTrustedPackRedirect(
          Uri.parse('https://cdn.jsdelivr.net/start.json'),
          'https://evil.example/pack.json',
        ),
        throwsA(isA<PackRedirectException>()),
      );
    });
  });

  group('pack downloader', () {
    test('a redirect to a foreign host is rejected before it is requested',
        () async {
      final db = newTestDb();
      addTearDown(db.close);
      final root = await _newRoot();
      final adapter = _HopAdapter({
        'https://cdn.jsdelivr.net/start.json':
            _Hop.redirect(302, 'https://evil.example/pack.json'),
      });
      final downloader = PackDownloader(
        db,
        dio: Dio()..httpClientAdapter = adapter,
        libraryRootResolver: () async => root,
      );

      await expectLater(
        downloader.install(_pack('https://cdn.jsdelivr.net/start.json')),
        throwsA(isA<PackFailure>()),
      );
      expect(adapter.requested, ['https://cdn.jsdelivr.net/start.json']);
      expect(adapter.followRedirectFlags, [false]);
      final parts = root.existsSync()
          ? root
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.part'))
          : const <File>[];
      expect(parts, isEmpty);
    });

    test('a redirect to http is rejected before it is requested', () async {
      final db = newTestDb();
      addTearDown(db.close);
      final root = await _newRoot();
      final adapter = _HopAdapter({
        'https://cdn.jsdelivr.net/start.json':
            _Hop.redirect(301, 'http://cdn.jsdelivr.net/pack.json'),
      });
      final downloader = PackDownloader(
        db,
        dio: Dio()..httpClientAdapter = adapter,
        libraryRootResolver: () async => root,
      );

      await expectLater(
        downloader.install(_pack('https://cdn.jsdelivr.net/start.json')),
        throwsA(isA<PackFailure>()),
      );
      expect(adapter.requested, ['https://cdn.jsdelivr.net/start.json']);
    });

    test('a redirect chain beyond the hop cap fails closed', () async {
      final db = newTestDb();
      addTearDown(db.close);
      final root = await _newRoot();
      final adapter = _HopAdapter({
        'https://cdn.jsdelivr.net/start.json': _Hop.redirect(302, '/h1.json'),
        'https://cdn.jsdelivr.net/h1.json': _Hop.redirect(302, '/h2.json'),
        'https://cdn.jsdelivr.net/h2.json': _Hop.redirect(302, '/h3.json'),
        'https://cdn.jsdelivr.net/h3.json': _Hop.redirect(302, '/h4.json'),
      });
      final downloader = PackDownloader(
        db,
        dio: Dio()..httpClientAdapter = adapter,
        libraryRootResolver: () async => root,
      );

      await expectLater(
        downloader.install(_pack('https://cdn.jsdelivr.net/start.json')),
        throwsA(isA<PackFailure>()),
      );
      expect(adapter.requested, [
        'https://cdn.jsdelivr.net/start.json',
        'https://cdn.jsdelivr.net/h1.json',
        'https://cdn.jsdelivr.net/h2.json',
        'https://cdn.jsdelivr.net/h3.json',
      ]);
    });
  });
}
