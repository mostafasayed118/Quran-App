/// What the adhan player is doing right now.
enum AdhanPlaybackStatus {
  /// Nothing is playing.
  idle,

  /// The full adhan or a preview is playing.
  playing,

  /// Reserved for the background/notification controls; the v1 player never
  /// emits it, but the UI already renders it as "resume" so adding pause later
  /// is not a breaking change.
  paused,
}

/// A snapshot of the adhan player.
class AdhanPlaybackState {
  /// Creates a snapshot.
  const AdhanPlaybackState({required this.status, this.trackId});

  /// The idle snapshot, used as the initial value and after [AdhanPlayer.stop].
  static const AdhanPlaybackState idle =
      AdhanPlaybackState(status: AdhanPlaybackStatus.idle);

  /// What the player is doing.
  final AdhanPlaybackStatus status;

  /// The track being played, or null when idle.
  final String? trackId;

  /// Whether audio is currently coming out of the device.
  bool get isPlaying => status == AdhanPlaybackStatus.playing;
}

/// Cross-feature seam in front of adhan audio.
///
/// Implemented in the notifications feature so the settings screen never
/// imports another feature's `data/` layer. Implementations must never throw
/// on a missing asset or an uninitialised audio plugin: the spec requires the
/// request to be queued or to fail open with a log, because the boot path
/// deliberately does not wait for the plugin.
abstract interface class AdhanPlayer {
  /// Plays the full adhan for [trackId], stopping any recitation first.
  Future<void> play(String trackId);

  /// Plays the short clip for [trackId] (picker audition).
  ///
  /// A second preview replaces the first rather than mixing with it.
  Future<void> preview(String trackId);

  /// Stops whatever is playing; safe to call when idle.
  Future<void> stop();

  /// Emits on every playback transition.
  Stream<AdhanPlaybackState> get state;
}
