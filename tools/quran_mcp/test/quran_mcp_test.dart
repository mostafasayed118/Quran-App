import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Absolute path to the app checkout, resolved from `tools/quran_mcp`.
final String _repoRoot = Directory('../../').absolute.path;

void main() {
  group('content database', () {
    late _McpClient client;

    setUpAll(() async {
      if (!File('$_repoRoot/assets/db/quran.sqlite').existsSync()) {
        fail('run this suite from tools/quran_mcp inside the app checkout');
      }
      client = await _McpClient.start(_repoRoot);
    });

    tearDownAll(() async {
      await client.close();
    });

    test('exposes both tools', () async {
      final response = await client.request('tools/list');
      final result = response['result']! as Map<String, dynamic>;
      final tools = result['tools']! as List<dynamic>;
      expect(
        tools.map((tool) => (tool as Map<String, dynamic>)['name']),
        containsAll(<String>['quran_search', 'quran_surah']),
      );
    });

    test('الصلاة matches 61 ayahs in mushaf order', () async {
      final result = await client.callTool('quran_search', {'query': 'الصلاة'});
      expect(result.isError, isFalse);
      final body = result.json;
      expect(body['strategy'], 'fts5-trigram');
      expect(body['script'], 'imlaei');
      expect(body['total'], 61);
      expect(body['returned'], 10);
      expect(body['has_more'], isTrue);
      final first = (body['results']! as List<dynamic>).first;
      expect((first as Map<String, dynamic>)['surah'], 2);
      expect(first['ayah'], 3);
    });

    test('الصلاة limited to al-Baqarah is 9 matches', () async {
      final result = await client.callTool('quran_search', {
        'query': 'الصلاة',
        'surah': 2,
      });
      final body = result.json;
      expect(body['total'], 9);
      expect(body['returned'], 9);
      expect(body['has_more'], isFalse);
      for (final row in body['results']! as List<dynamic>) {
        expect((row as Map<String, dynamic>)['surah'], 2);
      }
    });

    test(
      'the Uthmani spelling الصلوة does not match the imla i index',
      () async {
        final result = await client.callTool('quran_search', {
          'query': 'الصلوة',
        });
        final body = result.json;
        expect(body['strategy'], 'fts5-trigram');
        expect(body['total'], 0);
        expect(body['returned'], 0);
        expect(body['has_more'], isFalse);
      },
    );

    test('a one-letter query is rejected like the app rejects it', () async {
      final result = await client.callTool('quran_search', {'query': 'ا'});
      expect(result.isError, isTrue);
      expect(result.text, contains('at least 2'));
    });

    test('an out-of-range surah filter is an error', () async {
      final result = await client.callTool('quran_search', {
        'query': 'الصلاة',
        'surah': 115,
      });
      expect(result.isError, isTrue);
      expect(result.text, contains('between 1 and 114'));
    });

    test('limit is capped at 50', () async {
      final result = await client.callTool('quran_search', {
        'query': 'الصلاة',
        'limit': 500,
      });
      final body = result.json;
      expect(body['returned'], 50);
      expect(body['total'], 61);
      expect(body['has_more'], isTrue);
    });

    test('offset walks the same page without changing the total', () async {
      final page = await client.callTool('quran_search', {
        'query': 'الصلاة',
        'limit': 3,
      });
      final skipped = await client.callTool('quran_search', {
        'query': 'الصلاة',
        'limit': 3,
        'offset': 1,
      });
      final pageRows = page.json['results']! as List<dynamic>;
      final skippedRows = skipped.json['results']! as List<dynamic>;
      expect(skipped.json['total'], 61);
      expect(skipped.json['offset'], 1);
      expect(skipped.json['returned'], 3);
      expect(skippedRows.first, pageRows[1]);
      expect(skipped.json['has_more'], isTrue);

      final pastEnd = await client.callTool('quran_search', {
        'query': 'الصلاة',
        'offset': 100,
      });
      expect(pastEnd.json['returned'], 0);
      expect(pastEnd.json['has_more'], isFalse);
    });

    test('quran_surah returns the name and both scripts', () async {
      final result = await client.callTool('quran_surah', {
        'surah': 2,
        'limit': 1,
      });
      expect(result.isError, isFalse);
      final body = result.json;
      expect(body['surah'], 2);
      expect(body['surah_name'], 'البقرة');
      expect(body['script'], 'uthmani');
      expect(body['ayah_count'], 286);
      final first = (body['ayahs']! as List<dynamic>).first;
      expect((first as Map<String, dynamic>)['ayah'], 1);
      expect(first['text'], 'الٓمٓ');
      expect(first['text_imlaei'], 'الم');
    });

    test('quran_surah returns the requested slice of al-Fatiha', () async {
      final result = await client.callTool('quran_surah', {
        'surah': 1,
        'limit': 3,
      });
      final body = result.json;
      expect(body['ayah_count'], 7);
      expect(body['ayahs'], hasLength(3));
    });
  });

  // A second server runs against a copy of the content database: the native
  // sqlite3 asset can only be bundled once at a time, so this group starts
  // after the group above has closed its process.
  group('content database without ayah_search', () {
    _McpClient? broken;
    Directory? temp;

    setUpAll(() async {
      final root = temp = Directory.systemTemp.createTempSync(
        'quran_mcp_nofts_',
      );
      final database = Directory('${root.path}/assets/db')
        ..createSync(recursive: true);
      final uthmani = Directory('${root.path}/assets/quran/uthmani')
        ..createSync(recursive: true);
      final copy = File('$_repoRoot/assets/db/quran.sqlite')
          .copySync('${database.path}/quran.sqlite');
      File('$_repoRoot/assets/quran/uthmani/1.json')
          .copySync('${uthmani.path}/1.json');
      File('${uthmani.path}/114.json').writeAsStringSync('{not json');

      final drop = await Process.run(Platform.resolvedExecutable, [
        'run',
        'test/fixtures/drop_search_index.dart',
        copy.path,
      ], workingDirectory: Directory.current.path);
      if (drop.exitCode != 0) {
        fail('could not drop ayah_search: ${drop.stderr}');
      }

      broken = await _McpClient.start(root.path);
    });

    tearDownAll(() async {
      await broken?.close();
      final root = temp;
      if (root == null) return;
      for (var attempt = 0; attempt < 10; attempt++) {
        try {
          root.deleteSync(recursive: true);
          return;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
      root.deleteSync(recursive: true);
    });

    test('fails closed but not silently', () async {
      final search = await broken!.callTool('quran_search', {
        'query': 'الصلاة',
      });
      expect(search.isError, isTrue);
      expect(search.text, contains('ayah_search'));

      final surah = await broken!.callTool('quran_surah', {
        'surah': 1,
        'limit': 2,
      });
      expect(surah.isError, isFalse);
      expect(surah.json['ayah_count'], 7);
      final firstAyah =
          (surah.json['ayahs']! as List<dynamic>).first as Map<String, dynamic>;
      expect(firstAyah['text_imlaei'], isNotNull);

      final corrupt = await broken!.callTool('quran_surah', {'surah': 114});
      expect(corrupt.isError, isTrue);
      expect(corrupt.text, contains('corrupt'));
    });
  });
}

class _McpClient {
  _McpClient(this._process)
    : _lines = StreamIterator(
        _process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
      ) {
    _process.stderr.transform(utf8.decoder).listen(_stderr.write);
  }

  static Future<_McpClient> start(String root) async {
    final process = await Process.start(Platform.resolvedExecutable, [
      'run',
      'bin/server.dart',
      '--root',
      root,
    ], workingDirectory: Directory.current.path);
    final client = _McpClient(process);
    final init = await client.request('initialize', {
      'protocolVersion': '2025-06-18',
      'capabilities': <String, Object?>{},
      'clientInfo': {'name': 'quran_mcp_test', 'version': '1.0.0'},
    });
    if (init['error'] != null) {
      throw StateError('initialize failed: ${init['error']}');
    }
    await client.notify('notifications/initialized');
    return client;
  }

  final Process _process;
  final StreamIterator<String> _lines;
  final StringBuffer _stderr = StringBuffer();
  int _lastId = 0;

  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, Object?>? params,
  ]) async {
    final id = ++_lastId;
    _process.stdin.writeln(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': ?params,
      }),
    );
    await _process.stdin.flush();
    while (await _lines.moveNext()) {
      final message = jsonDecode(_lines.current) as Map<String, dynamic>;
      if (message['id'] == id) return message;
    }
    throw StateError(
      'server exited before answering $method: ${_stderr.toString()}',
    );
  }

  Future<void> notify(String method, [Map<String, Object?>? params]) async {
    _process.stdin.writeln(
      jsonEncode({'jsonrpc': '2.0', 'method': method, 'params': ?params}),
    );
    await _process.stdin.flush();
  }

  Future<_ToolResult> callTool(
    String name,
    Map<String, Object?> arguments,
  ) async {
    final message = await request('tools/call', {
      'name': name,
      'arguments': arguments,
    });
    final result = message['result']! as Map<String, dynamic>;
    final content = (result['content']! as List<dynamic>).first;
    final text = (content as Map<String, dynamic>)['text']! as String;
    Object? body;
    try {
      body = jsonDecode(text);
    } on FormatException {
      body = null;
    }
    return _ToolResult(
      isError: result['isError'] == true,
      body: body,
      text: text,
    );
  }

  Future<void> close() async {
    await _process.stdin.close();
    try {
      await _process.exitCode.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      _process.kill();
    }
    await _lines.cancel();
  }
}

class _ToolResult {
  const _ToolResult({
    required this.isError,
    required this.body,
    required this.text,
  });

  final bool isError;
  final Object? body;
  final String text;

  Map<String, dynamic> get json => body! as Map<String, dynamic>;
}
