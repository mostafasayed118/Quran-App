import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/recitation/presentation/playback/player_sheet.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

PlaybackState _playing({
  Duration position = Duration.zero,
  Duration duration = const Duration(minutes: 3),
  String surahName = 'الفاتحة',
}) =>
    PlaybackState.playing(
      reciterName: 'reciter',
      surahNumber: 1,
      surahName: surahName,
      position: position,
      duration: duration,
    );

PlaybackState _paused({
  Duration position = Duration.zero,
  Duration duration = const Duration(minutes: 3),
}) =>
    PlaybackState.paused(
      reciterName: 'reciter',
      surahNumber: 1,
      surahName: 'الفاتحة',
      position: position,
      duration: duration,
    );

void main() {
  test('a position tick is ignored while the user drags', () {
    expect(
      playerSheetShouldRebuild(
        _playing(position: const Duration(seconds: 1)),
        _playing(position: const Duration(seconds: 2)),
        dragging: true,
      ),
      isFalse,
    );
  });

  test('the same tick rebuilds when nothing is being dragged', () {
    expect(
      playerSheetShouldRebuild(
        _playing(position: const Duration(seconds: 1)),
        _playing(position: const Duration(seconds: 2)),
        dragging: false,
      ),
      isTrue,
    );
  });

  test('a paused position tick is ignored while dragging too', () {
    expect(
      playerSheetShouldRebuild(
        _paused(position: const Duration(seconds: 1)),
        _paused(position: const Duration(seconds: 2)),
        dragging: true,
      ),
      isFalse,
    );
  });

  test('play/pause still rebuilds mid-drag', () {
    expect(
      playerSheetShouldRebuild(
        _playing(position: const Duration(seconds: 5)),
        _paused(position: const Duration(seconds: 5)),
        dragging: true,
      ),
      isTrue,
    );
  });

  test('a track change rebuilds mid-drag', () {
    expect(
      playerSheetShouldRebuild(
        _playing(surahName: 'الفاتحة'),
        _playing(surahName: 'البقرة'),
        dragging: true,
      ),
      isTrue,
    );
  });

  test('a duration arriving mid-drag rebuilds the times', () {
    expect(
      playerSheetShouldRebuild(
        _playing(duration: Duration.zero),
        _playing(duration: const Duration(minutes: 4)),
        dragging: true,
      ),
      isTrue,
    );
  });

  test('a failure always rebuilds', () {
    expect(
      playerSheetShouldRebuild(
        _playing(),
        const PlaybackState.failed(kind: PlaybackFailureKind.network),
        dragging: true,
      ),
      isTrue,
    );
  });
}
