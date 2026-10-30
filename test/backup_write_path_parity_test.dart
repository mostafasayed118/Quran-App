import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';

/// Counts which write path the service takes: per-row inserts or a batch.
class _PathProbe extends QueryInterceptor {
  int insertCalls = 0;
  int batchCalls = 0;

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    insertCalls++;
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    batchCalls++;
    return super.runBatched(executor, statements);
  }
}

BackupDocument _document() => BackupDocument(
      exportedAt: DateTime(2026, 10, 30),
      schemaVersion: 2,
      data: BackupData(
        bookmarks: [
          for (var i = 1; i <= 3; i++)
            BackupBookmark(ayahId: i, createdAt: DateTime(2026, 1, i)),
        ],
        lastReadAyahId: 4321,
        khatma: [
          BackupKhatmaRow(
            ayahId: 100,
            targetPages: 20,
            updatedAt: DateTime(2026, 3, 1),
          ),
        ],
        prayerLog: [
          BackupPrayerDay(
            day: DateTime(2026, 5, 1),
            fajr: true,
            dhuhr: false,
            asr: false,
            maghrib: false,
            isha: true,
          ),
          BackupPrayerDay(
            day: DateTime(2026, 5, 2),
            fajr: false,
            dhuhr: false,
            asr: false,
            maghrib: true,
            isha: false,
          ),
        ],
        tasbih: const BackupTasbih(count: 33, target: 99),
        settings: const {'azkar_reminder_time': '06:30'},
      ),
    );

AppDatabase _dbWith(_PathProbe probe) {
  final db = AppDatabase.test(NativeDatabase.memory().interceptWith(probe));
  addTearDown(db.close);
  return db;
}

Future<void> _seedKhatma(AppDatabase db, DateTime updatedAt) =>
    db.into(db.khatmaProgress).insert(
          KhatmaProgressCompanion.insert(
            ayahId: 1,
            targetPages: 10,
            updatedAt: Value(updatedAt),
          ),
        );

Future<Map<String, Object?>> _dump(AppDatabase db) async {
  final bookmarks = await db.select(db.bookmarks).get();
  final prayer = await db.select(db.prayerLog).get();
  final settings = await db.select(db.settingsTable).get();
  final khatma = await db.select(db.khatmaProgress).get();
  return {
    'bookmarks': {
      for (final row in bookmarks)
        row.ayahId: row.createdAt.millisecondsSinceEpoch,
    },
    'prayer': {
      for (final row in prayer)
        row.day.millisecondsSinceEpoch: [
          row.fajr,
          row.dhuhr,
          row.asr,
          row.maghrib,
          row.isha,
        ],
    },
    'settings': {for (final row in settings) row.key: row.value},
    'khatma': [
      for (final row in khatma)
        [row.ayahId, row.targetPages, row.updatedAt.millisecondsSinceEpoch],
    ],
  };
}

void main() {
  test('per-row and batch paths persist identical rows (khatma insert)',
      () async {
    final perRowProbe = _PathProbe();
    final batchProbe = _PathProbe();
    final perRowDb = _dbWith(perRowProbe);
    final batchDb = _dbWith(batchProbe);
    final document = _document();

    await BackupService(
      db: perRowDb,
      reschedule: () async {},
      batchThreshold: 1000,
    ).apply(document);
    await BackupService(
      db: batchDb,
      reschedule: () async {},
      batchThreshold: 0,
    ).apply(document);

    expect(perRowProbe.insertCalls, greaterThan(0));
    expect(perRowProbe.batchCalls, 0);
    expect(batchProbe.insertCalls, 0);
    expect(batchProbe.batchCalls, 1);
    expect(await _dump(perRowDb), await _dump(batchDb));

    final khatma = await batchDb.select(batchDb.khatmaProgress).get();
    expect(khatma, hasLength(1));
    expect(khatma.single.ayahId, 100);
    expect(khatma.single.targetPages, 20);
  });

  test('per-row and batch paths persist identical rows (khatma update)',
      () async {
    final perRowProbe = _PathProbe();
    final batchProbe = _PathProbe();
    final perRowDb = _dbWith(perRowProbe);
    final batchDb = _dbWith(batchProbe);
    final older = DateTime(2026, 1, 1);
    await _seedKhatma(perRowDb, older);
    await _seedKhatma(batchDb, older);
    // The seed itself is an insert; only the apply is measured.
    perRowProbe.insertCalls = 0;
    batchProbe.insertCalls = 0;
    final document = _document();

    await BackupService(
      db: perRowDb,
      reschedule: () async {},
      batchThreshold: 1000,
    ).apply(document);
    await BackupService(
      db: batchDb,
      reschedule: () async {},
      batchThreshold: 0,
    ).apply(document);

    expect(perRowProbe.batchCalls, 0);
    expect(batchProbe.batchCalls, 1);
    expect(await _dump(perRowDb), await _dump(batchDb));

    final khatma = await batchDb.select(batchDb.khatmaProgress).get();
    expect(khatma, hasLength(1));
    expect(khatma.single.ayahId, 100);
    expect(khatma.single.targetPages, 20);
  });
}
