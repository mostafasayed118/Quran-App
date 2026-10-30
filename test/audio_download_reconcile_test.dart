import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/download_status.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory root;

  setUp(() async {
    db = newTestDb();
    root = await Directory.systemTemp.createTemp('qy_audio_reconcile');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
    await db.close();
  });

  test('a complete file is promoted and a missing file becomes retryable',
      () async {
    final audioDir = Directory('${root.path}/audio/1-1')
      ..createSync(recursive: true);
    final complete = File('${audioDir.path}/001.mp3')
      ..writeAsBytesSync(List<int>.filled(64, 1));
    final missingPath = '${audioDir.path}/002.mp3';
    File('$missingPath.part').writeAsBytesSync(List<int>.filled(16, 1));

    await db.into(db.downloads).insert(DownloadsCompanion.insert(
          reciterId: '1-1',
          surahId: 1,
          status: DownloadStatus.downloading.name,
          path: complete.path,
        ));
    await db.into(db.downloads).insert(DownloadsCompanion.insert(
          reciterId: '1-1',
          surahId: 2,
          status: DownloadStatus.queued.name,
          path: missingPath,
        ));

    await AudioDownloader(db, audioRootResolver: () async => root)
        .reconcileOnStart();

    final rows = await db.select(db.downloads).get();
    final first = rows.firstWhere((r) => r.surahId == 1);
    final second = rows.firstWhere((r) => r.surahId == 2);
    expect(first.status, DownloadStatus.done.name);
    expect(first.bytes, 64);
    expect(second.status, DownloadStatus.failed.name);
    expect(File('$missingPath.part').existsSync(), isFalse);
  });

  test('orphan dot-part files with no row are removed', () async {
    final orphanDir = Directory('${root.path}/audio/9-9')
      ..createSync(recursive: true);
    final orphan = File('${orphanDir.path}/114.mp3.part')
      ..writeAsBytesSync(const [1, 2, 3]);

    await AudioDownloader(db, audioRootResolver: () async => root)
        .reconcileOnStart();

    expect(orphan.existsSync(), isFalse);
  });
}
