import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/connection.dart';
import 'package:quran_yahdi/core/db/content_version.dart';

void main() {
  late Directory tempDir;
  var loaderCalls = 0;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('qy_refresh');
    loaderCalls = 0;
  });
  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<File> buildSeed(
      {required String version, required String nameAr}) async {
    final file = File(p.join(tempDir.path, 'seed.sqlite'));
    final db = AppDatabase(NativeDatabase(file));
    await db.createSchemaForSeeding();
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(1),
          nameAr: nameAr,
          nameEn: 'Seed',
          revelationType: 'meccan',
          ayahCount: 7,
          pagesStart: 1,
          pagesEnd: 1,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(1),
          surahId: 1,
          numberInSurah: 1,
          juz: 1,
          page: 1,
          textUthmani: 'seed',
          textImlaei: 'seed',
        ));
    await db.into(db.settingsTable).insert(
        SettingsTableCompanion.insert(key: kContentVersionKey, value: version));
    await db.close();
    return file;
  }

  Future<ByteData> loaderFor(File seed) async {
    loaderCalls++;
    final bytes = seed.readAsBytesSync();
    return ByteData.view(
        bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);
  }

  Future<AppDatabase> staleDb() async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.createSchemaForSeeding();
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(1),
          nameAr: 'قديم',
          nameEn: 'Old',
          revelationType: 'meccan',
          ayahCount: 7,
          pagesStart: 1,
          pagesEnd: 1,
        ));
    return db;
  }

  test('stale installed content is re-seeded; user rows survive; version bumps',
      () async {
    final seed = await buildSeed(version: '7', nameAr: 'مجدّد');
    final db = await staleDb();
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(ayahId: 1));

    await ensureContentCurrent(db.executor,
        loadAsset: (_) => loaderFor(seed), tempDir: tempDir, bundledVersion: 7);

    expect(loaderCalls, 1);
    expect((await db.select(db.surahs).get()).single.nameAr, 'مجدّد');
    expect((await db.select(db.ayahs).get()).length, 1);
    expect((await db.select(db.bookmarks).get()).length, 1);
    expect(await db.installedContentVersion(), 7);

    await ensureContentCurrent(db.executor,
        loadAsset: (_) => loaderFor(seed), tempDir: tempDir, bundledVersion: 7);
    expect(loaderCalls, 1, reason: 'second call is a no-op');
    await db.close();
  });

  test('a failing loader keeps the previous content and never throws',
      () async {
    final db = await staleDb();
    await ensureContentCurrent(db.executor,
        loadAsset: (_) => Future<ByteData>.error(StateError('asset missing')),
        tempDir: tempDir,
        bundledVersion: 7);
    expect((await db.select(db.surahs).get()).single.nameAr, 'قديم');
    expect(await db.installedContentVersion(), 0);
    await db.close();
  });

  test('committed asset carries the current content version', () async {
    final copy = File(p.join(tempDir.path, 'asset.sqlite'))
      ..writeAsBytesSync(File('assets/db/quran.sqlite').readAsBytesSync());
    final db = AppDatabase(NativeDatabase(copy));
    expect(await db.installedContentVersion(), kContentVersion);
    await db.close();
  });
}
