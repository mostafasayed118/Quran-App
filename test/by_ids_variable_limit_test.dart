import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';

import 'support/test_db.dart';

/// RED for the byIds IN-variable risk (audit Task B).
///
/// byIds builds one isIn(...) variable per id, unbounded. With >999 ids the
/// statement fails on Android's SQLite. The interceptor emulates that ceiling.
void main() {
  test('byIds with 1500 ids stays under the variable ceiling and merges',
      () async {
    final db = newLimitedVarDb(limit: 999);
    await db.into(db.reciters).insert(RecitersCompanion.insert(
          id: 'r-1',
          reciterName: 'عبدالباسط',
          moshafName: 'حفص مرتل',
          server: 'https://server.example/mp3',
          surahList: '1',
          surahTotal: 114,
        ));
    await db.into(db.reciters).insert(RecitersCompanion.insert(
          id: 'r-1500',
          reciterName: 'ناصر القطامي',
          moshafName: 'حفص مرتل',
          server: 'https://server.example/mp3',
          surahList: '1',
          surahTotal: 114,
        ));
    final repo = ReciterRepository(db);
    final ids = <String>{
      'r-1',
      'r-1500',
      for (var i = 0; i < 1500; i++) 'missing-$i',
    };

    final found = await repo.byIds(ids);

    expect(found.keys.toSet(), {'r-1', 'r-1500'});
  });
}
