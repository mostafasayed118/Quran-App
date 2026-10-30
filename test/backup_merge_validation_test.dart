import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_merger.dart';

BackupBookmark _bookmark(int ayahId) =>
    BackupBookmark(ayahId: ayahId, createdAt: DateTime(2026, 1, 1));

BackupKhatmaRow _khatma(int ayahId, int targetPages) => BackupKhatmaRow(
      ayahId: ayahId,
      targetPages: targetPages,
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  test('out-of-range bookmark ids are rejected, not inserted', () {
    final merge = mergeBookmarks(
      existingAyahIds: const {},
      imported: [_bookmark(0), _bookmark(1), _bookmark(6237)],
    );

    expect(merge.toInsert.map((b) => b.ayahId), [1]);
    expect(merge.rejected, 2);
  });

  test('khatma rows with bad ids or non-positive targets are rejected', () {
    final merge = mergeKhatma(
      existing: null,
      imported: [
        _khatma(0, 10),
        _khatma(1, 0),
        _khatma(1, 10),
      ],
    );

    expect(merge.toWrite?.ayahId, 1);
    expect(merge.toWrite?.targetPages, 10);
    expect(merge.rejected, 2);
  });

  test('summary carries the rejected count so the preview can warn', () {
    const summary = BackupSummary(
      newBookmarks: 0,
      mergedPrayerDays: 0,
      planReplaced: false,
      tasbihCountDelta: 0,
      tasbihChanged: false,
      lastReadChanged: false,
      settingsKeysApplied: 0,
      rejectedEntries: 3,
    );

    expect(summary.isEmpty, isFalse);
    expect(summary.rejectedEntries, 3);
  });
}
