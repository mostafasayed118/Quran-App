import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_merger.dart';

void main() {
  test('feelings saved verses survive an encode/decode round trip', () {
    final doc = BackupDocument(
      exportedAt: DateTime(2026, 11, 22),
      schemaVersion: 4,
      data: BackupData(
        bookmarks: const [],
        lastReadAyahId: null,
        khatma: const [],
        prayerLog: const [],
        tasbih: null,
        settings: const {},
        feelingSavedVerses: [
          BackupSavedFeelingVerse(
            ayahId: 42,
            feeling: 'qalaq',
            createdAt: DateTime(2026, 11, 22, 10, 30),
          ),
        ],
      ),
    );
    final decoded = decode(encode(doc)) as BackupDecodeSuccess;
    expect(decoded.document.data.feelingSavedVerses, hasLength(1));
    final row = decoded.document.data.feelingSavedVerses.single;
    expect(row.ayahId, 42);
    expect(row.feeling, 'qalaq');
    expect(row.createdAt, DateTime(2026, 11, 22, 10, 30));
  });

  test('an older file without the field decodes as an empty collection', () {
    final raw =
        '{"app":"$kBackupAppId","format":$kBackupFormat,'
        '"data":{"bookmarks":[],"lastRead":null,"khatma":[],'
        '"prayerLog":[],"tasbih":null,"settings":{}}}';
    final decoded = decode(raw) as BackupDecodeSuccess;
    expect(decoded.document.data.feelingSavedVerses, isEmpty);
  });

  test('merge is by ayahId and preserves feeling and createdAt', () {
    final imported = [
      BackupSavedFeelingVerse(
        ayahId: 7,
        feeling: 'amal',
        createdAt: DateTime(2026, 11, 22),
      ),
      BackupSavedFeelingVerse(
        ayahId: 7,
        feeling: 'huzn',
        createdAt: DateTime(2026, 11, 23),
      ),
      BackupSavedFeelingVerse(
        ayahId: 99999,
        feeling: 'qalaq',
        createdAt: DateTime(2026, 11, 22),
      ),
    ];
    final merge = mergeSavedFeelingVerses(
      existingAyahIds: const {},
      imported: imported,
    );
    expect(merge.toInsert, hasLength(1));
    expect(merge.toInsert.single.feeling, 'amal', reason: 'first wins');
    expect(merge.toInsert.single.createdAt, DateTime(2026, 11, 22));
    expect(merge.rejected, 1);

    final skipExisting = mergeSavedFeelingVerses(
      existingAyahIds: const {7},
      imported: imported,
    );
    expect(skipExisting.toInsert, isEmpty);
  });
}
