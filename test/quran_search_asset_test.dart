import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/search_index.dart';

void main() {
  test('the committed Quran asset indexes all 6236 ayahs', () async {
    final dir = Directory.systemTemp.createTempSync('qy_search_asset');
    addTearDown(() => dir.deleteSync(recursive: true));
    final copy = File(p.join(dir.path, 'asset.sqlite'))
      ..writeAsBytesSync(File('assets/db/quran.sqlite').readAsBytesSync());
    final db = AppDatabase(NativeDatabase(copy));
    addTearDown(db.close);

    await ensureQuranSearchIndex(db);

    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM ayah_search')
        .getSingle();
    expect(row.read<int>('c'), 6236);
  });
}
