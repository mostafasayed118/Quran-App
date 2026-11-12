import 'package:freezed_annotation/freezed_annotation.dart';

part 'playback_state.freezed.dart';

enum PlaybackFailureKind { network, noReciters, backgroundUnavailable }

/// What the player does when the current surah ends.
enum PlaybackRepeatMode {
  /// Stop at the end of the current surah (the historical behaviour).
  off,

  /// Replay the current surah.
  one,
}

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
    @Default(1.0) double speed,
    @Default(PlaybackRepeatMode.off) PlaybackRepeatMode repeatMode,
    @Default(null) Duration? sleepTimer,
  }) = PlaybackPlaying;

  const factory PlaybackState.paused({
    required String reciterName,
    required int surahNumber,
    @Default('') String surahName,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(1.0) double speed,
    @Default(PlaybackRepeatMode.off) PlaybackRepeatMode repeatMode,
    @Default(null) Duration? sleepTimer,
  }) = PlaybackPaused;

  const factory PlaybackState.failed({
    required PlaybackFailureKind kind,
  }) = PlaybackFailed;
}

/// Compatibility alias for the frozen suite: the pre-merge name of the
/// "not ready" state (it and the loading state are one state now).
typedef PlaybackInitial = PlaybackLoading;

/// Field-preserving transitions between the play/pause variants.
///
/// Freezed generates `copyWith` per variant, not on the sealed union, so the
/// cubit used to spell out all eight fields at every transition. These helpers
/// are the one place that mapping lives; an added field cannot be forgotten at
/// a call site.
extension PlaybackStateTransitions on PlaybackState {
  /// Converts a loading or paused state to playing.
  ///
  /// A loading state without a pending track (the idle state) is returned
  /// unchanged. The optional overrides are used when the cubit's in-memory
  /// controls are newer than the state's snapshot.
  PlaybackState toPlaying({
    Duration? duration,
    double? speedOverride,
    PlaybackRepeatMode? repeatModeOverride,
    Duration? sleepTimerOverride,
  }) =>
      switch (this) {
        PlaybackLoading(
          :final reciterName,
          :final surahNumber,
          :final surahName
        )
            when reciterName != null =>
          PlaybackState.playing(
            reciterName: reciterName,
            surahNumber: surahNumber,
            surahName: surahName,
            duration: duration ?? Duration.zero,
            speed: speedOverride ?? 1.0,
            repeatMode: repeatModeOverride ?? PlaybackRepeatMode.off,
            sleepTimer: sleepTimerOverride,
          ),
        PlaybackPaused(
          :final reciterName,
          :final surahNumber,
          :final surahName,
          :final position,
          :final duration,
          :final speed,
          :final repeatMode,
          :final sleepTimer,
        ) =>
          PlaybackState.playing(
            reciterName: reciterName,
            surahNumber: surahNumber,
            surahName: surahName,
            position: position,
            duration: duration,
            speed: speedOverride ?? speed,
            repeatMode: repeatModeOverride ?? repeatMode,
            sleepTimer: sleepTimerOverride ?? sleepTimer,
          ),
        _ => this,
      };

  /// Converts a playing state to paused, or clears a paused state's timer.
  ///
  /// [clearSleepTimer] is the sleep-timer-fired case; every other transition
  /// preserves the timer.
  PlaybackState toPaused({bool clearSleepTimer = false}) => switch (this) {
        PlaybackPlaying(
          :final reciterName,
          :final surahNumber,
          :final surahName,
          :final position,
          :final duration,
          :final speed,
          :final repeatMode,
          :final sleepTimer,
        ) =>
          PlaybackState.paused(
            reciterName: reciterName,
            surahNumber: surahNumber,
            surahName: surahName,
            position: position,
            duration: duration,
            speed: speed,
            repeatMode: repeatMode,
            sleepTimer: clearSleepTimer ? null : sleepTimer,
          ),
        PlaybackPaused() when clearSleepTimer =>
          (this as PlaybackPaused).copyWith(sleepTimer: null),
        _ => this,
      };
}
