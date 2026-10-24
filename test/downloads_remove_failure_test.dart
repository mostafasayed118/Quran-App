import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';

import 'support/test_db.dart';

class _ThrowingRemoveDownloader extends AudioDownloader {
  _ThrowingRemoveDownloader(super.db);

  @override
  Future<void> removeDownload(String rowId, int surahNumber) =>
      Future.error(StateError('remove failed'));
}

void main() {
  test('a throwing removeDownload returns false and keeps the entry', () async {
    final db = newTestDb();
    await db.into(db.downloads).insert(
          DownloadsCompanion.insert(
            reciterId: '51-53',
            surahId: 1,
            status: 'done',
            path: 'missing.mp3',
          ),
        );
    final cubit = DownloadsCubit(
      downloader: _ThrowingRemoveDownloader(db),
      reciters: ReciterRepository(db),
    );
    addTearDown(cubit.close);
    await cubit.refreshDone();
    expect(cubit.state.items.containsKey('51-53-1'), isTrue);

    final removed =
        await cubit.removeDone('51-53', 1).timeout(const Duration(seconds: 10));

    expect(removed, isFalse);
    expect(cubit.state.items.containsKey('51-53-1'), isTrue,
        reason: 'a failed delete must leave the row visible for a retry');
  });
}
