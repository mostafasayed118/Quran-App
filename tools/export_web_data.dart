// Generates web/src/data from assets/db/quran.sqlite (the app's shipped DB).
// Run from repo root:  dart run tools/export_web_data.dart
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:quran_yahdi/core/db/app_database.dart';

Future<void> main() async {
  final root = Directory.current.path;
  // Work on a temp copy: AppDatabase.beforeOpen writes indexes — the shipped asset must stay pristine.
  final tmp = File('${Directory.systemTemp.path}/quran_export_$pid.sqlite')
    ..writeAsBytesSync(File('$root/assets/db/quran.sqlite').readAsBytesSync());
  final db = AppDatabase(NativeDatabase(tmp));
  try {
    final outDir = Directory('$root/web/src/data')..createSync(recursive: true);
    final ayahDir = Directory('${outDir.path}/ayahs')..createSync(recursive: true);

    final surahs = await (db.select(db.surahs)
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
    if (surahs.length != 114) {
      stderr.writeln('expected 114 surahs, got ${surahs.length}');
      exitCode = 1;
      return;
    }

    var total = 0;
    final surahRows = <Map<String, Object?>>[];
    final searchRows = <Map<String, Object?>>[];
    for (final s in surahs) {
      final ayahs = await (db.select(db.ayahs)
            ..where((t) => t.surahId.equals(s.id))
            ..orderBy([(t) => OrderingTerm(expression: t.numberInSurah)]))
          .get();
      if (ayahs.length != s.ayahCount) {
        stderr.writeln('surah ${s.id}: ${ayahs.length} ayahs != ${s.ayahCount}');
        exitCode = 1;
        return;
      }
      total += ayahs.length;
      surahRows.add({
        'id': s.id, 'nameAr': s.nameAr, 'nameEn': s.nameEn,
        'revelationType': s.revelationType, 'ayahCount': s.ayahCount,
        'pagesStart': s.pagesStart, 'pagesEnd': s.pagesEnd,
      });
      for (final a in ayahs) {
        if (a.textImlaei.trim().isNotEmpty) {
          searchRows.add({'s': s.id, 'a': a.numberInSurah, 't': a.textImlaei});
        }
      }
      File('${ayahDir.path}/${s.id}.json').writeAsStringSync(jsonEncode({
        'surah': s.id,
        'ayahs': [
          for (final a in ayahs)
            {'n': a.numberInSurah, 'juz': a.juz, 'page': a.page,
             'u': a.textUthmani, 'i': a.textImlaei, 'sajda': a.sajda},
        ],
      }));
    }
    if (total != 6236) {
      stderr.writeln('expected 6236 ayahs, got $total');
      exitCode = 1;
      return;
    }
    File('${outDir.path}/surahs.json')
        .writeAsStringSync(jsonEncode({'surahs': surahRows}));
    File('${outDir.path}/search-index.json')
        .writeAsStringSync(jsonEncode({'ayahs': searchRows}));
    stdout.writeln('OK: wrote 114 surahs + $total ayahs to web/src/data');
  } finally {
    await db.close();
    tmp.deleteSync();
  }
}
