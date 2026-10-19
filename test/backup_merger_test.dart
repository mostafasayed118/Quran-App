import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_merger.dart';

BackupBookmark bookmark(int ayahId) =>
    BackupBookmark(ayahId: ayahId, createdAt: DateTime(2026, 1, 1));

BackupKhatmaRow khatma(int targetPages, DateTime updatedAt) => BackupKhatmaRow(
    ayahId: 100, targetPages: targetPages, updatedAt: updatedAt);

BackupPrayerDay day(
  int dom, {
  bool fajr = false,
  bool dhuhr = false,
  bool asr = false,
  bool maghrib = false,
  bool isha = false,
}) =>
    BackupPrayerDay(
      day: DateTime(2026, 5, dom),
      fajr: fajr,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
    );

void main() {
  group('mergeBookmarks', () {
    test('an empty target takes the whole file', () {
      final merge = mergeBookmarks(
        existingAyahIds: const {},
        imported: [bookmark(1), bookmark(2), bookmark(3)],
      );

      expect(merge.newCount, 3);
      expect(merge.toInsert.map((b) => b.ayahId), [1, 2, 3]);
    });

    test('overlap dedupes and keeps existing rows', () {
      final merge = mergeBookmarks(
        existingAyahIds: const {1, 2},
        imported: [bookmark(1), bookmark(2), bookmark(3)],
      );

      expect(merge.newCount, 1);
      expect(merge.toInsert.single.ayahId, 3);
    });

    test('duplicate ids inside the file collapse to the first', () {
      final merge = mergeBookmarks(
        existingAyahIds: const {},
        imported: [bookmark(2), bookmark(2), bookmark(3)],
      );

      expect(merge.newCount, 2);
      expect(merge.toInsert.map((b) => b.ayahId), [2, 3]);
    });
  });

  group('mergeLastRead', () {
    test('a valid import wins over the existing value', () {
      final merge = mergeLastRead(existing: 5, imported: 42);

      expect(merge.changed, isTrue);
      expect(merge.toWrite, 42);
    });

    test('boundaries 1 and 6236 are accepted', () {
      expect(mergeLastRead(existing: 5, imported: 1).toWrite, 1);
      expect(
        mergeLastRead(existing: 5, imported: kBackupMaxAyahId).toWrite,
        kBackupMaxAyahId,
      );
    });

    test('an invalid import (0 / beyond 6236 / absent) is ignored', () {
      expect(mergeLastRead(existing: 5, imported: 0).changed, isFalse);
      expect(mergeLastRead(existing: 5, imported: 6237).changed, isFalse);
      expect(mergeLastRead(existing: 5, imported: null).changed, isFalse);
    });

    test('an identical value reports no change', () {
      final merge = mergeLastRead(existing: 42, imported: 42);

      expect(merge.changed, isFalse);
      expect(merge.toWrite, 42);
    });
  });

  group('mergeKhatma', () {
    test('an empty target takes the imported plan', () {
      final plan = khatma(20, DateTime(2026, 3, 1));
      final merge = mergeKhatma(existing: null, imported: [plan]);

      expect(merge.replaced, isTrue);
      expect(merge.toWrite?.targetPages, 20);
    });

    test('a newer import replaces the existing plan', () {
      final merge = mergeKhatma(
        existing: khatma(10, DateTime(2026, 3, 1)),
        imported: [khatma(20, DateTime(2026, 3, 5))],
      );

      expect(merge.replaced, isTrue);
      expect(merge.toWrite?.targetPages, 20);
    });

    test('older or equal imports are ignored', () {
      expect(
        mergeKhatma(
          existing: khatma(10, DateTime(2026, 3, 5)),
          imported: [khatma(20, DateTime(2026, 3, 1))],
        ).replaced,
        isFalse,
      );
      expect(
        mergeKhatma(
          existing: khatma(10, DateTime(2026, 3, 5)),
          imported: [khatma(20, DateTime(2026, 3, 5))],
        ).replaced,
        isFalse,
      );
    });

    test('the newest of several file rows is the candidate', () {
      final merge = mergeKhatma(
        existing: null,
        imported: [
          khatma(10, DateTime(2026, 3, 1)),
          khatma(30, DateTime(2026, 3, 9)),
          khatma(20, DateTime(2026, 3, 5)),
        ],
      );

      expect(merge.toWrite?.targetPages, 30);
    });
  });

  group('mergePrayerLog', () {
    test('new days are written', () {
      final merge = mergePrayerLog(
        existing: const [],
        imported: [day(1, fajr: true), day(2, isha: true)],
      );

      expect(merge.mergedDays, 2);
    });

    test('overlapping days OR-merge and only flips are fixed', () {
      final merge = mergePrayerLog(
        existing: [day(1, fajr: true)],
        imported: [day(1, fajr: false, isha: true)],
      );

      expect(merge.mergedDays, 1);
      final merged = merge.daysToWrite.single;
      expect(merged.fajr, isTrue);
      expect(merged.isha, isTrue);
    });

    test('a fully covered day writes nothing', () {
      final merge = mergePrayerLog(
        existing: [day(1, fajr: true, isha: true)],
        imported: [day(1, fajr: true)],
      );

      expect(merge.daysToWrite, isEmpty);
    });

    test('duplicate file days merge together', () {
      final merge = mergePrayerLog(
        existing: const [],
        imported: [day(1, fajr: true), day(1, isha: true)],
      );

      expect(merge.mergedDays, 1);
      expect(merge.daysToWrite.single.fajr, isTrue);
      expect(merge.daysToWrite.single.isha, isTrue);
    });

    test('days outside the file are untouched', () {
      final merge = mergePrayerLog(
        existing: [day(9, fajr: true)],
        imported: [day(1, fajr: true)],
      );

      expect(merge.daysToWrite.map((d) => d.day.day), [1]);
    });
  });

  group('mergeTasbih', () {
    test('an empty target takes the imported snapshot', () {
      final merge = mergeTasbih(
        existing: null,
        imported: const BackupTasbih(count: 33, target: 99),
      );

      expect(merge.changed, isTrue);
      expect(merge.toWrite?.count, 33);
      expect(merge.toWrite?.target, 99);
      expect(merge.countDelta, 33);
    });

    test('count takes the max while a valid target follows the import', () {
      final merge = mergeTasbih(
        existing: const BackupTasbih(count: 50, target: 99),
        imported: const BackupTasbih(count: 33, target: 33),
      );

      expect(merge.toWrite?.count, 50);
      expect(merge.toWrite?.target, 33);
      expect(merge.countDelta, 0);
      expect(merge.changed, isTrue);
    });

    test('an invalid imported target (<= 0) keeps the existing target', () {
      final merge = mergeTasbih(
        existing: const BackupTasbih(count: 10, target: 99),
        imported: const BackupTasbih(count: 20, target: 0),
      );

      expect(merge.toWrite?.target, 99);
      expect(merge.toWrite?.count, 20);
      expect(merge.countDelta, 10);
    });

    test('identical values write nothing', () {
      final merge = mergeTasbih(
        existing: const BackupTasbih(count: 33, target: 99),
        imported: const BackupTasbih(count: 33, target: 99),
      );

      expect(merge.changed, isFalse);
      expect(merge.countDelta, 0);
    });

    test('an absent import writes nothing', () {
      final merge = mergeTasbih(
        existing: const BackupTasbih(count: 33, target: 99),
        imported: null,
      );

      expect(merge.changed, isFalse);
    });
  });

  group('mergeSettings', () {
    test('whitelisted keys are applied', () {
      final merge = mergeSettings(
        existing: const {},
        imported: const {
          'azkar_reminder_time': '07:00',
          'selected_city': '{"id":"cairo"}',
        },
      );

      expect(merge.appliedCount, 2);
      expect(merge.toWrite['azkar_reminder_time'], '07:00');
    });

    test('unknown keys in the file are ignored', () {
      final merge = mergeSettings(
        existing: const {},
        imported: const {
          'content_version': '9',
          'last_read_ayah_id': '10',
          'tasbih_state': '{}',
          'selected_moshaf_row': '1',
        },
      );

      expect(merge.toWrite, {'selected_moshaf_row': '1'});
    });

    test('equal values are not rewritten', () {
      final merge = mergeSettings(
        existing: const {'selected_city': '{"id":"cairo"}'},
        imported: const {'selected_city': '{"id":"cairo"}'},
      );

      expect(merge.appliedCount, 0);
    });

    test('an import wins over a different existing value', () {
      final merge = mergeSettings(
        existing: const {'azkar_reminder_enabled': 'false'},
        imported: const {'azkar_reminder_enabled': 'true'},
      );

      expect(merge.toWrite, {'azkar_reminder_enabled': 'true'});
    });
  });
}
