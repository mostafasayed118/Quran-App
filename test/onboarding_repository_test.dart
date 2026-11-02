import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/onboarding/data/onboarding_repository.dart';

import 'support/test_db.dart';

void main() {
  test('a fresh install is not onboarded', () async {
    final db = newTestDb();

    expect(await OnboardingRepository(db).isCompleted(), isFalse);
  });

  test('markCompleted persists across a new repository instance', () async {
    final db = newTestDb();
    final repo = OnboardingRepository(db);

    await repo.markCompleted();

    expect(await repo.isCompleted(), isTrue);
    expect(await OnboardingRepository(db).isCompleted(), isTrue);
  });

  test('an unrelated settings row is untouched', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(key: 'unrelated', value: 'keep-me'),
        );

    await OnboardingRepository(db).markCompleted();

    final row = await (db.select(db.settingsTable)
          ..where((s) => s.key.equals('unrelated')))
        .getSingle();
    expect(row.value, 'keep-me');
  });

  test('a malformed flag reads as not completed', () async {
    final db = newTestDb();
    await db.into(db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: OnboardingRepository.completedKey,
            value: 'yes',
          ),
        );

    expect(await OnboardingRepository(db).isCompleted(), isFalse);
  });
}
