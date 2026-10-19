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

/// A playback service whose [loadAndPlay] hangs until the test releases it,
/// so races around a hung load are driven deterministically.
class _ControlledPlaybackService implements PlaybackService {
  final playing = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();

  final List<Completer<void>> pending = <Completer<void>>[];
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

/// A repository whose selected-moshaf lookup waits on a test-owned gate.
class _GatedSelectRepository extends ReciterRepository {
  _GatedSelectRepository(super.db, this.gate);

  final Completer<void> gate;

  @override
  Future<String?> loadSelectedMoshaf() async {
    await gate.future;
    return null;
  }

  @override
  Stream<List<ReciterRow>> watchAll() => Stream.value(const <ReciterRow>[]);
}

const _row = ReciterRow(
  id: '51-53',
  reciterName: 'عبدالباسط عبدالصمد',
  moshafName: 'حفص مرتل',
  server: 'https://server.example/mp3',
  surahList: '1,2',
  surahTotal: 114,
);

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late _ControlledPlaybackService service;
  late PlaybackCubit cubit;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_races_test');
    service = _ControlledPlaybackService();
    cubit = PlaybackCubit(
      service: service,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => true,
    );
  });

  tearDown(() async {
    await cubit.close();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  Future<void> waitForLoads(int count) async {
    var spins = 0;
    while (service.pending.length < count) {
      if (spins++ > 200) fail('loadAndPlay never started');
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('stop during a hung load discards the late failure', () async {
    final play = cubit.playSurah(_row, 1);
    await waitForLoads(1);

    await cubit.stopAndReset();
    expect(cubit.state, isA<PlaybackInitial>());

    service.pending[0].completeError(StateError('late boom'));
    await play;

    expect(cubit.state, isA<PlaybackInitial>(),
        reason: 'a stopped attempt must not resurrect a failure strip');
    expect(service.stopCount, 1);
  });

  test('stop during a hung load discards the late success', () async {
    final play = cubit.playSurah(_row, 1);
    await waitForLoads(1);

    await cubit.stopAndReset();
    service.pending[0].complete();
    await play;

    expect(cubit.state, isA<PlaybackInitial>(),
        reason: 'a stopped attempt must not resurrect a playing strip');
  });

  test("a newer play discards the previous attempt's late failure", () async {
    final first = cubit.playSurah(_row, 1);
    await waitForLoads(1);
    final second = cubit.playSurah(_row, 2);
    await waitForLoads(2);

    service.pending[0].completeError(StateError('first boom'));
    await first;
    service.pending[1].complete();
    await second;

    expect(cubit.state, isA<PlaybackPlaying>());
    expect((cubit.state as PlaybackPlaying).surahNumber, 2);
  });

  test('stop during the default-reciter lookup discards the attempt', () async {
    final gate = Completer<void>();
    final gatedCubit = PlaybackCubit(
      service: service,
      reciters: _GatedSelectRepository(db, gate),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => true,
    );
    addTearDown(gatedCubit.close);

    final lookup = gatedCubit.playDefaultForSurah(1);
    await gatedCubit.stopAndReset();
    gate.complete();
    await lookup;

    expect(gatedCubit.state, isA<PlaybackInitial>(),
        reason: 'a stopped lookup must not start playback or fail loudly');
    expect(service.pending, isEmpty);
  });

  test('background-inactive load failure is labelled, not called network',
      () async {
    final localCubit = PlaybackCubit(
      service: service,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => false,
    );
    addTearDown(localCubit.close);

    final play = localCubit.playSurah(_row, 1);
    await waitForLoads(1);
    service.pending[0].completeError(StateError('boom'));
    await play;

    expect(localCubit.state, isA<PlaybackFailed>());
    expect((localCubit.state as PlaybackFailed).kind,
        PlaybackFailureKind.backgroundUnavailable);
  });

  test('background-active load failure stays network', () async {
    final play = cubit.playSurah(_row, 1);
    await waitForLoads(1);
    service.pending[0].completeError(StateError('boom'));
    await play;

    expect(cubit.state, isA<PlaybackFailed>());
    expect((cubit.state as PlaybackFailed).kind, PlaybackFailureKind.network);
  });
}
