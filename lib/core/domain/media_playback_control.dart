import 'dart:async';

/// The app's single audio bridge for the adhan.
///
/// It exists as one interface on the recitation player because
/// `just_audio_background` allows exactly **one** `AudioPlayer` per process
/// (`just_audio_background` throws `PlatformException("… supports only a
/// single player instance")` on a second `init`). A separate adhan player
/// would therefore silently fail the moment the user had ever played a surah
/// — and would break recitation if the adhan initialised first.
///
/// Kept separate from `PlaybackService` so the dozen hand-rolled
/// `PlaybackService` test fakes stay untouched.
abstract interface class MediaPlaybackControl {
  /// Stops whatever is playing so the adhan is never mixed with it. Also used
  /// to silence a running adhan or preview.
  Future<void> stopForAdhan();

  /// Loads [assetPath] into the shared player and starts it. Returns once
  /// playback has started, not when it ends.
  Future<void> playAdhan(
    String assetPath, {
    required String id,
    required String title,
  });

  /// Fires once each time playback reaches its natural end.
  Stream<void> get adhanCompleted;
}
