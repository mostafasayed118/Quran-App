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

/// Playback double that also exposes the completion capability.
class _CompletingPlaybackService
    implements PlaybackService, CompletingPlaybackService {
  final _completion = StreamController<void>.broadcast();

  int stopCount = 0;

  @override
  Stream<void> completionStream() => _completion.stream;

  void emitCompletion() => _completion.add(null);

  Future<void> close() => _completion.close();

  @override
  Stream<bool> playingStream() => const Stream<bool>.empty();

  @override
  Stream<Duration> positionStream() => const Stream<Duration>.empty();

  @override
  Stream<Duration?> durationStream() => const Stream<Duration?>.empty();

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async => stopCount += 1;
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_completion_test');
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص عن عاصم - مرتل',
            server: 'PLACEHOLDER',
            surahList: '1,2',
            surahTotal: 114,
          ),
        );
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('a completion event resets the player and stops the track', () async {
    final service = _CompletingPlaybackService();
    final cubit = PlaybackCubit(
      service: service,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
    );
    addTearDown(cubit.close);
    addTearDown(service.close);

    final row = (await ReciterRepository(db).byId('51-53'))!;
    await cubit.playSurah(row, 1);
    expect(cubit.state, isA<PlaybackPlaying>());

    final reset = cubit.stream
        .firstWhere((s) => s is PlaybackInitial)
        .timeout(const Duration(seconds: 10));

    service.emitCompletion();
    await reset;

    expect(service.stopCount, 1);
    expect(cubit.state, isA<PlaybackInitial>());
  });
}
