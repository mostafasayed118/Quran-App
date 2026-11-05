import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

import 'support/test_db.dart';

class _TunableFake
    implements
        PlaybackService,
        TunablePlaybackService,
        CompletingPlaybackService {
  final playing = StreamController<bool>.broadcast();
  final position = StreamController<Duration>.broadcast();
  final duration = StreamController<Duration?>.broadcast();
  final completion = StreamController<void>.broadcast();

  final List<PlaybackSource> loaded = <PlaybackSource>[];
  double speed = 1;
  bool loop = false;
  int pauseCount = 0;
  int stopCount = 0;

  @override
  Stream<bool> playingStream() => playing.stream;

  @override
  Stream<Duration> positionStream() => position.stream;

  @override
  Stream<Duration?> durationStream() => duration.stream;

  @override
  Stream<void> completionStream() => completion.stream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {
    loaded.add(source);
  }

  @override
  Future<void> pause() async => pauseCount += 1;

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async => stopCount += 1;

  @override
  Future<void> setSpeed(double value) async => speed = value;

  @override
  Future<void> setLoopMode(bool value) async => loop = value;

  Future<void> close() async {
    await playing.close();
    await position.close();
    await duration.close();
    await completion.close();
  }
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late _TunableFake service;
  late PlaybackCubit cubit;
  late ReciterRow row;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_player_controls');
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: 'row-1',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص مرتل',
            server: 'https://server.example/mp3',
            surahList: '1,2,113,114',
            surahTotal: 114,
          ),
        );
    row = (await ReciterRepository(db).byId('row-1'))!;
    service = _TunableFake();
    cubit = PlaybackCubit(
      service: service,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
    );
  });

  tearDown(() async {
    await cubit.close();
    await service.close();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('speed is clamped, reaches the service and survives position ticks',
      () async {
    await cubit.playSurah(row, 1);
    await pumpEventQueue();

    await cubit.setSpeed(1.5);
    expect(service.speed, 1.5);
    expect((cubit.state as PlaybackPlaying).speed, 1.5);

    service.position.add(const Duration(seconds: 3));
    await pumpEventQueue();
    expect((cubit.state as PlaybackPlaying).speed, 1.5);

    await cubit.setSpeed(9);
    expect(service.speed, 2);
    expect((cubit.state as PlaybackPlaying).speed, 2);
  });

  test('cycleSpeed moves through the declared ladder', () async {
    await cubit.playSurah(row, 1);
    await pumpEventQueue();

    await cubit.cycleSpeed();
    expect((cubit.state as PlaybackPlaying).speed, 1.25);

    await cubit.cycleSpeed();
    expect((cubit.state as PlaybackPlaying).speed, 1.5);
  });

  test('repeat toggles the loop mode on the service', () async {
    await cubit.playSurah(row, 1);
    await pumpEventQueue();

    await cubit.toggleRepeat();
    expect(service.loop, isTrue);
    expect(
      (cubit.state as PlaybackPlaying).repeatMode,
      PlaybackRepeatMode.one,
    );

    await cubit.toggleRepeat();
    expect(service.loop, isFalse);
    expect(
      (cubit.state as PlaybackPlaying).repeatMode,
      PlaybackRepeatMode.off,
    );
  });

  test('next and previous move inside the surah range', () async {
    await cubit.playSurah(row, 1);
    await pumpEventQueue();
    await cubit.previousSurah();
    expect(service.loaded, hasLength(1));

    await cubit.nextSurah();
    await pumpEventQueue();
    expect(service.loaded, hasLength(2));
    expect((cubit.state as PlaybackPlaying).surahNumber, 2);

    await cubit.playSurah(row, 114);
    await pumpEventQueue();
    final before = service.loaded.length;
    await cubit.nextSurah();
    expect(service.loaded, hasLength(before));
  });

  test('completion stops when repeat is off', () async {
    await cubit.playSurah(row, 1);
    await pumpEventQueue();

    service.completion.add(null);
    await pumpEventQueue();

    expect(service.loaded, hasLength(1));
    expect(service.stopCount, 1);
    expect(cubit.state, isA<PlaybackLoading>());
    expect((cubit.state as PlaybackLoading).reciterName, isNull);
  });

  test('completion repeats the same surah when repeat is on', () async {
    await cubit.playSurah(row, 1);
    await pumpEventQueue();
    await cubit.toggleRepeat();

    service.completion.add(null);
    await pumpEventQueue();

    expect(service.loaded, hasLength(2));
    expect((cubit.state as PlaybackPlaying).surahNumber, 1);
  });

  test('the sleep timer pauses once and clears itself', () async {
    await cubit.playSurah(row, 1);
    await pumpEventQueue();

    await cubit.startSleepTimer(const Duration(milliseconds: 20));
    expect((cubit.state as PlaybackPlaying).sleepTimer,
        const Duration(milliseconds: 20));

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(service.pauseCount, 1);
    final state = cubit.state;
    expect(state, isA<PlaybackPaused>());
    expect((state as PlaybackPaused).sleepTimer, isNull);
  });

  test('cancelling the sleep timer prevents the pause', () async {
    await cubit.playSurah(row, 1);
    await pumpEventQueue();

    await cubit.startSleepTimer(const Duration(milliseconds: 20));
    await cubit.cancelSleepTimer();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(service.pauseCount, 0);
    expect((cubit.state as PlaybackPlaying).sleepTimer, isNull);
  });

  test('stop cancels a pending sleep timer', () async {
    await cubit.playSurah(row, 1);
    await pumpEventQueue();

    await cubit.startSleepTimer(const Duration(milliseconds: 20));
    await cubit.stopAndReset();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(service.pauseCount, 0);
  });
}
