import 'dart:async';

import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/adhan_player.dart';
import 'package:quran_yahdi/core/domain/media_playback_control.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

/// Plays the adhan through the app's single audio player, owning the policy:
///
/// * readiness is checked **before** anything is stopped — otherwise a plugin
///   that never initialised would silence the user's Quran and play nothing;
/// * every request waits for the audio plugin to settle, because the boot path
///   deliberately does not block on it (AGENTS.md) — but only for
///   [readyTimeout], since the guard's completer never resolves if the plugin
///   itself hangs;
/// * recitation stops first, so two streams never mix;
/// * a missing asset or an unready plugin fails open: logged, player left
///   idle, nothing thrown at the UI.
class JustAudioAdhanPlayer implements AdhanPlayer {
  /// Creates the player.
  ///
  /// [ready] resolves true once the audio plugin is usable, false when its
  /// boot-time initialisation already failed. [control] is the shared player;
  /// [readyTimeout] bounds the wait so a hanging plugin cannot queue a request
  /// forever.
  JustAudioAdhanPlayer({
    required Future<bool> Function() ready,
    required MediaPlaybackControl control,
    Duration readyTimeout = const Duration(seconds: 2),
  })  : _ready = ready,
        _control = control,
        _readyTimeout = readyTimeout {
    _completionSub =
        _control.adhanCompleted.listen((_) => _emit(AdhanPlaybackState.idle));
  }

  final Future<bool> Function() _ready;
  final MediaPlaybackControl _control;
  final Duration _readyTimeout;

  final StreamController<AdhanPlaybackState> _states =
      StreamController<AdhanPlaybackState>.broadcast();

  late final StreamSubscription<void> _completionSub;

  AdhanPlaybackState _state = AdhanPlaybackState.idle;

  /// A queue of one: a newer request never lands before an older one.
  Future<void> _tail = Future<void>.value();

  @override
  Stream<AdhanPlaybackState> get state => _states.stream;

  /// The synchronous snapshot (the stream is broadcast and never replays).
  AdhanPlaybackState get stateNow => _state;

  @override
  Future<void> play(String trackId) => _enqueue(() async {
        if (!await _ensureReady()) return;
        await _control.stopForAdhan();
        await _start(trackId, preview: false);
      });

  @override
  Future<void> preview(String trackId) => _enqueue(() async {
        if (!await _ensureReady()) return;
        // A second audition replaces the first rather than mixing with it.
        await _control.stopForAdhan();
        await _start(trackId, preview: true);
      });

  @override
  Future<void> stop() => _enqueue(() async {
        await _control.stopForAdhan();
        _emit(AdhanPlaybackState.idle);
      });

  /// False when the plugin failed or never settled. The request is not an
  /// error: it is reported once and the player stays idle.
  Future<bool> _ensureReady() async {
    bool ok;
    try {
      ok = await _ready().timeout(_readyTimeout, onTimeout: () => false);
    } on Object {
      ok = false;
    }
    if (ok) return true;
    _log('audio plugin never became ready');
    _emit(AdhanPlaybackState.idle);
    return false;
  }

  Future<void> _start(String trackId, {required bool preview}) async {
    final track = adhanById(trackId);
    try {
      _emit(AdhanPlaybackState(
        status: AdhanPlaybackStatus.playing,
        trackId: track.id,
      ));
      await _control.playAdhan(
        preview ? track.clipPath : track.assetPath,
        id: track.id,
        title: track.nameAr,
      );
    } on Object catch (error, stackTrace) {
      appLog(
        'adhan ${preview ? 'preview' : 'play'} failed',
        name: 'quran_yahdi/adhan',
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
      _emit(AdhanPlaybackState.idle);
    }
  }

  Future<void> _enqueue(Future<void> Function() op) {
    final result = _tail.then<void>((_) => op());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  void _emit(AdhanPlaybackState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  void _log(String message) => appLog(
        message,
        name: 'quran_yahdi/adhan',
      );

  /// Releases the stream and silences the player. Wired as the GetIt
  /// `dispose:` callback.
  Future<void> dispose() async {
    await _completionSub.cancel();
    await _control.stopForAdhan();
    await _states.close();
  }
}
