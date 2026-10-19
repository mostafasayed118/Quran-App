// Build-time generator: assets/db/quran.sqlite from the legacy JSON + surah metadata.
// Run:  dart run tools/build_quran_db.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/content_version.dart';

Future<void> main() async {
  final repoRoot = Directory.current.path;
  final jsonPath = '$repoRoot\\assets\\json\\hafs_smart_v8.json';
  final dbPath = '$repoRoot\\assets\\db\\quran.sqlite';
  final cachePath = '$repoRoot\\tools\\chapters_cache.json';

  final data =
      jsonDecode(File(jsonPath).readAsStringSync()) as Map<String, dynamic>;
  final ayahList = (data['quran'] as List).cast<Map<String, dynamic>>();
  if (ayahList.length != 6236) {
    stderr.writeln('unexpected ayah count: ${ayahList.length}');
    exitCode = 1;
    return;
  }

  // Surah metadata: quran.com API v4 (id-ordered 114 chapters).
  // Fetched once, cached to tools/chapters_cache.json for deterministic reruns.
  Map<String, dynamic> chapters;
  if (File(cachePath).existsSync()) {
    chapters =
        jsonDecode(File(cachePath).readAsStringSync()) as Map<String, dynamic>;
  } else {
    final res = await http
        .get(Uri.parse('https://api.quran.com/api/v4/chapters?language=ar'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      stderr.writeln('metadata fetch failed: HTTP ${res.statusCode}');
      exitCode = 1;
      return;
    }
    final pretty = const JsonEncoder.withIndent('  ')
        .convert(jsonDecode(res.body) as Map<String, dynamic>);
    File(cachePath).writeAsStringSync(pretty);
    chapters = jsonDecode(pretty) as Map<String, dynamic>;
  }
  final chapterRows =
      (chapters['chapters'] as List).cast<Map<String, dynamic>>();
  if (chapterRows.length != 114) {
    stderr.writeln('unexpected chapter count: ${chapterRows.length}');
    exitCode = 1;
    return;
  }

  final dbFile = File(dbPath);
  if (dbFile.existsSync()) dbFile.deleteSync();
  final db = AppDatabase(NativeDatabase(dbFile));
  await db.createSchemaForSeeding();

  final bySurah = groupBy(
      ayahList, (Map<String, dynamic> a) => (a['sura_no'] as num).toInt());

  await db.batch((b) {
    for (final ch in chapterRows) {
      final surahNo = (ch['id'] as num).toInt();
      final ayahs = bySurah[surahNo]!;
      final pages = ayahs.map((a) => (a['page'] as num).toInt()).toList();
      b.insert(
          db.surahs,
          SurahsCompanion.insert(
            id: Value(surahNo),
            nameAr: ch['name_arabic'] as String,
            nameEn: ch['name_simple'] as String,
            revelationType: ch['revelation_place'] as String,
            ayahCount: (ch['verses_count'] as num).toInt(),
            pagesStart: pages.reduce(min),
            pagesEnd: pages.reduce(max),
          ));
    }
    for (final a in ayahList) {
      b.insert(
          db.ayahs,
          AyahsCompanion.insert(
            id: Value((a['id'] as num).toInt()),
            surahId: (a['sura_no'] as num).toInt(),
            numberInSurah: (a['aya_no'] as num).toInt(),
            juz: (a['jozz'] as num).toInt(),
            page: (a['page'] as num).toInt(),
            lineStart: a['line_start'] == null
                ? const Value.absent()
                : Value((a['line_start'] as num).toInt()),
            lineEnd: a['line_end'] == null
                ? const Value.absent()
                : Value((a['line_end'] as num).toInt()),
            textUthmani: a['aya_text'] as String,
            textImlaei: a['aya_text_emlaey'] as String,
          ));
    }
  });

  await db.into(db.settingsTable).insertOnConflictUpdate(
        SettingsTableCompanion.insert(
          key: kContentVersionKey,
          value: '$kContentVersion',
        ),
      );

  final surahCount = (await db.select(db.surahs).get()).length;
  final ayahCount = (await db.select(db.ayahs).get()).length;
  await db.close();
  stdout.writeln(
      'surahs=$surahCount ayahs=$ayahCount bytes=${dbFile.lengthSync()}');
  if (surahCount != 114 || ayahCount != 6236) {
    stderr.writeln('COUNT MISMATCH — deleting artifact; nothing to commit');
    dbFile.deleteSync();
    exitCode = 1;
  }
}
