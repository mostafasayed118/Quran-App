/// Pure-Dart guard around the `just_audio_background` bootstrap.
///
/// Package failure modes (verified in the pub cache against
/// just_audio_background 0.0.1-beta.17 + audio_service 0.18.19):
/// - `JustAudioBackground.init` first swaps `JustAudioPlatform.instance` to
///   its own in-process implementation and then awaits `AudioService.init`;
///   when the platform setup is missing or unavailable, that init call can
///   throw (e.g. a PlatformException from the service bind attempt).
/// - With no init at all, the platform is never swapped and `MediaItem` tags
///   are simply ignored — tags are never serialized by the method-channel
///   platform (`'tag'` appears in no `toMap` implementation of
///   just_audio_platform_interface 4.6.0), so foreground playback stays safe.
///
/// Chosen semantics: app startup must never fail because of background audio.
/// [attempt] runs the initializer, never rethrows, and reports the outcome;
/// `main` continues either way. If init failed, later playback attempts
/// surface through the existing `PlaybackFailureKind.network` path in
/// `PlaybackCubit` instead of crashing the launch.
class BackgroundInitGuard {
  BackgroundInitGuard._();

  static bool _active = false;

  /// Whether the most recent [attempt] completed successfully.
  static bool get active => _active;

  /// Runs [init] (the `JustAudioBackground.init` call) and never rethrows.
  static Future<bool> attempt(Future<void> Function() init) async {
    try {
      await init();
      _active = true;
      return true;
    } on Object {
      _active = false;
      return false;
    }
  }
}
