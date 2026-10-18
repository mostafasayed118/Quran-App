import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/recitation/presentation/playback/mini_player_bar.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

void main() {
  group('miniPlayerShellShouldRebuild', () {
    PlaybackState playing({
      Duration position = Duration.zero,
      Duration duration = const Duration(minutes: 6),
      String reciterName = 'عبدالباسط عبدالصمد',
      int surahNumber = 1,
    }) =>
        PlaybackState.playing(
          reciterName: reciterName,
          surahNumber: surahNumber,
          position: position,
          duration: duration,
        );

    test('a position-only tick does not rebuild the shell', () {
      expect(
        miniPlayerShellShouldRebuild(
          playing(position: const Duration(seconds: 1)),
          playing(position: const Duration(seconds: 2)),
        ),
        isFalse,
      );
    });

    test('identical states do not rebuild the shell', () {
      expect(miniPlayerShellShouldRebuild(playing(), playing()), isFalse);
      expect(
        miniPlayerShellShouldRebuild(
          const PlaybackState.initial(),
          const PlaybackState.initial(),
        ),
        isFalse,
      );
    });

    test('a track change rebuilds the shell', () {
      expect(
        miniPlayerShellShouldRebuild(playing(), playing(surahNumber: 2)),
        isTrue,
      );
      expect(
        miniPlayerShellShouldRebuild(
          playing(),
          playing(reciterName: 'محمود خليل الحصري'),
        ),
        isTrue,
      );
    });

    test('a status change rebuilds the shell', () {
      expect(
        miniPlayerShellShouldRebuild(
          playing(),
          const PlaybackState.paused(
            reciterName: 'عبدالباسط عبدالصمد',
            surahNumber: 1,
          ),
        ),
        isTrue,
      );
    });

    test('a duration change rebuilds the shell', () {
      expect(
        miniPlayerShellShouldRebuild(
          playing(),
          playing(duration: const Duration(minutes: 7)),
        ),
        isTrue,
      );
    });

    test('a failure-kind change rebuilds; an identical failure does not', () {
      expect(
        miniPlayerShellShouldRebuild(
          const PlaybackState.failed(kind: PlaybackFailureKind.network),
          const PlaybackState.failed(
            kind: PlaybackFailureKind.backgroundUnavailable,
          ),
        ),
        isTrue,
      );
      expect(
        miniPlayerShellShouldRebuild(
          const PlaybackState.failed(kind: PlaybackFailureKind.network),
          const PlaybackState.failed(kind: PlaybackFailureKind.network),
        ),
        isFalse,
      );
    });
  });
}
