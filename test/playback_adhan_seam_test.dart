import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/domain/adhan_player.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

import 'support/test_db.dart';

class _Service implements PlaybackService {
  final playing = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();
  final pending = <Completer<void>>[];
  int stopCount = 0;

  @override
  Stream<bool> playingStream() => playing.stream;

  @override
  Stream<Duration> positionStream() => positionCtrl.stream;

  @override
  Stream<Duration?> durationStream() => durationCtrl.stream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) {
    final completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async => stopCount += 1;
}

const _row = ReciterRow(
  id: '51-53',
  reciterName: 'عبدالباسط عبدالصمد',
  moshafName: 'حفص مرتل',
  server: 'https://server.example/mp3',
  surahList: '1,2',
  surahTotal: 114,
);

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late _Service service;
  late StreamController<AdhanPlaybackState> adhan;
  late PlaybackCubit cubit;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_adhan_seam');
    service = _Service();
    adhan = StreamController<AdhanPlaybackState>.broadcast();
    cubit = PlaybackCubit(
      service: service,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => true,
      adhanStates: adhan.stream,
    );
  });

  tearDown(() async {
    await cubit.close();
    await adhan.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  Future<void> startSurah() async {
    final play = cubit.playSurah(_row, 1);
    var spins = 0;
    while (service.pending.isEmpty) {
      if (spins++ > 200) fail('loadAndPlay never started');
      await Future<void>.delayed(Duration.zero);
    }
    service.pending.removeAt(0).complete();
    await play;
    service.playing.add(true);
    await _settle();
    expect(cubit.state, isA<PlaybackPlaying>());
  }

  test('an adhan start clears the surah without touching the shared player',
      () async {
    await startSurah();

    adhan.add(const AdhanPlaybackState(
      status: AdhanPlaybackStatus.playing,
      trackId: 'abdulbasit',
    ));
    await _settle();

    expect(cubit.state, isA<PlaybackInitial>(),
        reason: 'the mini player must not claim the adhan is the surah');
    expect(service.stopCount, 0,
        reason: 'the adhan player already stopped the shared player');

    // The shared player now belongs to the adhan; its events must not revive
    // the surah state.
    service.playing.add(true);
    service.durationCtrl.add(const Duration(minutes: 3));
    service.positionCtrl.add(const Duration(seconds: 5));
    await _settle();
    expect(cubit.state, isA<PlaybackInitial>());

    adhan.add(AdhanPlaybackState.idle);
    await _settle();
    expect(cubit.state, isA<PlaybackInitial>());
  });

  test('a new surah plays normally after the adhan ends', () async {
    await startSurah();
    adhan.add(const AdhanPlaybackState(
      status: AdhanPlaybackStatus.playing,
      trackId: 'abdulbasit',
    ));
    await _settle();
    adhan.add(AdhanPlaybackState.idle);
    await _settle();

    final play = cubit.playSurah(_row, 2);
    var spins = 0;
    while (service.pending.isEmpty) {
      if (spins++ > 200) fail('the second load never started');
      await Future<void>.delayed(Duration.zero);
    }
    service.pending.removeAt(0).complete();
    await play;
    service.playing.add(true);
    await _settle();

    expect(cubit.state, isA<PlaybackPlaying>());
    expect((cubit.state as PlaybackPlaying).surahNumber, 2);
  });
}
