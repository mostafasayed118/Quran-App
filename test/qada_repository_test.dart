import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/ramadan/data/qada_repository.dart';

import 'support/test_db.dart';

void main() {
  test('the missed-fast list defaults to empty and round-trips', () async {
    final db = newTestDb();
    final repo = QadaRepository(db);

    expect(await repo.loadMissed(), isEmpty);

    final dates = [DateTime(2027, 3, 2), DateTime(2027, 3, 1)];
    await repo.saveMissed(dates);

    final loaded = await QadaRepository(db).loadMissed();
    expect(loaded, [DateTime(2027, 3, 1), DateTime(2027, 3, 2)]);
  });

  test('normalize dedupes, drops the time and sorts', () async {
    final normalized = QadaRepository.normalize([
      DateTime(2027, 3, 2, 23, 59),
      DateTime(2027, 3, 1, 5, 1),
      DateTime(2027, 3, 2, 1),
    ]);

    expect(normalized, [DateTime(2027, 3, 1), DateTime(2027, 3, 2)]);
  });

  test('malformed stored JSON degrades to empty', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: QadaRepository.key,
            value: 'not-json',
          ),
        );

    expect(await QadaRepository(db).loadMissed(), isEmpty);

    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: QadaRepository.key,
            value: '["2027-03-01", 4, "bad-date"]',
          ),
        );

    expect(await QadaRepository(db).loadMissed(), [DateTime(2027, 3, 1)]);
  });
}
