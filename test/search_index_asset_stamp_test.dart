import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/db/content_version.dart';
import 'package:quran_yahdi/core/db/search_index.dart';

void main() {
  test('the shipped asset already carries a current search index', () async {
    final dir = Directory.systemTemp.createTempSync('qy_search_stamp');
    addTearDown(() => dir.deleteSync(recursive: true));
    final copy = File(p.join(dir.path, 'asset.sqlite'))
      ..writeAsBytesSync(File('assets/db/quran.sqlite').readAsBytesSync());
    final db = AppDatabase(NativeDatabase(copy));
    addTearDown(db.close);

    await ensureQuranSearchIndex(
      db,
      run: <R>(_) => throw StateError('must not rebuild'),
    );

    final count = await db
        .customSelect('SELECT COUNT(*) AS c FROM ayah_search')
        .getSingle();
    expect(count.read<int>('c'), 6236);
    final stamp = await db.customSelect(
      'SELECT value FROM settings_table WHERE key = ?',
      variables: [const Variable(kSearchIndexVersionKey)],
    ).getSingle();
    expect(stamp.read<String>('value'), '$kContentVersion');
  });
}
