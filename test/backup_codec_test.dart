import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_codec.dart';

BackupDocument fullDocument() => BackupDocument(
      exportedAt: DateTime(2026, 10, 19, 12, 30, 5),
      schemaVersion: 2,
      data: BackupData(
        bookmarks: [
          BackupBookmark(ayahId: 1, createdAt: DateTime(2026, 1, 2, 3, 4, 5)),
          BackupBookmark(
              ayahId: 6236, createdAt: DateTime(2026, 6, 7, 8, 9, 10)),
        ],
        lastReadAyahId: 42,
        khatma: [
          BackupKhatmaRow(
            ayahId: 100,
            targetPages: 20,
            updatedAt: DateTime(2026, 3, 4, 5, 6, 7),
          ),
        ],
        prayerLog: [
          BackupPrayerDay(
            day: DateTime(2026, 5, 1),
            fajr: true,
            dhuhr: false,
            asr: true,
            maghrib: false,
            isha: true,
          ),
        ],
        tasbih: const BackupTasbih(count: 33, target: 99),
        settings: const {
          'azkar_reminder_time': '06:30',
          'selected_city': '{"id":"cairo"}',
        },
      ),
    );

String wrapper(String dataJson) =>
    '{"app":"$kBackupAppId","format":$kBackupFormat,"data":$dataJson}';

void main() {
  test('roundtrips a full document through encode/decode', () {
    final result = decode(encode(fullDocument()));

    expect(result, isA<BackupDecodeSuccess>());
    final success = result as BackupDecodeSuccess;
    expect(success.skippedEntries, 0);
    final doc = success.document;
    expect(doc.exportedAt, DateTime(2026, 10, 19, 12, 30, 5));
    expect(doc.schemaVersion, 2);
    expect(doc.data.bookmarks, hasLength(2));
    expect(doc.data.bookmarks.first.ayahId, 1);
    expect(doc.data.bookmarks.first.createdAt, DateTime(2026, 1, 2, 3, 4, 5));
    expect(doc.data.bookmarks.last.ayahId, 6236);
    expect(doc.data.lastReadAyahId, 42);
    expect(doc.data.khatma, hasLength(1));
    expect(doc.data.khatma.single.targetPages, 20);
    expect(doc.data.khatma.single.updatedAt, DateTime(2026, 3, 4, 5, 6, 7));
    expect(doc.data.prayerLog, hasLength(1));
    final day = doc.data.prayerLog.single;
    expect(day.day, DateTime(2026, 5, 1));
    expect(day.fajr, isTrue);
    expect(day.dhuhr, isFalse);
    expect(day.isha, isTrue);
    expect(doc.data.tasbih?.count, 33);
    expect(doc.data.tasbih?.target, 99);
    expect(doc.data.settings, {
      'azkar_reminder_time': '06:30',
      'selected_city': '{"id":"cairo"}',
    });
  });

  test('rejects a wrong app id (fail closed)', () {
    final result = decode('{"app":"another_app","format":1,"data":{}}');
    expect(
      (result as BackupDecodeFailure).reason,
      BackupDecodeFailureReason.wrongApp,
    );
  });

  test('rejects a missing app id (fail closed)', () {
    final result = decode('{"format":1,"data":{}}');
    expect(
      (result as BackupDecodeFailure).reason,
      BackupDecodeFailureReason.wrongApp,
    );
  });

  test('rejects a wrong format version (fail closed)', () {
    final result = decode('{"app":"$kBackupAppId","format":2,"data":{}}');
    expect(
      (result as BackupDecodeFailure).reason,
      BackupDecodeFailureReason.wrongFormat,
    );
  });

  test('rejects malformed JSON', () {
    final result = decode('not-json at all');
    expect(
      (result as BackupDecodeFailure).reason,
      BackupDecodeFailureReason.malformed,
    );
  });

  test('rejects a non-object root', () {
    expect(
      (decode('[1,2,3]') as BackupDecodeFailure).reason,
      BackupDecodeFailureReason.malformed,
    );
    expect(
      (decode('"just a string"') as BackupDecodeFailure).reason,
      BackupDecodeFailureReason.malformed,
    );
  });

  test('rejects an over-cap payload before parsing', () {
    // A 2 MB+ run of x's is not JSON at all — getting tooLarge (not malformed)
    // proves the size guard runs before parsing.
    final raw = 'x'.padRight(kBackupMaxBytes + 1, 'x');
    expect(
      (decode(raw) as BackupDecodeFailure).reason,
      BackupDecodeFailureReason.tooLarge,
    );
  });

  test('skips corrupt bookmark entries and counts them', () {
    final result = decode(wrapper(
      '{"bookmarks":[{"ayahId":1,"createdAt":"2026-01-01T00:00:00.000"},'
      '{"ayahId":"x","createdAt":"2026-01-01T00:00:00.000"},'
      '{"ayahId":3}]}',
    ));

    final success = result as BackupDecodeSuccess;
    expect(success.skippedEntries, 2);
    expect(success.document.data.bookmarks, hasLength(1));
    expect(success.document.data.bookmarks.single.ayahId, 1);
  });

  test('skips corrupt prayer-log entries and counts them', () {
    final result = decode(wrapper(
      '{"prayerLog":[{"day":"not-a-date","fajr":true},'
      '{"day":"2026-05-01T00:00:00.000","fajr":true}]}',
    ));

    final success = result as BackupDecodeSuccess;
    expect(success.skippedEntries, 1);
    expect(success.document.data.prayerLog, hasLength(1));
    expect(success.document.data.prayerLog.single.fajr, isTrue);
  });

  test('a corrupt lastRead object is skipped', () {
    final success =
        decode(wrapper('{"lastRead":{"ayahId":"x"}}')) as BackupDecodeSuccess;
    expect(success.skippedEntries, 1);
    expect(success.document.data.lastReadAyahId, isNull);
  });

  test('a corrupt tasbih object is skipped', () {
    final success = decode(wrapper('{"tasbih":{"count":"x","target":5}}'))
        as BackupDecodeSuccess;
    expect(success.skippedEntries, 1);
    expect(success.document.data.tasbih, isNull);
  });

  test('ignores unknown keys at wrapper and data level', () {
    final success = decode(
      '{"app":"$kBackupAppId","format":$kBackupFormat,"extra":7,'
      '"data":{"bookmarks":[],"futureEntity":[1,2]}}',
    ) as BackupDecodeSuccess;

    expect(success.skippedEntries, 0);
    expect(success.document.data.bookmarks, isEmpty);
  });

  test('skips non-string settings values and counts them', () {
    final success = decode(wrapper(
      '{"settings":{"selected_city":"{\\"id\\":\\"x\\"}","bad":5}}',
    )) as BackupDecodeSuccess;

    expect(success.skippedEntries, 1);
    expect(success.document.data.settings, {
      'selected_city': '{"id":"x"}',
    });
  });

  test('a missing data block decodes to an empty document', () {
    final success = decode('{"app":"$kBackupAppId","format":$kBackupFormat}')
        as BackupDecodeSuccess;

    expect(success.skippedEntries, 0);
    final data = success.document.data;
    expect(data.bookmarks, isEmpty);
    expect(data.lastReadAyahId, isNull);
    expect(data.khatma, isEmpty);
    expect(data.prayerLog, isEmpty);
    expect(data.tasbih, isNull);
    expect(data.settings, isEmpty);
  });

  test('missing metadata degrades leniently', () {
    final success = decode('{"app":"$kBackupAppId","format":$kBackupFormat}')
        as BackupDecodeSuccess;

    expect(success.skippedEntries, 0);
    expect(success.document.schemaVersion, 0);
    expect(success.document.exportedAt.millisecondsSinceEpoch, 0);
  });
}
