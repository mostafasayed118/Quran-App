import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/settings_store.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';

import 'support/test_db.dart';

/// RED for L-4: readAll(keys) and reciter isIn(surahIds) were unbatched, so a
/// >999 collection exceeded SQLite's host-variable limit. The interceptor
/// emulates that limit; before the fix these calls throw "too many SQL
/// variables", after the sqlBatches fix they succeed.
void main() {
  test('readAll stays under the variable ceiling for 1500 keys', () async {
    final db = newLimitedVarDb(limit: 999);
    final store = SettingsStore(db);
    await store.writeAll(<String, String>{'k0': 'v0', 'k1499': 'v1499'});
    final keys = [for (var i = 0; i < 1500; i++) 'k$i'];

    final got = await store.readAll(keys);

    expect(got['k0'], 'v0');
    expect(got['k1499'], 'v1499');
  });

  test('surahNamesFor stays under the variable ceiling for 1500 ids', () async {
    final db = newLimitedVarDb(limit: 999);
    final repo = ReciterRepository(db);
    // We only exercise the unbatched isIn path; no rows needed — the point is
    // the query must not bind >999 variables.
    final ids = [for (var i = 0; i < 1500; i++) i + 1];

    final got = await repo.surahNamesFor(ids);

    expect(got, isEmpty);
  });
}
