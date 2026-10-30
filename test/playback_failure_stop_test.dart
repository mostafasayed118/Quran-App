import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_info_source.dart';
import 'package:quran_yahdi/features/recitation/domain/reciter_info.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

import 'support/test_db.dart';

class _FakeService implements PlaybackService {
  Object? loadError;
  int stopCount = 0;

  @override
  Stream<bool> playingStream() => const Stream<bool>.empty();

  @override
  Stream<Duration> positionStream() => const Stream<Duration>.empty();

  @override
  Stream<Duration?> durationStream() => const Stream<Duration?>.empty();

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {
    final error = loadError;
    if (error != null) throw error;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async => stopCount++;
}

class _ThrowingReciters implements ReciterInfoSource {
  @override
  Future<ReciterInfo?> defaultReciter() async => throw StateError('catalog');
}

class _OneReciter implements ReciterInfoSource {
  @override
  Future<ReciterInfo?> defaultReciter() async => const ReciterInfo(
        id: '1-1',
        reciterName: 'القارئ',
        moshafName: 'حفص',
        server: 'https://server.example/mp3',
        surahList: '1',
        surahTotal: 114,
      );
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_playback_stop');
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    await db.close();
  });

  PlaybackCubit build(_FakeService service, ReciterInfoSource reciters) =>
      PlaybackCubit(
        service: service,
        reciters: reciters,
        downloader: AudioDownloader(
          db,
          audioRootResolver: () async => tempRoot,
        ),
        backgroundActive: () => true,
      );

  test('a failed default-reciter lookup stops the previous track', () async {
    final service = _FakeService();
    final cubit = build(service, _ThrowingReciters());
    addTearDown(cubit.close);

    await cubit.playDefaultForSurah(1);

    expect(cubit.state, isA<PlaybackFailed>());
    expect(service.stopCount, 1);
  });

  test('a failed load stops the previous track', () async {
    final service = _FakeService()..loadError = StateError('load failed');
    final cubit = build(service, _OneReciter());
    addTearDown(cubit.close);

    await cubit.playDefaultForSurah(1);

    expect(cubit.state, isA<PlaybackFailed>());
    expect(service.stopCount, 1);
  });
}
