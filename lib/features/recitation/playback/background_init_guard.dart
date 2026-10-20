import 'dart:async';

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
/// `main` continues either way.
///
/// The guard is TRI-STATE, because the bootstrap runs BEHIND the first frame:
/// the first paint no longer waits for the plugin, so "no result yet" is a
/// normal state and not a failure.
///
/// | state   | [settled] | [active] | [available] |
/// |---------|-----------|----------|-------------|
/// | pending | false     | false    | true        |
/// | active  | true      | true     | true        |
/// | failed  | true      | false    | false       |
///
/// [available] is the only question a caller may ask before claiming that
/// background audio is unavailable: a PENDING attempt counts as available,
/// because unavailability is established by a settled failure and never by a
/// missing result. A load that fails while the bootstrap is still pending is
/// therefore labelled `PlaybackFailureKind.network` by `PlaybackCubit`; only a
/// settled failure produces the "background audio unavailable" wording.
class BackgroundInitGuard {
  BackgroundInitGuard._();

  static bool _active = false;
  static bool _settled = false;
  static Completer<bool> _readyCompleter = Completer<bool>();

  /// Whether the most recent [attempt] completed successfully.
  ///
  /// True only after a successful init. False both while the attempt is
  /// still running and after a failed one — [settled] tells the two apart.
  static bool get active => _active;

  /// Whether the most recent [attempt] has finished — successfully or not.
  ///
  /// False means the attempt is still PENDING, which is the normal state
  /// during the first seconds of the app (the bootstrap runs behind the
  /// first frame). True means the outcome is known: read [active] for it.
  static bool get settled => _settled;

  /// Whether background audio is NOT known to be unavailable.
  ///
  /// True while the attempt is pending and after a successful one; false
  /// only after a settled failure. A caller must ask this (never [active])
  /// before claiming that background audio is unavailable.
  static bool get available => _active || !_settled;

  /// Completes with the outcome of the attempt: true when the init
  /// succeeded, false when it failed.
  ///
  /// Lets a caller observe the outcome without polling. [attempt] completes
  /// this future in a `finally`, so it also settles on failure; reading it
  /// before any attempt started waits for the first one. Nothing on the
  /// playback path may await this — the guard is only driven by the app
  /// bootstrap, and a playback attempt must never block on it.
  static Future<bool> get ready => _readyCompleter.future;

  /// Runs [init] (the `JustAudioBackground.init` call) and never rethrows.
  ///
  /// Each attempt starts a new readiness cycle: [settled] goes back to false
  /// (PENDING) and the outcome is published through [ready].
  static Future<bool> attempt(Future<void> Function() init) async {
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<bool>();
    }
    _active = false;
    _settled = false;
    try {
      await init();
      _active = true;
      return true;
    } on Object {
      _active = false;
      return false;
    } finally {
      _settled = true;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete(_active);
      }
    }
  }
}
