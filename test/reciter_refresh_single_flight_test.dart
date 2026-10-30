import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';

import 'support/test_db.dart';

const _fixture = '''
{"reciters":[
 {"id":51,"name":"عبدالباسط عبدالصمد","letter":"ع","moshaf":[
   {"id":53,"name":"حفص عن عاصم - مرتل","server":"https://server11.mp3quran.net/basit/","surah_total":114,"surah_list":"1,2,3"}]}
]}
''';

void main() {
  test('concurrent refreshes share one HTTP request and one table rewrite',
      () async {
    final db = newTestDb();
    addTearDown(db.close);
    final gate = Completer<void>();
    var requests = 0;
    final server = await HttpServer.bind('127.0.0.1', 0);
    addTearDown(() async => server.close(force: true));
    server.listen((req) async {
      requests++;
      await gate.future;
      req.response.headers.contentType = ContentType.json;
      req.response.write(_fixture);
      await req.response.close();
    });

    final repo = ReciterRepository(
      db,
      client: http.Client(),
      apiEndpointOverride:
          'http://127.0.0.1:${server.port}/api/v3/reciters?language=ar',
    );

    final first = repo.refreshFromApi();
    final second = repo.refreshFromApi();
    gate.complete();
    await Future.wait([first, second]);

    expect(requests, 1);
    expect(await db.select(db.reciters).get(), hasLength(1));
  });
}
