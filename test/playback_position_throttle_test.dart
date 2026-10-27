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

/// Models the production service: `loadAndPlay` stays pending until the
/// platform reports the load is done; a `playing` event arrives first.
class _PendingLoadService implements PlaybackService {
  final playingCtrl = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();
  final loadGate = Completer<void>();

  @override
  Stream<bool> playingStream() => playingCtrl.stream;

  @override
  Stream<Duration> positionStream() => positionCtrl.stream;

  @override
  Stream<Duration?> durationStream() => durationCtrl.stream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) => loadGate.future;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late _PendingLoadService service;
  late PlaybackCubit cubit;
  late ReciterRow row;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_playback_throttle');
    service = _PendingLoadService();
    cubit = PlaybackCubit(
      service: service,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
    );
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص مرتل',
            server: 'https://server.example/mp3',
            surahList: '1',
            surahTotal: 114,
          ),
        );
    row = (await ReciterRepository(db).byId('51-53'))!;
  });

  tearDown(() async {
    await cubit.close();
    await service.playingCtrl.close();
    await service.positionCtrl.close();
    await service.durationCtrl.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  Future<void> waitForBinding() async {
    for (var i = 0; i < 100 && !service.playingCtrl.hasListener; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(service.playingCtrl.hasListener, isTrue);
  }

  test('a new track does not inherit the previous track duration', () async {
    final first = cubit.playSurah(row, 1);
    await waitForBinding();

    service.durationCtrl.add(const Duration(minutes: 3));
    await Future<void>.delayed(Duration.zero);
    service.playingCtrl.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(
        (cubit.state as PlaybackPlaying).duration, const Duration(minutes: 3));

    service.loadGate.complete();
    await first;
    expect(cubit.state, isA<PlaybackPlaying>());

    await cubit.stopAndReset();
    expect(cubit.state, isA<PlaybackInitial>());

    final second = cubit.playSurah(row, 2);
    await second;
    expect(cubit.state, isA<PlaybackPlaying>());
    expect((cubit.state as PlaybackPlaying).duration, Duration.zero,
        reason: 'a new track must not seed the previous track duration');

    service.durationCtrl.add(const Duration(minutes: 5));
    await Future<void>.delayed(Duration.zero);
    expect(
        (cubit.state as PlaybackPlaying).duration, const Duration(minutes: 5));
  });

  test('sub-second position ticks do not rebuild the progress row', () async {
    final pending = cubit.playSurah(row, 1);
    await waitForBinding();
    service.playingCtrl.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<PlaybackPlaying>());

    service.positionCtrl.add(const Duration(milliseconds: 200));
    service.positionCtrl.add(const Duration(milliseconds: 400));
    service.positionCtrl.add(const Duration(milliseconds: 800));
    await Future<void>.delayed(Duration.zero);

    expect((cubit.state as PlaybackPlaying).position, Duration.zero);

    service.positionCtrl.add(const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);
    expect(
        (cubit.state as PlaybackPlaying).position, const Duration(seconds: 1));

    service.loadGate.complete();
    await pending;
  });
}
