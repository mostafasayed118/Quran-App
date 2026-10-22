import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_cubit.dart';

void main() {
  test('the worker-isolate decode path completes and decodes', () async {
    final raw = encode(BackupDocument(
      exportedAt: DateTime.utc(2026, 10, 22),
      schemaVersion: 2,
      data: const BackupData(
        bookmarks: [],
        lastReadAyahId: null,
        khatma: [],
        prayerLog: [],
        tasbih: null,
        settings: {'selected_city': '{"id":"cairo"}'},
      ),
    ));
    final result = await BackupCubit.decodeInIsolate(
      Uint8List.fromList(utf8.encode(raw)),
    );

    expect(result, isA<BackupDecodeSuccess>());
    final success = result as BackupDecodeSuccess;
    expect(success.document.data.settings['selected_city'], '{"id":"cairo"}');
  });
}
