import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';

import 'support/test_db.dart';

const fixture = '''
{"reciters":[
 {"id":51,"name":"عبدالباسط عبدالصمد","letter":"ع","moshaf":[
   {"id":53,"name":"حفص عن عاصم - مرتل","server":"https://server11.mp3quran.net/basit/","surah_total":114,"surah_list":"1,2,3"},
   {"id":51,"name":"المصحف المجود","server":"https://server11.mp3quran.net/mujawwad/","surah_total":114,"surah_list":"1,2"}]},
 {"id":123,"name":"مشاري العفاسي","letter":"م","moshaf":[
   {"id":123,"name":"حفص عن عاصم - مرتل","server":"https://server8.mp3quran.net/afs/","surah_total":114,"surah_list":"2,1"}]}
]}
''';

void main() {
  late AppDatabase db;
  late ReciterRepository repo;

  setUp(() {
    db = newTestDb();
    repo = ReciterRepository(db);
  });

  test('pure helpers: url building + parse + featured sort', () {
    expect(surahAudioFileName(2), '002.mp3');
    expect(surahAudioFileName(114), '114.mp3');
    expect(surahAudioUrl('https://srv.net/afs/', 1),
        'https://srv.net/afs/001.mp3');
    expect(surahAudioUrl('https://srv.net/afs', 1),
        'https://srv.net/afs/001.mp3');
    expect(parseSurahList(' 1, 2 ,x,3 '), [1, 2, 3]);

    final sorted = sortReciters([
      _row(id: '123-123', name: 'مشاري العفاسي'),
      _row(id: '55-55', name: 'أحمد العجمي'),
      _row(id: '51-53', name: 'عبدالباسط عبدالصمد'),
      _row(id: '4-4', name: 'الشاطري'),
    ]);
    // PM-verified featured order: 51 before 123 before 4 (W2a disclosure:
    // plan fixture line contradicted the embedded featuredReciterIds ranks).
    expect(sorted.map((r) => r.id).toList(),
        ['51-53', '123-123', '4-4', '55-55']);
  });

  test('refreshFromApi wipes + inserts moshaf rows (local server)', () async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.write(fixture);
      await req.response.close();
    });
    addTearDown(() async => server.close(force: true));

    final hosted =
        'http://127.0.0.1:${server.port}/api/v3/reciters?language=ar';
    final netRepo = ReciterRepository(
      db,
      client: http.Client(),
      apiEndpointOverride: hosted,
    );
    await netRepo.refreshFromApi();

    final rows = await db.select(db.reciters).get();
    expect(rows, hasLength(3));
    final basit = rows.firstWhere((r) => r.id == '51-53');
    expect(basit.reciterName, 'عبدالباسط عبدالصمد');
    expect(parseSurahList(basit.surahList), [1, 2, 3]);

    // Idempotent re-run: still 3 rows, no dupes.
    await netRepo.refreshFromApi();
    expect(await db.select(db.reciters).get(), hasLength(3));
  });

  test('malformed API entries are skipped, never crash the refresh', () async {
    const messyFixture = '''
    {"reciters":[
     "not-a-map",
     {"name":"no id","moshaf":[]},
     {"id":"99","name":"bad id","moshaf":[]},
     {"id":7,"name":"bad moshaf entries","moshaf":[
       {"id":1,"name":"bad server","server":123},
       {"id":2,"name":"missing server"}
     ]},
     {"id":51,"name":"عبدالباسط عبدالصمد","moshaf":[
       {"id":53,"name":"حفص عن عاصم - مرتل","server":"https://server11.mp3quran.net/basit/","surah_total":114,"surah_list":"1,2,3"}
     ]}
    ]}
    ''';
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.write(messyFixture);
      await req.response.close();
    });
    addTearDown(() async => server.close(force: true));

    final netRepo = ReciterRepository(
      db,
      client: http.Client(),
      apiEndpointOverride:
          'http://127.0.0.1:${server.port}/api/v3/reciters?language=ar',
    );
    await netRepo.refreshFromApi();

    final rows = await db.select(db.reciters).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, '51-53');
  });

  test('moshaf rows with untrusted or non-https servers are dropped',
      () async {
    const evilFixture = '''
    {"reciters":[
     {"id":51,"name":"عبدالباسط عبدالصمد","letter":"ع","moshaf":[
       {"id":53,"name":"حفص عن عاصم - مرتل","server":"https://server11.mp3quran.net/basit/","surah_total":114,"surah_list":"1,2,3"},
       {"id":51,"name":"المصحف المجود","server":"http://server11.mp3quran.net/mujawwad/","surah_total":114,"surah_list":"1,2"},
       {"id":52,"name":"مشبوه","server":"https://evil.example.net/x/","surah_total":114,"surah_list":"1"}]}
    ]}
    ''';
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      req.response.headers.contentType = ContentType.json;
      req.response.write(evilFixture);
      await req.response.close();
    });
    addTearDown(() async => server.close(force: true));

    final netRepo = ReciterRepository(
      db,
      client: http.Client(),
      apiEndpointOverride:
          'http://127.0.0.1:${server.port}/api/v3/reciters?language=ar',
    );
    await netRepo.refreshFromApi();

    final rows = await db.select(db.reciters).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, '51-53');
  });

  test('selection persists + loads', () async {
    expect(await repo.loadSelectedMoshaf(), isNull);
    await repo.selectMoshaf('51-53');
    expect(await repo.loadSelectedMoshaf(), '51-53');
  });
}

ReciterRow _row({required String id, required String name}) => ReciterRow(
      id: id,
      reciterName: name,
      moshafName: 'مرتل',
      server: 'https://x/',
      surahList: '1',
      surahTotal: 114,
    );
