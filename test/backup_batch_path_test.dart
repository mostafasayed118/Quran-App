import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';

import 'support/test_db.dart';

/// Counts which write path the service takes: per-row inserts or a batch.
class _PathProbeInterceptor extends QueryInterceptor {
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

/// Applies a truncated batch, then throws — simulating a failure halfway
/// through the batched writes inside the apply transaction.
class _FailingBatchInterceptor extends QueryInterceptor {
  bool fail = false;
  int appliedStatements = 0;

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) async {
    if (!fail) {
      return super.runBatched(executor, statements);
    }
    const applied = 10;
    appliedStatements = applied;
    await executor.runBatched(BatchedStatements(
      statements.statements,
      statements.arguments.take(applied).toList(),
    ));
    throw StateError('injected batch failure');
  }
}

BackupDocument doc({
  List<BackupBookmark> bookmarks = const [],
  int? lastRead,
  List<BackupKhatmaRow> khatma = const [],
  List<BackupPrayerDay> prayerLog = const [],
  BackupTasbih? tasbih,
  Map<String, String> settings = const {},
}) =>
    BackupDocument(
      exportedAt: DateTime(2026, 10, 19),
      schemaVersion: 2,
      data: BackupData(
        bookmarks: bookmarks,
        lastReadAyahId: lastRead,
        khatma: khatma,
        prayerLog: prayerLog,
        tasbih: tasbih,
        settings: settings,
      ),
    );

BackupBookmark bookmark(int ayahId, [DateTime? at]) => BackupBookmark(
    ayahId: ayahId, createdAt: at ?? DateTime(2026, 1, 2, 3, 4, 5));

BackupKhatmaRow khatma(int targetPages, DateTime updatedAt) => BackupKhatmaRow(
    ayahId: 100, targetPages: targetPages, updatedAt: updatedAt);

BackupPrayerDay prayerDay(
  DateTime day, {
  bool fajr = false,
  bool dhuhr = false,
  bool asr = false,
  bool maghrib = false,
  bool isha = false,
}) =>
    BackupPrayerDay(
      day: day,
      fajr: fajr,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
    );

void main() {
  test(
      'a 65-bookmark import (batch path) writes every entity and is '
      'idempotent on replay', () async {
    final db = newTestDb();
    var rescheduleCalls = 0;
    final service = BackupService(
      db: db,
      reschedule: () async {
        rescheduleCalls++;
      },
    );

    final document = doc(
      bookmarks: [
        for (var i = 1; i <= 64; i++) bookmark(i),
        bookmark(65, DateTime(2026, 6, 1, 12)),
      ],
      lastRead: 4321,
      prayerLog: [
        prayerDay(DateTime(2026, 5, 1), fajr: true, isha: true),
        prayerDay(DateTime(2026, 5, 2), maghrib: true),
      ],
      khatma: [khatma(20, DateTime(2026, 3, 1))],
      tasbih: const BackupTasbih(count: 33, target: 99),
      settings: const {
        'azkar_reminder_time': '06:30',
        'selected_moshaf_row': '2',
      },
    );

    Future<String?> setting(String key) async {
      final row = await (db.select(db.settingsTable)
            ..where((s) => s.key.equals(key)))
          .getSingleOrNull();
      return row?.value;
    }

    final outcome = await service.apply(document);

    expect(outcome.summary.newBookmarks, 65);
    expect(outcome.summary.mergedPrayerDays, 2);
    expect(outcome.summary.planReplaced, isTrue);
    expect(outcome.summary.tasbihCountDelta, 33);
    expect(outcome.summary.tasbihChanged, isTrue);
    expect(outcome.summary.lastReadChanged, isTrue);
    expect(outcome.summary.settingsKeysApplied, 2);
    expect(outcome.rescheduled, isTrue);
    expect(rescheduleCalls, 1);

    final bookmarks = await db.select(db.bookmarks).get();
    expect(bookmarks, hasLength(65));
    final sample = bookmarks.singleWhere((row) => row.ayahId == 65);
    expect(sample.createdAt.millisecondsSinceEpoch,
        DateTime(2026, 6, 1, 12).millisecondsSinceEpoch);

    final prayerRows = await db.select(db.prayerLog).get();
    expect(prayerRows, hasLength(2));
    final byDay = <int, PrayerLogData>{
      for (final row in prayerRows) row.day.day: row,
    };
    expect(byDay[1]!.fajr, isTrue);
    expect(byDay[1]!.isha, isTrue);
    expect(byDay[1]!.dhuhr, isFalse);
    expect(byDay[2]!.maghrib, isTrue);
    expect(byDay[2]!.fajr, isFalse);

    expect(await setting('last_read_ayah_id'), '4321');
    expect(jsonDecode((await setting('tasbih_state'))!),
        {'count': 33, 'target': 99});
    expect(await setting('azkar_reminder_time'), '06:30');
    expect(await setting('selected_moshaf_row'), '2');

    final khatmaRows = await db.select(db.khatmaProgress).get();
    expect(khatmaRows, hasLength(1));
    expect(khatmaRows.single.ayahId, 100);
    expect(khatmaRows.single.targetPages, 20);
    expect(khatmaRows.single.updatedAt.millisecondsSinceEpoch,
        DateTime(2026, 3, 1).millisecondsSinceEpoch);

    final replay = await service.apply(document);

    expect(replay.summary.isEmpty, isTrue);
    expect(replay.rescheduled, isFalse);
    expect(rescheduleCalls, 1);
    expect(await db.select(db.bookmarks).get(), hasLength(65));
    expect(await db.select(db.prayerLog).get(), hasLength(2));
    expect(await db.select(db.khatmaProgress).get(), hasLength(1));
    expect(await setting('last_read_ayah_id'), '4321');
    expect(jsonDecode((await setting('tasbih_state'))!),
        {'count': 33, 'target': 99});
    expect(await setting('azkar_reminder_time'), '06:30');
    expect(await setting('selected_moshaf_row'), '2');
  });

  test('a batch write that fails midway rolls the whole import back', () async {
    final interceptor = _FailingBatchInterceptor();
    final db = AppDatabase.test(
      NativeDatabase.memory().interceptWith(interceptor),
    );
    addTearDown(db.close);
    var rescheduleCalls = 0;
    final service = BackupService(
      db: db,
      reschedule: () async {
        rescheduleCalls++;
      },
    );

    await db.customSelect('SELECT 1 AS one').getSingle();
    interceptor.fail = true;

    await expectLater(
      service.apply(doc(
        bookmarks: [
          for (var i = 1; i <= 65; i++) bookmark(i),
        ],
        lastRead: 42,
        prayerLog: [prayerDay(DateTime(2026, 5, 1), fajr: true)],
        khatma: [khatma(20, DateTime(2026, 3, 1))],
        tasbih: const BackupTasbih(count: 10, target: 100),
        settings: const {'selected_moshaf_row': '2'},
      )),
      throwsA(isA<StateError>()),
    );

    expect(interceptor.appliedStatements, 10,
        reason: 'the injected failure happened after partial progress');
    expect(await db.select(db.bookmarks).get(), isEmpty);
    expect(await db.select(db.prayerLog).get(), isEmpty);
    expect(await db.select(db.khatmaProgress).get(), isEmpty);
    expect(await db.select(db.settingsTable).get(), isEmpty);
    expect(rescheduleCalls, 0);
  });

  test(
      '63 writes take the per-row path, 64 take the batch path, and both '
      'persist identical rows', () async {
    final document = doc(
      bookmarks: [
        for (var i = 1; i <= 61; i++) bookmark(i),
      ],
      lastRead: 42,
      prayerLog: [
        prayerDay(DateTime(2026, 5, 1), fajr: true),
        prayerDay(DateTime(2026, 5, 2), maghrib: true),
      ],
    );

    final perRowProbe = _PathProbeInterceptor();
    final perRowDb = AppDatabase.test(
      NativeDatabase.memory().interceptWith(perRowProbe),
    );
    addTearDown(perRowDb.close);
    await perRowDb.into(perRowDb.bookmarks).insert(
          BookmarksCompanion.insert(
            ayahId: 1,
            createdAt: Value(bookmark(1).createdAt),
          ),
        );
    perRowProbe.insertCalls = 0;

    final batchProbe = _PathProbeInterceptor();
    final batchDb = AppDatabase.test(
      NativeDatabase.memory().interceptWith(batchProbe),
    );
    addTearDown(batchDb.close);

    await BackupService(db: perRowDb, reschedule: () async {}).apply(document);
    await BackupService(db: batchDb, reschedule: () async {}).apply(document);

    // 60 new bookmarks + 2 prayer days + lastRead = 63 per-row inserts.
    expect(perRowProbe.insertCalls, 63);
    expect(perRowProbe.batchCalls, 0);
    // 61 new bookmarks + 2 prayer days + lastRead = 64 batched statements.
    expect(batchProbe.insertCalls, 0);
    expect(batchProbe.batchCalls, 1);

    final perRowBookmarks = await perRowDb.select(perRowDb.bookmarks).get();
    final batchBookmarks = await batchDb.select(batchDb.bookmarks).get();
    expect(perRowBookmarks, hasLength(61));
    expect(batchBookmarks, hasLength(61));
    expect(
      {
        for (final row in perRowBookmarks)
          row.ayahId: row.createdAt.millisecondsSinceEpoch,
      },
      {
        for (final row in batchBookmarks)
          row.ayahId: row.createdAt.millisecondsSinceEpoch,
      },
    );

    final perRowPrayer = await perRowDb.select(perRowDb.prayerLog).get();
    final batchPrayer = await batchDb.select(batchDb.prayerLog).get();
    Map<int, List<bool>> prayerShape(List<PrayerLogData> rows) => {
          for (final row in rows)
            row.day.millisecondsSinceEpoch: [
              row.fajr,
              row.dhuhr,
              row.asr,
              row.maghrib,
              row.isha,
            ],
        };
    expect(prayerShape(perRowPrayer), prayerShape(batchPrayer));

    final perRowSettings = await perRowDb.select(perRowDb.settingsTable).get();
    final batchSettings = await batchDb.select(batchDb.settingsTable).get();
    expect(
      {for (final row in perRowSettings) row.key: row.value},
      {for (final row in batchSettings) row.key: row.value},
    );
  });
}
