import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

void main() {
  const playing = PlaybackState.playing(
    reciterName: 'Reciter',
    surahNumber: 2,
    surahName: 'Al-Baqarah',
    position: Duration(seconds: 30),
    duration: Duration(minutes: 5),
    speed: 1.25,
    repeatMode: PlaybackRepeatMode.one,
    sleepTimer: Duration(minutes: 10),
  );

  test('a pending loading state becomes playing with the supplied controls',
      () {
    const loading = PlaybackState.initial(
      reciterName: 'Reciter',
      surahNumber: 2,
      surahName: 'Al-Baqarah',
    );

    final next = loading.toPlaying(
      duration: const Duration(minutes: 5),
      speedOverride: 1.25,
      repeatModeOverride: PlaybackRepeatMode.one,
      sleepTimerOverride: const Duration(minutes: 10),
    );

    expect(
      next,
      const PlaybackState.playing(
        reciterName: 'Reciter',
        surahNumber: 2,
        surahName: 'Al-Baqarah',
        duration: Duration(minutes: 5),
        speed: 1.25,
        repeatMode: PlaybackRepeatMode.one,
        sleepTimer: Duration(minutes: 10),
      ),
    );
  });

  test('paused becomes playing while preserving position and duration', () {
    const paused = PlaybackState.paused(
      reciterName: 'Reciter',
      surahNumber: 2,
      surahName: 'Al-Baqarah',
      position: Duration(seconds: 30),
      duration: Duration(minutes: 5),
      speed: 1.0,
      sleepTimer: Duration(minutes: 10),
    );

    final next = paused.toPlaying(speedOverride: 1.25);

    expect(
      next,
      const PlaybackState.playing(
        reciterName: 'Reciter',
        surahNumber: 2,
        surahName: 'Al-Baqarah',
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
        speed: 1.25,
        sleepTimer: Duration(minutes: 10),
      ),
    );
  });

  test('playing becomes paused and can clear the sleep timer', () {
    final next = playing.toPaused(clearSleepTimer: true);
    expect(
      next,
      const PlaybackState.paused(
        reciterName: 'Reciter',
        surahNumber: 2,
        surahName: 'Al-Baqarah',
        position: Duration(seconds: 30),
        duration: Duration(minutes: 5),
        speed: 1.25,
        repeatMode: PlaybackRepeatMode.one,
      ),
    );
  });

  test('a paused state can clear its own sleep timer', () {
    const paused = PlaybackState.paused(
      reciterName: 'Reciter',
      surahNumber: 2,
      sleepTimer: Duration(minutes: 10),
    );

    final cleared = paused.toPaused(clearSleepTimer: true) as PlaybackPaused;
    final kept = paused.toPaused() as PlaybackPaused;
    expect(cleared.sleepTimer, isNull);
    expect(kept.sleepTimer, const Duration(minutes: 10));
  });

  test('states that cannot transition are returned unchanged', () {
    const idle = PlaybackState.initial();
    const failed = PlaybackState.failed(kind: PlaybackFailureKind.network);

    expect(identical(idle.toPlaying(), idle), isTrue);
    expect(identical(failed.toPlaying(), failed), isTrue);
    expect(identical(failed.toPaused(), failed), isTrue);
  });
}
