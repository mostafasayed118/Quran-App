import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/library/data/pack_downloader.dart';

import 'support/test_db.dart';

void main() {
  test('hadith pages stay available after the pack file is deleted', () async {
    final db = newTestDb();
    final tempRoot = await Directory.systemTemp.createTemp('qy_hadith_db');
    addTearDown(() => tempRoot.delete(recursive: true));
    final libraryDir = Directory('${tempRoot.path}/library')
      ..createSync(recursive: true);
    File('test/fixtures/hadith_eng_muslim_excerpt.json')
        .copySync('${libraryDir.path}/en-muslim.json');
    await db.into(db.installedPacks).insert(InstalledPacksCompanion.insert(
          packId: 'en-muslim',
          kind: 'hadith',
          language: 'en',
          title: 'Sahih Muslim',
          sizeMb: 1,
          version: '1',
        ));

    final downloader = PackDownloader(
      db,
      libraryRootResolver: () async => tempRoot,
      fileDecoder: (path) async => jsonDecode(File(path).readAsStringSync()),
    );

    final first = await downloader.hadithPage('en-muslim', 0, 10);
    expect(first.$1, hasLength(10));
    expect(first.$2, true);
    final imported = await db
        .customSelect('SELECT COUNT(*) AS c FROM hadith_entries')
        .getSingle();
    expect(imported.read<int>('c'), 12,
        reason: 'the first page must import every pack row into the DB');

    // The DB is now the read index: deleting the canonical file must not
    // empty the browse screen.
    File('${libraryDir.path}/en-muslim.json').deleteSync();

    final second = await downloader.hadithPage('en-muslim', 0, 10);
    expect(second.$1, hasLength(10));
    expect(second.$2, true);

    final last = await downloader.hadithPage('en-muslim', 10, 10);
    expect(last.$1, hasLength(2));
    expect(last.$2, false);
  });
}
