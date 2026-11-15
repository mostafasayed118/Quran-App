import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_inventory.dart';
import 'package:quran_yahdi/features/backup/data/backup_merger.dart';

Map<String, String> _one(String key, Object value) =>
    <String, String>{key: jsonEncode(value)};

Map<String, Object?> _decodeMap(SettingsMerge merge, String key) =>
    jsonDecode(merge.toWrite[key]!) as Map<String, Object?>;

List<Object?> _decodeList(SettingsMerge merge, String key) =>
    jsonDecode(merge.toWrite[key]!) as List<Object?>;

void main() {
  group('bookmark metadata', () {
    test('existing entries win; imported additions are kept', () {
      final merge = mergeSettings(
        existing: _one(backupKeyBookmarkMeta, {
          '1': {'folder': 'A'},
          '2': {'note': 'old'},
        }),
        imported: _one(backupKeyBookmarkMeta, {
          '2': {'note': 'new'},
          '3': {'folder': 'C'},
        }),
      );

      final merged = _decodeMap(merge, backupKeyBookmarkMeta);
      expect(merged['1'], {'folder': 'A'});
      expect(merged['2'], {'note': 'old'});
      expect(merged['3'], {'folder': 'C'});
    });

    test('a fresh device restores the whole document', () {
      final merge = mergeSettings(
        existing: const <String, String>{},
        imported: _one(backupKeyBookmarkMeta, {
          '2': {'note': 'B'},
        }),
      );

      expect(_decodeMap(merge, backupKeyBookmarkMeta), {
        '2': {'note': 'B'},
      });
    });

    test('an invalid import leaves the existing document untouched', () {
      final merge = mergeSettings(
        existing: _one(backupKeyBookmarkMeta, {
          '1': {'folder': 'A'},
        }),
        imported: <String, String>{backupKeyBookmarkMeta: 'not json'},
      );

      expect(merge.toWrite.containsKey(backupKeyBookmarkMeta), isFalse);
    });
  });

  test('hadith bookmarks union per pack', () {
    final merge = mergeSettings(
      existing: _one(backupKeyHadithBookmarks, {
        'ara-bukhari': [1, 2],
      }),
      imported: _one(backupKeyHadithBookmarks, {
        'ara-bukhari': [2, 3],
        'eng-bukhari': [4],
      }),
    );

    final merged = _decodeMap(merge, backupKeyHadithBookmarks);
    expect((merged['ara-bukhari']! as List).toSet(), {1, 2, 3});
    expect((merged['eng-bukhari']! as List).toSet(), {4});
  });

  test('qada dates union and sort', () {
    final merge = mergeSettings(
      existing: _one(backupKeyQadaMissedFasts, ['2026-01-02', '2026-01-01']),
      imported: _one(backupKeyQadaMissedFasts, ['2026-01-03', '2026-01-01']),
    );

    expect(_decodeList(merge, backupKeyQadaMissedFasts), [
      '2026-01-01',
      '2026-01-02',
      '2026-01-03',
    ]);
  });

  test('azkar favorites union', () {
    final merge = mergeSettings(
      existing: _one(backupKeyAzkarFavorites, ['morning']),
      imported: _one(backupKeyAzkarFavorites, ['evening', 'morning']),
    );

    expect(
      _decodeList(merge, backupKeyAzkarFavorites).toSet(),
      {'morning', 'evening'},
    );
  });

  test('azkar progress is export-only (one day, not date-keyed)', () {
    final existing = _one(backupKeyAzkarProgress, {
      'day': '2026-11-15',
      'counts': {
        'morning': [1, 2],
      },
    });
    final imported = _one(backupKeyAzkarProgress, {
      'day': '2026-11-14',
      'counts': {
        'morning': [0, 0],
        'evening': [3],
      },
    });
    final merge = mergeSettings(existing: existing, imported: imported);

    expect(merge.toWrite.containsKey(backupKeyAzkarProgress), isFalse);
    expect(merge.skippedDocuments, isEmpty);
  });

  test('a fresh device does not import daily azkar progress', () {
    final merge = mergeSettings(
      existing: const <String, String>{},
      imported: _one(backupKeyAzkarProgress, {
        'day': '2026-11-14',
        'counts': {
          'evening': [3],
        },
      }),
    );

    expect(merge.toWrite.containsKey(backupKeyAzkarProgress), isFalse);
  });

  test('an invalid document is reported as skipped', () {
    final merge = mergeSettings(
      existing: _one(backupKeyBookmarkMeta, {
        '1': {'folder': 'A'},
      }),
      imported: <String, String>{backupKeyBookmarkMeta: 'not json'},
    );

    expect(merge.toWrite.containsKey(backupKeyBookmarkMeta), isFalse);
    expect(merge.skippedDocuments, {backupKeyBookmarkMeta});
  });

  test('an invalid document on a fresh device is skipped, not written', () {
    final merge = mergeSettings(
      existing: const <String, String>{},
      imported: <String, String>{backupKeyBookmarkMeta: 'not json'},
    );

    expect(merge.toWrite, isEmpty);
    expect(merge.skippedDocuments, {backupKeyBookmarkMeta});
  });

  test('scalar settings still import-wins', () {
    final merge = mergeSettings(
      existing: const <String, String>{backupKeySelectedCity: 'A'},
      imported: const <String, String>{backupKeySelectedCity: 'B'},
    );

    expect(merge.toWrite[backupKeySelectedCity], 'B');
  });
}
