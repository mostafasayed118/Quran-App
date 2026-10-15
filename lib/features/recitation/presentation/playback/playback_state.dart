import 'package:freezed_annotation/freezed_annotation.dart';

part 'playback_state.freezed.dart';

enum PlaybackFailureKind { network, noReciters }

@freezed
sealed class PlaybackState with _$PlaybackState {
  const factory PlaybackState.initial() = PlaybackInitial;

  const factory PlaybackState.loading({
    required String reciterName,
    required int surahNumber,
  }) = PlaybackLoading;

  const factory PlaybackState.playing({
    required String reciterName,
    required int surahNumber,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
  }) = PlaybackPlaying;

  const factory PlaybackState.paused({
    required String reciterName,
    required int surahNumber,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
  }) = PlaybackPaused;

  const factory PlaybackState.failed({
    required PlaybackFailureKind kind,
  }) = PlaybackFailed;
}
