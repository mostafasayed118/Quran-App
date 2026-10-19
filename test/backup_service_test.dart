import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';

import 'support/test_db.dart';

class _FailingInsertInterceptor extends QueryInterceptor {
  int count = 0;
  int? failAtInsert;

  void reset() {
    count = 0;
    failAtInsert = null;
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    count++;
    if (count == failAtInsert) {
      throw StateError('injected insert failure');
    }
    return super.runInsert(executor, statement, args);
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
  late AppDatabase db;
  late int rescheduleCalls;
  late BackupService service;

  setUp(() {
    db = newTestDb();
    rescheduleCalls = 0;
    service = BackupService(
      db: db,
      reschedule: () async {
        rescheduleCalls++;
      },
    );
  });

  Future<String?> settingValue(String key) async {
    final row = await (db.select(db.settingsTable)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) =>
      db.into(db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(key: key, value: value),
          );

  test('export → fresh db → apply reproduces the full state', () async {
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(
        ayahId: 1, createdAt: Value(DateTime(2026, 1, 2, 3, 4, 5))));
    await db.into(db.bookmarks).insert(BookmarksCompanion.insert(
        ayahId: 6236, createdAt: const Value.absent()));
    await db.into(db.khatmaProgress).insert(KhatmaProgressCompanion.insert(
          ayahId: 100,
          targetPages: 20,
          updatedAt: Value(DateTime(2026, 3, 4)),
        ));
    await db
        .into(db.prayerLog)
        .insertOnConflictUpdate(PrayerLogCompanion.insert(
          day: DateTime(2026, 5, 1),
          fajr: const Value(true),
          isha: const Value(true),
        ));
    await writeSetting('last_read_ayah_id', '42');
    await writeSetting('tasbih_state', jsonEncode({'count': 33, 'target': 99}));
    await writeSetting('selected_city', '{"id":"cairo"}');
    await writeSetting('azkar_reminder_enabled', 'true');
    await writeSetting('content_version', '1');

    final json = await service.exportJson();
    final result = decode(json);
    expect(result, isA<BackupDecodeSuccess>());
    final success = result as BackupDecodeSuccess;
    expect(success.skippedEntries, 0);
    expect(success.document.schemaVersion, 2);

    final fresh = newTestDb();
    final freshService = BackupService(
      db: fresh,
      reschedule: () async {
        rescheduleCalls++;
      },
    );
    await freshService.apply(success.document);

    final bookmarks = await fresh.select(fresh.bookmarks).get();
    expect(bookmarks.map((b) => b.ayahId), [1, 6236]);
    expect(bookmarks.first.createdAt.millisecondsSinceEpoch,
        DateTime(2026, 1, 2, 3, 4, 5).millisecondsSinceEpoch);

    final khatmaRow = await fresh.select(fresh.khatmaProgress).getSingle();
    expect(khatmaRow.ayahId, 100);
    expect(khatmaRow.targetPages, 20);
    expect(khatmaRow.updatedAt.millisecondsSinceEpoch,
        DateTime(2026, 3, 4).millisecondsSinceEpoch);

    final prayerRows = await fresh.select(fresh.prayerLog).get();
    expect(prayerRows, hasLength(1));
    expect(prayerRows.single.day.millisecondsSinceEpoch,
        DateTime(2026, 5, 1).millisecondsSinceEpoch);
    expect(prayerRows.single.fajr, isTrue);
    expect(prayerRows.single.isha, isTrue);

    Future<String?> freshSetting(String key) async {
      final row = await (fresh.select(fresh.settingsTable)
            ..where((s) => s.key.equals(key)))
          .getSingleOrNull();
      return row?.value;
    }

    expect(await freshSetting('last_read_ayah_id'), '42');
    expect(jsonDecode((await freshSetting('tasbih_state'))!),
        {'count': 33, 'target': 99});
    expect(await freshSetting('selected_city'), '{"id":"cairo"}');
    expect(await freshSetting('azkar_reminder_enabled'), 'true');
    expect(await freshSetting('content_version'), isNull);
  });

  test('export carries typed entities plus only whitelisted settings',
      () async {
    await writeSetting('last_read_ayah_id', '5');
    await writeSetting('tasbih_state', jsonEncode({'count': 33, 'target': 99}));
    await writeSetting('selected_city', '{"id":"cairo"}');
    await writeSetting('azkar_reminder_time', '06:30');
    await writeSetting('content_version', '1');

    final success = decode(await service.exportJson()) as BackupDecodeSuccess;

    expect(success.document.data.lastReadAyahId, 5);
    expect(success.document.data.tasbih?.count, 33);
    expect(
      success.document.data.settings.keys.toSet(),
      {'selected_city', 'azkar_reminder_time'},
    );
  });

  test('bookmarks union on a nonempty target counts only the additions',
      () async {
    await db.into(db.bookmarks).insert(
        BookmarksCompanion.insert(ayahId: 1, createdAt: const Value.absent()));

    final outcome =
        await service.apply(doc(bookmarks: [bookmark(1), bookmark(2)]));

    final rows = await db.select(db.bookmarks).get();
    expect(rows.map((b) => b.ayahId).toList()..sort(), [1, 2]);
    expect(rows, hasLength(2));
    expect(outcome.summary.newBookmarks, 1);
    expect(outcome.rescheduled, isFalse);
  });

  test('prayer-log OR-merge flips marks and adds new days', () async {
    await db
        .into(db.prayerLog)
        .insertOnConflictUpdate(PrayerLogCompanion.insert(
          day: DateTime(2026, 5, 1),
          fajr: const Value(true),
        ));

    final outcome = await service.apply(doc(prayerLog: [
      prayerDay(DateTime(2026, 5, 1), isha: true),
      prayerDay(DateTime(2026, 5, 2), maghrib: true),
    ]));

    expect(outcome.summary.mergedPrayerDays, 2);
    final rows = await db.select(db.prayerLog).get();
    final byDom = <int, PrayerLogData>{for (final r in rows) r.day.day: r};
    expect(byDom[1]!.fajr, isTrue);
    expect(byDom[1]!.isha, isTrue);
    expect(byDom[2]!.maghrib, isTrue);
  });

  test('non-reminder changes never reschedule', () async {
    await writeSetting('azkar_reminder_time', '06:30');

    await service.apply(doc(bookmarks: [bookmark(1)]));
    expect(rescheduleCalls, 0);

    await service.apply(doc(settings: {'selected_moshaf_row': '2'}));
    expect(rescheduleCalls, 0);

    // Equal value → no write → no reschedule.
    await service.apply(doc(settings: {'azkar_reminder_time': '06:30'}));
    expect(rescheduleCalls, 0);
  });

  test('reminder-relevant changes reschedule once per applying commit',
      () async {
    final first =
        await service.apply(doc(settings: {'azkar_reminder_time': '07:00'}));
    expect(first.rescheduled, isTrue);
    expect(rescheduleCalls, 1);
    expect(await settingValue('azkar_reminder_time'), '07:00');

    final second =
        await service.apply(doc(settings: {'selected_city': '{"id":"x"}'}));
    expect(second.rescheduled, isTrue);
    expect(rescheduleCalls, 2);
    expect(await settingValue('selected_city'), '{"id":"x"}');
  });

  test('a mid-transaction failure rolls back every write', () async {
    final interceptor = _FailingInsertInterceptor();
    final failing =
        AppDatabase.test(NativeDatabase.memory().interceptWith(interceptor));
    addTearDown(failing.close);
    await failing.customSelect('SELECT 1 AS one').getSingle();
    final failingService = BackupService(
      db: failing,
      reschedule: () async {
        rescheduleCalls++;
      },
    );

    interceptor.reset();
    interceptor.failAtInsert = 3;

    await expectLater(
      failingService.apply(doc(
        bookmarks: [bookmark(1), bookmark(2), bookmark(3)],
        settings: {'azkar_reminder_time': '07:00'},
      )),
      throwsA(isA<StateError>()),
    );

    final attempted = interceptor.count;
    expect(attempted, 3,
        reason: 'two inserts landed, the third was the injected failure');
    interceptor.reset();

    final rows = await failing.select(failing.bookmarks).get();
    expect(rows, isEmpty, reason: 'the two committed inserts rolled back');
    final settingRows = await failing.select(failing.settingsTable).get();
    expect(settingRows, isEmpty);
    expect(rescheduleCalls, 0);
  });

  test('preview reports counts without writing anything', () async {
    await db.into(db.bookmarks).insert(
        BookmarksCompanion.insert(ayahId: 1, createdAt: const Value.absent()));
    await db
        .into(db.prayerLog)
        .insertOnConflictUpdate(PrayerLogCompanion.insert(
          day: DateTime(2026, 5, 1),
          fajr: const Value(true),
        ));

    final summary = await service.preview(doc(
      bookmarks: [bookmark(1), bookmark(2), bookmark(3)],
      prayerLog: [
        prayerDay(DateTime(2026, 5, 1), isha: true),
        prayerDay(DateTime(2026, 5, 2), fajr: true),
      ],
      lastRead: 42,
      khatma: [khatma(20, DateTime(2026, 3, 1))],
      tasbih: const BackupTasbih(count: 10, target: 50),
      settings: const {'selected_moshaf_row': '2', 'nonsense_key': 'x'},
    ));

    expect(summary.newBookmarks, 2);
    expect(summary.mergedPrayerDays, 2);
    expect(summary.planReplaced, isTrue);
    expect(summary.tasbihCountDelta, 10);
    expect(summary.tasbihChanged, isTrue);
    expect(summary.lastReadChanged, isTrue);
    expect(summary.settingsKeysApplied, 1);

    expect(await db.select(db.bookmarks).get(), hasLength(1));
    expect(await db.select(db.prayerLog).get(), hasLength(1));
    expect(await db.select(db.khatmaProgress).getSingleOrNull(), isNull);
    expect(await settingValue('last_read_ayah_id'), isNull);
    expect(await settingValue('tasbih_state'), isNull);
    expect(await settingValue('selected_moshaf_row'), isNull);
  });

  test('khatma: a newer imported plan replaces; an older one leaves the row',
      () async {
    await db.into(db.khatmaProgress).insert(KhatmaProgressCompanion.insert(
          ayahId: 5,
          targetPages: 10,
          updatedAt: Value(DateTime(2026, 1, 1)),
        ));

    final replaced =
        await service.apply(doc(khatma: [khatma(20, DateTime(2026, 3, 1))]));
    expect(replaced.summary.planReplaced, isTrue);
    var row = await db.select(db.khatmaProgress).getSingle();
    expect(row.ayahId, 100);
    expect(row.targetPages, 20);

    final ignored =
        await service.apply(doc(khatma: [khatma(30, DateTime(2020, 1, 1))]));
    expect(ignored.summary.planReplaced, isFalse);
    row = await db.select(db.khatmaProgress).getSingle();
    expect(row.targetPages, 20);
  });

  test('lastRead: an out-of-range import is ignored; a valid one wins',
      () async {
    final ignored = await service.apply(doc(lastRead: 9999));
    expect(ignored.summary.lastReadChanged, isFalse);
    expect(await settingValue('last_read_ayah_id'), isNull);

    final written = await service.apply(doc(lastRead: 555));
    expect(written.summary.lastReadChanged, isTrue);
    expect(await settingValue('last_read_ayah_id'), '555');
  });
}
