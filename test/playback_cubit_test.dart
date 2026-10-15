import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

class FakePlaybackService implements PlaybackService {
  final playing = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();

  final List<PlaybackSource> loaded = <PlaybackSource>[];
  Object? loadError;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;

  @override
  Stream<bool> playingStream() => playing.stream;

  @override
  Stream<Duration> positionStream() => positionCtrl.stream;

  @override
  Stream<Duration?> durationStream() => durationCtrl.stream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {
    final error = loadError;
    if (error != null) throw error;
    loaded.add(source);
  }

  @override
  Future<void> pause() async => pauseCount += 1;

  @override
  Future<void> resume() async => resumeCount += 1;

  @override
  Future<void> stop() async => stopCount += 1;
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late FakePlaybackService service;
  late PlaybackCubit cubit;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    tempRoot = await Directory.systemTemp.createTemp('qy_playback_test');
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  Future<ReciterRow> seedRow({
    required String id,
    required String name,
    String server = 'https://server.example/mp3',
  }) async {
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: id,
            reciterName: name,
            moshafName: 'حفص مرتل',
            server: server,
            surahList: '1,2',
            surahTotal: 114,
          ),
        );
    return (await ReciterRepository(db).byId(id))!;
  }

  Future<String> seedDownload(String rowId, int surah) async {
    final file =
        File('${tempRoot.path}${Platform.pathSeparator}$rowId-$surah.mp3');
    await file.writeAsBytes([1, 2, 3]);
    await db.into(db.downloads).insert(
          DownloadsCompanion.insert(
            reciterId: rowId,
            surahId: surah,
            status: 'done',
            path: file.path,
          ),
        );
    return file.path;
  }

  PlaybackCubit buildCubit(FakePlaybackService fake) => PlaybackCubit(
        service: fake,
        reciters: ReciterRepository(db),
        downloader:
            AudioDownloader(db, audioRootResolver: () async => tempRoot),
      );

  test('playSurah uses the downloaded file when the downloads row is done',
      () async {
    final row = await seedRow(id: '51-53', name: 'عبدالباسط عبدالصمد');
    final seededPath = await seedDownload(row.id, 1);
    service = FakePlaybackService();
    cubit = buildCubit(service);

    await cubit.playSurah(row, 1);

    expect(service.loaded, hasLength(1));
    final source = service.loaded.single;
    expect(source.kind, PlaybackSourceKind.file);
    expect(source.path, seededPath);
  });

  test('playSurah streams the server URL when nothing is downloaded',
      () async {
    final row = await seedRow(
        id: '55-55', name: 'ماهر المعيقلي', server: 'https://s.example/a');
    service = FakePlaybackService();
    cubit = buildCubit(service);

    await cubit.playSurah(row, 2);

    final source = service.loaded.single;
    expect(source.kind, PlaybackSourceKind.url);
    expect(source.uri.toString(), surahAudioUrl(row.server, 2));
  });

  test('service failure lands in Failed(network) and keeps state resettable',
      () async {
    final row = await seedRow(id: '51-53', name: 'عبدالباسط عبدالصمد');
    service = FakePlaybackService()..loadError = StateError('boom');
    cubit = buildCubit(service);

    await cubit.playSurah(row, 1);
    expect(cubit.state, isA<PlaybackFailed>());

    await cubit.stopAndReset();
    expect(cubit.state, isA<PlaybackInitial>());
  });

  test('playDefaultForSurah falls back to the first featured row when no selection exists',
      () async {
    await seedRow(id: '55-55', name: 'ماهر المعيقلي');
    final featured = await seedRow(id: '51-53', name: 'عبدالباسط عبدالصمد');
    service = FakePlaybackService();
    cubit = buildCubit(service);

    await cubit.playDefaultForSurah(3);

    expect(cubit.state, isA<PlaybackPlaying>());
    expect((cubit.state as PlaybackPlaying).reciterName, featured.reciterName);
  });

  test('toggle pauses and resumes', () async {
    final row = await seedRow(id: '51-53', name: 'عبدالباسط عبدالصمد');
    service = FakePlaybackService();
    cubit = buildCubit(service);

    await cubit.playSurah(row, 1);
    expect(cubit.state, isA<PlaybackPlaying>());

    await cubit.toggle();
    expect(service.pauseCount, 1);
    expect(cubit.state, isA<PlaybackPaused>());

    await cubit.toggle();
    expect(service.resumeCount, 1);
    expect(cubit.state, isA<PlaybackPlaying>());
  });
}
