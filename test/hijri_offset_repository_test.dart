import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/hijri/data/hijri_offset_repository.dart';
import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';

import 'support/test_db.dart';

void main() {
  test('the offset defaults to zero and round-trips', () async {
    final db = newTestDb();
    final repo = HijriOffsetRepository(db);

    expect(await repo.loadOffsetDays(), 0);

    await repo.saveOffsetDays(1);
    expect(await HijriOffsetRepository(db).loadOffsetDays(), 1);
  });

  test('malformed and out-of-range values are clamped', () async {
    final db = newTestDb();
    final repo = HijriOffsetRepository(db);

    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: HijriOffsetRepository.key,
            value: 'not-a-number',
          ),
        );
    expect(await repo.loadOffsetDays(), 0);

    await repo.saveOffsetDays(9);
    expect(await repo.loadOffsetDays(), HijriService.maxOffsetDays);

    await repo.saveOffsetDays(-9);
    expect(await repo.loadOffsetDays(), HijriService.minOffsetDays);
  });
}
