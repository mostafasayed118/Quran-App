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

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_playback_contract');
    service = _PendingLoadService();
    cubit = PlaybackCubit(
      service: service,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
    );
  });

  tearDown(() async {
    await cubit.close();
    await service.playingCtrl.close();
    await service.positionCtrl.close();
    await service.durationCtrl.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test(
      'a playing event moves the mini player out of loading before load returns',
      () async {
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
    final row = (await ReciterRepository(db).byId('51-53'))!;

    final pending = cubit.playSurah(row, 1);
    // Wait until the cubit has bound the streams (the DB lookup runs first).
    for (var i = 0; i < 100 && !service.playingCtrl.hasListener; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(service.playingCtrl.hasListener, isTrue);
    expect(cubit.state, isA<PlaybackLoading>());

    service.playingCtrl.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<PlaybackPlaying>());

    service.loadGate.complete();
    await pending;
    expect(cubit.state, isA<PlaybackPlaying>());
  });

  test('a pause before load settles is not undone by the late load', () async {
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
    final row = (await ReciterRepository(db).byId('51-53'))!;

    final pending = cubit.playSurah(row, 1);
    for (var i = 0; i < 100 && !service.playingCtrl.hasListener; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    service.playingCtrl.add(true);
    await Future<void>.delayed(Duration.zero);

    await cubit.toggle(); // pause
    expect(cubit.state, isA<PlaybackPaused>());

    service.loadGate.complete();
    await pending;
    expect(cubit.state, isA<PlaybackPaused>(),
        reason: 'the late load completion must not emit playing after a pause');
  });
}
