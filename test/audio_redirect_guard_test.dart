import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart'
    show surahAudioUrl;

import 'support/test_db.dart';

/// One canned response served for a requested URI.
class _Hop {
  _Hop.redirect(this.status, String this.location) : body = const <int>[];

  _Hop.ok(this.body)
      : status = 200,
        location = null;

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
      Headers.contentTypeHeader: ['audio/mpeg'],
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

const _trustedServer = 'https://server.mp3quran.net/mp3';
final String _firstUrl = surahAudioUrl(_trustedServer, 1);

Future<ReciterRow> _seedReciter(AppDatabase db, String server) async {
  await db.into(db.reciters).insert(RecitersCompanion.insert(
        id: '51-53',
        reciterName: 'عبدالباسط عبدالصمد',
        moshafName: 'حفص مرتل',
        server: server,
        surahList: '1',
        surahTotal: 114,
      ));
  return (db.select(db.reciters)).getSingle();
}

/// Not a single staged `.part` may survive any failed download.
List<File> _partFiles(Directory root) {
  if (!root.existsSync()) return const <File>[];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.part'))
      .toList();
}

Future<Directory> _newRoot(String tag) async {
  final root = await Directory.systemTemp.createTemp(tag);
  addTearDown(() => root.delete(recursive: true));
  return root;
}

Future<AudioDownloader> _downloader(
  AppDatabase db,
  Directory root,
  _HopAdapter adapter,
) async =>
    AudioDownloader(
      db,
      dio: Dio()..httpClientAdapter = adapter,
      audioRootResolver: () async => root,
    );

void main() {
  test('trusted relative and absolute redirects are followed to the limit',
      () async {
    final db = newTestDb();
    final root = await _newRoot('qy_audio_redirect_ok');
    final reciter = await _seedReciter(db, _trustedServer);
    final body = List<int>.generate(4096, (i) => i % 251);
    final adapter = _HopAdapter({
      _firstUrl: _Hop.redirect(302, '/h1/001.mp3'),
      'https://server.mp3quran.net/h1/001.mp3':
          _Hop.redirect(307, 'https://cdn.mp3quran.net/h2/001.mp3'),
      'https://cdn.mp3quran.net/h2/001.mp3':
          _Hop.redirect(308, '../h3/001.mp3'),
      'https://cdn.mp3quran.net/h3/001.mp3': _Hop.ok(body),
    });
    final downloader = await _downloader(db, root, adapter);

    final file =
        await downloader.downloadSurah(reciter: reciter, surahNumber: 1);

    expect(file.existsSync(), isTrue);
    expect(await file.readAsBytes(), body);
    expect(adapter.requested, <String>[
      _firstUrl,
      'https://server.mp3quran.net/h1/001.mp3',
      'https://cdn.mp3quran.net/h2/001.mp3',
      'https://cdn.mp3quran.net/h3/001.mp3',
    ]);
    expect(adapter.followRedirectFlags, everyElement(isFalse),
        reason: 'every hop must be followed by the guard, not by Dio');
    expect(_partFiles(root), isEmpty);
    final row = await (db.select(db.downloads)).getSingle();
    expect(row.status, 'done');
    expect(row.bytes, body.length);
  });

  test('a redirect to http:// fails and never serves bytes', () async {
    final db = newTestDb();
    final root = await _newRoot('qy_audio_redirect_http');
    final reciter = await _seedReciter(db, _trustedServer);
    final adapter = _HopAdapter({
      _firstUrl: _Hop.redirect(301, 'http://cdn.mp3quran.net/001.mp3'),
      'http://cdn.mp3quran.net/001.mp3': _Hop.ok(List<int>.filled(8, 1)),
    });
    final downloader = await _downloader(db, root, adapter);

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DownloadFailure>()),
    );

    expect(adapter.requested, <String>[_firstUrl],
        reason: 'the insecure hop must be rejected before it is requested');
    expect(_partFiles(root), isEmpty);
    final row = await (db.select(db.downloads)).getSingle();
    expect(row.status, 'failed');
  });

  test('a redirect to a foreign host fails and is never requested', () async {
    final db = newTestDb();
    final root = await _newRoot('qy_audio_redirect_foreign');
    final reciter = await _seedReciter(db, _trustedServer);
    final adapter = _HopAdapter({
      _firstUrl: _Hop.redirect(302, 'https://evil.example/001.mp3'),
      'https://evil.example/001.mp3': _Hop.ok(List<int>.filled(8, 2)),
    });
    final downloader = await _downloader(db, root, adapter);

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DownloadFailure>()),
    );

    expect(adapter.requested, <String>[_firstUrl]);
    expect(_partFiles(root), isEmpty);
    final row = await (db.select(db.downloads)).getSingle();
    expect(row.status, 'failed');
  });

  test('a four-hop chain exceeds the limit and fails', () async {
    final db = newTestDb();
    final root = await _newRoot('qy_audio_redirect_long');
    final reciter = await _seedReciter(db, _trustedServer);
    final adapter = _HopAdapter({
      _firstUrl: _Hop.redirect(302, '/h1/001.mp3'),
      'https://server.mp3quran.net/h1/001.mp3':
          _Hop.redirect(302, '/h2/001.mp3'),
      'https://server.mp3quran.net/h2/001.mp3':
          _Hop.redirect(302, '/h3/001.mp3'),
      'https://server.mp3quran.net/h3/001.mp3':
          _Hop.redirect(302, '/h4/001.mp3'),
      'https://server.mp3quran.net/h4/001.mp3': _Hop.ok(List<int>.filled(8, 3)),
    });
    final downloader = await _downloader(db, root, adapter);

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DownloadFailure>()),
    );

    expect(adapter.requested, hasLength(4),
        reason: 'the initial request plus exactly three followed hops');
    expect(adapter.requested,
        isNot(contains('https://server.mp3quran.net/h4/001.mp3')));
    expect(_partFiles(root), isEmpty);
    final row = await (db.select(db.downloads)).getSingle();
    expect(row.status, 'failed');
  });

  test('a redirect without Location fails', () async {
    final db = newTestDb();
    final root = await _newRoot('qy_audio_redirect_nolocation');
    final reciter = await _seedReciter(db, _trustedServer);
    final adapter = _HopAdapter({_firstUrl: _Hop.redirect(302, '')});
    final downloader = await _downloader(db, root, adapter);

    await expectLater(
      downloader.downloadSurah(reciter: reciter, surahNumber: 1),
      throwsA(isA<DownloadFailure>()),
    );

    expect(adapter.requested, <String>[_firstUrl]);
    expect(_partFiles(root), isEmpty);
    final row = await (db.select(db.downloads)).getSingle();
    expect(row.status, 'failed');
  });

  test('the initial URL is still requested for a non-redirect 200', () async {
    final db = newTestDb();
    final root = await _newRoot('qy_audio_redirect_plain');
    final reciter = await _seedReciter(db, _trustedServer);
    final body = List<int>.generate(512, (i) => i % 251);
    final adapter = _HopAdapter({_firstUrl: _Hop.ok(body)});
    final downloader = await _downloader(db, root, adapter);

    final file =
        await downloader.downloadSurah(reciter: reciter, surahNumber: 1);

    expect(file.path, endsWith('001.mp3'));
    expect(await file.readAsBytes(), body);
    expect(adapter.requested, <String>[_firstUrl]);
  });
}
