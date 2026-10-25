import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/hadith_store.dart';

import 'support/test_db.dart';

void main() {
  test('pages an imported projection by ordinal', () async {
    final db = newTestDb();
    final store = HadithStore(db, packPath: (_) async => null);
    await store.importProjection('p', [
      for (var i = 0; i < 25; i++) (i + 1, 'حديث ${i + 1}'),
    ]);

    final first = await store.hadithPage('p', 0, 20);
    expect(first.$1, hasLength(20));
    expect(first.$1.first.$1, 1);
    expect(first.$2, true);

    final second = await store.hadithPage('p', 20, 20);
    expect(second.$1, hasLength(5));
    expect(second.$1.last.$1, 25);
    expect(second.$2, false);

    final beyond = await store.hadithPage('p', 99, 20);
    expect(beyond.$1, isEmpty);
    expect(beyond.$2, false);
  });

  test('keeps malformed entries as empty text and filters them', () async {
    final db = newTestDb();
    final store = HadithStore(db, packPath: (_) async => null);
    await store.importProjection('p', [null, (1, 'ok'), null]);

    final page = await store.hadithPage('p', 0, 10);
    expect(page.$1, [(1, 'ok')]);
    expect(page.$2, false);
  });

  test('lazy-imports an installed pack file on first page', () async {
    final db = newTestDb();
    final dir = Directory.systemTemp.createTempSync('qy_hadith_store');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/p.json')
      ..writeAsStringSync(jsonEncode({
        'hadiths': [
          {'hadithnumber': 1, 'text': 'first'},
          {'hadithnumber': 2, 'text': 'second'},
        ],
      }));
    final store = HadithStore(
      db,
      packPath: (_) async => file.path,
      fileDecoder: (path) async => jsonDecode(File(path).readAsStringSync()),
    );

    final page = await store.hadithPage('p', 0, 10);
    expect(page.$1, [(1, 'first'), (2, 'second')]);
    expect(page.$2, false);
  });

  test('deletePack removes the imported rows', () async {
    final db = newTestDb();
    final store = HadithStore(db, packPath: (_) async => null);
    await store.importProjection('p', [(1, 'ok')]);

    await store.deletePack('p');

    final page = await store.hadithPage('p', 0, 10);
    expect(page.$1, isEmpty);
  });
}
