// Permanent service-level regression for the feelings backup integration.
// Distinguishes itself from the existing unit tests: it goes through the
// production BackupService.exportJson / apply (not the codec or merger).
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';

AppDatabase _newDb() {
  final db = AppDatabase.test(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}

void main() {
  test('feelings saved verses survive service export → fresh-db apply, dedup '
      'on reapply, and an older file without the field', () async {
    final db = _newDb();
    final service = BackupService(db: db, reschedule: () async {});
    final created = DateTime(2026, 11, 22, 10, 30);
    await db
        .into(db.feelingSavedVerses)
        .insert(
          FeelingSavedVersesCompanion.insert(
            ayahId: 39,
            feeling: 'amal',
            createdAt: Value(created),
          ),
        );

    // 1. Production export carries the field.
    final decoded = decode(await service.exportJson()) as BackupDecodeSuccess;
    expect(decoded.document.data.feelingSavedVerses, hasLength(1));
    final row = decoded.document.data.feelingSavedVerses.single;
    expect(row.ayahId, 39);
    expect(row.feeling, 'amal');

    // 2. Production restore into a fresh in-memory DB, with reference.
    final fresh = _newDb();
    final freshService = BackupService(db: fresh, reschedule: () async {});
    final first = await freshService.apply(decoded.document);
    expect(first.summary.newSavedFeelingVerses, 1);
    final restored = await fresh.select(fresh.feelingSavedVerses).get();
    expect(restored.single.ayahId, 39);
    expect(restored.single.feeling, 'amal');
    expect(
      restored.single.createdAt.millisecondsSinceEpoch,
      created.millisecondsSinceEpoch,
    );

    // 3. Reapplying the same backup must not duplicate the row.
    final second = await freshService.apply(decoded.document);
    expect(second.summary.newSavedFeelingVerses, 0);
    expect(await fresh.select(fresh.feelingSavedVerses).get(), hasLength(1));

    // 4. An older backup missing the new field still applies cleanly.
    final oldRaw =
        '{"app":"$kBackupAppId","format":$kBackupFormat,'
        '"data":{"bookmarks":[],"lastRead":null,"khatma":[],'
        '"prayerLog":[],"tasbih":null,"settings":{}}}';
    final oldDoc = (decode(oldRaw) as BackupDecodeSuccess).document;
    final third = await freshService.apply(oldDoc);
    expect(third.summary.newSavedFeelingVerses, 0);
    expect(await fresh.select(fresh.feelingSavedVerses).get(), hasLength(1));
  });
}
