import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';

import 'support/test_db.dart';

const _fixture = '''
{"reciters":[
 {"id":51,"name":"عبدالباسط عبدالصمد","letter":"ع","moshaf":[
   {"id":53,"name":"حفص عن عاصم - مرتل","server":"https://server11.mp3quran.net/basit/","surah_total":114,"surah_list":"1,2,3"}]},
 {"id":123,"name":"مشاري العفاسي","letter":"م","moshaf":[
   {"id":123,"name":"حفص عن عاصم - مرتل","server":"https://server8.mp3quran.net/afs/","surah_total":114,"surah_list":"2,1"}]}
]}
''';

/// First-run playback depends on the catalog being fetched before the reader's
/// play button resolves `defaultReciter()`. `ensureCatalog` is that warm-up:
/// one fetch on an empty table, none once the catalog exists.
void main() {
  late AppDatabase db;
  late HttpServer server;
  late String endpoint;
  var hits = 0;

  setUp(() async {
    db = newTestDb();
    hits = 0;
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((request) async {
      hits++;
      request.response.headers.contentType = ContentType.json;
      request.response.write(_fixture);
      await request.response.close();
    });
    endpoint = 'http://127.0.0.1:${server.port}/api/v3/reciters?language=ar';
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('empty catalog: one fetch, then the default reciter resolves', () async {
    final repo = ReciterRepository(
      db,
      client: http.Client(),
      apiEndpointOverride: endpoint,
    );

    expect(await repo.ensureCatalog(), isTrue);
    expect(hits, 1);
    expect(await repo.defaultReciter(), isNotNull);
  });

  test('warm catalog: no network call', () async {
    final repo = ReciterRepository(
      db,
      client: http.Client(),
      apiEndpointOverride: endpoint,
    );

    expect(await repo.ensureCatalog(), isTrue); // seeds
    expect(await repo.ensureCatalog(), isFalse); // no second fetch
    expect(hits, 1);
  });
}
