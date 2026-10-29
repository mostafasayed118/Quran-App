import 'package:freezed_annotation/freezed_annotation.dart';

part 'playback_state.freezed.dart';

enum PlaybackFailureKind { network, noReciters, backgroundUnavailable }

@freezed
sealed class PlaybackState with _$PlaybackState {
  /// The player is NOT ready: nothing was picked yet (the idle state) or a
  /// track is being prepared.
  ///
  /// A null [reciterName] means "no track known" — the mini player shows
  /// nothing then; a pending track carries its reciter and surah.
  const factory PlaybackState.initial({
    String? reciterName,
    @Default(0) int surahNumber,
    @Default('') String surahName,
  }) = PlaybackLoading;

  /// The player is preparing a track.
  ///
  /// The pre-merge factory name, kept as a constructor for the pending
  /// track — the state itself is [PlaybackState.initial] with the track
  /// filled in.
  static PlaybackState loading({
    required String reciterName,
    required int surahNumber,
    String surahName = '',
  }) =>
      PlaybackLoading(
        reciterName: reciterName,
        surahNumber: surahNumber,
        surahName: surahName,
      );

  const factory PlaybackState.playing({
    required String reciterName,
    required int surahNumber,
    @Default('') String surahName,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
  }) = PlaybackPlaying;

  const factory PlaybackState.paused({
    required String reciterName,
    required int surahNumber,
    @Default('') String surahName,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
  }) = PlaybackPaused;

  const factory PlaybackState.failed({
    required PlaybackFailureKind kind,
  }) = PlaybackFailed;
}

/// Compatibility alias for the frozen suite: the pre-merge name of the
/// "not ready" state (it and the loading state are one state now).
typedef PlaybackInitial = PlaybackLoading;
