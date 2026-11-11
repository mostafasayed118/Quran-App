import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/adhan_player.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../../core/domain/quran_limits.dart';
import '../../data/audio_downloader.dart';
import '../../data/reciter_info_source.dart';
import '../../data/reciter_repository.dart' show surahAudioUrl;
import '../../domain/reciter_info.dart';
import '../../playback/background_init_guard.dart';
import '../../playback/playback_service.dart';
import 'playback_state.dart';

// The row-typed entry point lives in its own file so this surface never
// imports a drift row; it is re-exported for the frozen recitation doubles.
export '../../data/playback_row_entry.dart';

/// The player: the current track, its position and the mini player's state.
class PlaybackCubit extends Cubit<PlaybackState> {
  /// Creates the cubit around the playback service.
  ///
  /// [backgroundActive] is the probe that decides how a load failure is
  /// labelled; it defaults to the production probe.
  PlaybackCubit({
    required PlaybackService service,
    required ReciterInfoSource reciters,
    required AudioDownloader downloader,
    bool Function()? backgroundActive,
    Stream<AdhanPlaybackState>? adhanStates,
  })  : _service = service,
        _reciters = reciters,
        _downloader = downloader,
        _backgroundActive = backgroundActive ?? _probeBackgroundInit,
        super(const PlaybackState.initial()) {
    _adhanSub = adhanStates?.listen(_onAdhanState, onError: _onStreamError);
  }

  final PlaybackService _service;
  final ReciterInfoSource _reciters;
  final AudioDownloader _downloader;

  /// Decides how a failed load is labelled: `true` (background audio is up)
  /// → [PlaybackFailureKind.network], `false` (background audio is known to
  /// be down) → [PlaybackFailureKind.backgroundUnavailable] instead of
  /// masquerading as a network failure.
  ///
  /// The INJECTED probe keeps exactly that meaning. The PRODUCTION probe
  /// ([_probeBackgroundInit]) answers the truthful question — "is background
  /// audio known to be unavailable?" — so a load that fails while the
  /// bootstrap is still PENDING is not reported as a missing background
  /// service.
  final bool Function() _backgroundActive;

  /// The production probe: background audio counts as available until an
  /// attempt has settled AND failed.
  ///
  /// The bootstrap runs behind the first frame, so during the first ~1.5 s
  /// the outcome is simply unknown. A pending attempt is not a failure, and
  /// claiming "background audio unavailable" on that basis would state
  /// something false about the user's device.
  static bool _probeBackgroundInit() => BackgroundInitGuard.available;

  String _reciterName = '';

  /// The current track's reciter row and server, kept so next/previous and
  /// repeat can restart without another catalog lookup.
  String _rowId = '';
  String _server = '';

  /// Player preferences that survive track changes.
  double _speed = 1.0;
  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.off;

  /// The selected sleep duration; null when the timer is off.
  Duration? _sleepTimerDuration;
  Timer? _sleepTimer;

  /// The speeds the player cycles through.
  static const List<double> speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  /// The last non-null track duration the service reported.
  ///
  /// The duration can arrive while the track is still loading, before the
  /// cubit holds a [PlaybackPlaying] state; the promotion into that state
  /// seeds this value instead of starting from zero.
  Duration _lastDuration = Duration.zero;

  /// Monotonic play-attempt counter: bumped by every play attempt and by
  /// [stopAndReset], so a hung attempt's late success/failure is discarded
  /// once a newer attempt (or a stop) superseded it.
  int _episode = 0;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<void>? _completionSub;
  StreamSubscription<AdhanPlaybackState>? _adhanSub;

  /// True while the shared player is carrying the adhan (full or preview).
  /// The player's streams are the adhan's during that window, not the
  /// recitation's, so they must not rebuild the surah state.
  bool _externalAudioActive = false;

  /// Entity entry for the re-typed screens (ready states carry
  /// [ReciterInfo], never drift rows).
  ///
  /// [surahName] is the display name when the caller knows it; the player
  /// shows it instead of a bare number.
  Future<void> playReciter(ReciterInfo reciter, int surahNumber,
          {String surahName = ''}) =>
      _start(reciter.id, reciter.reciterName, reciter.server, surahNumber,
          surahName);

  Future<void> _start(String rowId, String reciterName, String server,
      int surahNumber, String surahName) async {
    if (isClosed) return;
    final episode = ++_episode;
    _lastDuration = Duration.zero;
    _reciterName = reciterName;
    _rowId = rowId;
    _server = server;
    emit(PlaybackState.loading(
      reciterName: reciterName,
      surahNumber: surahNumber,
      surahName: surahName,
    ));
    String? downloaded;
    try {
      downloaded = await _downloader.downloadedPath(rowId, surahNumber);
    } on Object catch (error, stackTrace) {
      // A registry read failure is not a playback failure: fall back to the
      // remote URL instead of leaving the state stuck in loading.
      appLog('download lookup failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      downloaded = null;
    }
    if (isClosed || episode != _episode) return;
    final source = downloaded != null
        ? PlaybackSource.file(
            downloaded,
            mediaTitle: reciterName,
            artist: reciterName,
          )
        : PlaybackSource.url(
            Uri.parse(surahAudioUrl(server, surahNumber)),
            mediaTitle: reciterName,
            artist: reciterName,
          );
    _bindStreams();
    try {
      await _service.loadAndPlay(source);
      await _applyTuning();
      if (isClosed || episode != _episode) return;
      if (state is! PlaybackLoading) return;
      emit(PlaybackState.playing(
        reciterName: _reciterName,
        surahNumber: surahNumber,
        surahName: surahName,
        duration: _lastDuration,
        speed: _speed,
        repeatMode: _repeatMode,
        sleepTimer: _sleepTimerDuration,
      ));
    } on Object catch (error, stackTrace) {
      appLog('playback load failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      if (isClosed || episode != _episode) return;
      await _stopBestEffort();
      if (isClosed || episode != _episode) return;
      emit(PlaybackState.failed(
        kind: _backgroundActive()
            ? PlaybackFailureKind.network
            : PlaybackFailureKind.backgroundUnavailable,
      ));
    }
  }

  /// Plays the default reciter's audio for [surahNumber].
  ///
  /// A missing default reciter fails with [PlaybackFailureKind.noReciters];
  /// a lookup error fails with [PlaybackFailureKind.network].
  Future<void> playDefaultForSurah(int surahNumber,
      {String surahName = ''}) async {
    final episode = ++_episode;
    final ReciterInfo? reciter;
    try {
      reciter = await _reciters.defaultReciter();
    } on Object catch (error, stackTrace) {
      appLog('reciter lookup failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      if (isClosed || episode != _episode) return;
      await _stopBestEffort();
      if (isClosed || episode != _episode) return;
      emit(const PlaybackState.failed(kind: PlaybackFailureKind.network));
      return;
    }
    if (isClosed || episode != _episode) return;
    if (reciter == null) {
      await _stopBestEffort();
      if (isClosed || episode != _episode) return;
      emit(const PlaybackState.failed(
        kind: PlaybackFailureKind.noReciters,
      ));
      return;
    }
    await playReciter(reciter, surahNumber, surahName: surahName);
  }

  /// Sets the playback speed, clamped to 0.75–2.0.
  ///
  /// A service without [TunablePlaybackService] still updates the state so
  /// the control stays coherent; the production adapter implements it.
  Future<void> setSpeed(double speed) async {
    final safe = speed < 0.75 ? 0.75 : (speed > 2.0 ? 2.0 : speed);
    if (safe == _speed) return;
    _speed = safe;
    if (_service case final TunablePlaybackService tunable) {
      try {
        await tunable.setSpeed(safe);
      } on Object catch (error, stackTrace) {
        appLog('speed change failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      }
    }
    _emitControls();
  }

  /// Advances to the next speed in [speeds].
  Future<void> cycleSpeed() {
    final index = speeds.indexOf(_speed);
    final next = speeds[(index < 0 ? 0 : index + 1) % speeds.length];
    return setSpeed(next);
  }

  /// Toggles between stopping at the end of the surah and repeating it.
  Future<void> toggleRepeat() async {
    _repeatMode = _repeatMode == PlaybackRepeatMode.one
        ? PlaybackRepeatMode.off
        : PlaybackRepeatMode.one;
    if (_service case final TunablePlaybackService tunable) {
      try {
        await tunable.setLoopMode(_repeatMode == PlaybackRepeatMode.one);
      } on Object catch (error, stackTrace) {
        appLog('repeat change failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      }
    }
    _emitControls();
  }

  /// Pauses the track after [duration]; a zero duration clears the timer.
  Future<void> startSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (duration <= Duration.zero) {
      _sleepTimerDuration = null;
      _emitControls();
      return;
    }
    _sleepTimerDuration = duration;
    _sleepTimer = Timer(duration, () => unawaited(_sleepNow()));
    _emitControls();
  }

  /// Clears the sleep timer without touching playback.
  Future<void> cancelSleepTimer() => startSleepTimer(Duration.zero);

  /// Plays the next surah of the current reciter when one exists.
  Future<void> nextSurah() => _skipTo(1);

  /// Plays the previous surah of the current reciter when one exists.
  Future<void> previousSurah() => _skipTo(-1);

  /// Applies the retained speed/loop preference to a freshly loaded source.
  Future<void> _applyTuning() async {
    if (_service case final TunablePlaybackService tunable) {
      try {
        await tunable.setSpeed(_speed);
        await tunable.setLoopMode(_repeatMode == PlaybackRepeatMode.one);
      } on Object catch (error, stackTrace) {
        appLog('playback tuning failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      }
    }
  }

  Future<void> _skipTo(int delta) async {
    final state = this.state;
    final current = switch (state) {
      PlaybackPlaying(:final surahNumber) => surahNumber,
      PlaybackPaused(:final surahNumber) => surahNumber,
      PlaybackLoading(:final surahNumber) => surahNumber,
      PlaybackFailed() => 0,
    };
    if (current <= 0 || _rowId.isEmpty) return;
    final next = current + delta;
    if (next < kFirstSurahId || next > kSurahCount) return;
    await _start(_rowId, _reciterName, _server, next, '');
  }

  /// The end-of-track policy: repeat the surah or stop.
  Future<void> _onCompleted() async {
    if (isClosed || _externalAudioActive) return;
    final state = this.state;
    final current = switch (state) {
      PlaybackPlaying(:final surahNumber, :final surahName) => (
          number: surahNumber,
          name: surahName
        ),
      PlaybackPaused(:final surahNumber, :final surahName) => (
          number: surahNumber,
          name: surahName
        ),
      _ => null,
    };
    if (current == null || _rowId.isEmpty) {
      await stopAndReset();
      return;
    }
    if (_repeatMode == PlaybackRepeatMode.one) {
      await _start(
        _rowId,
        _reciterName,
        _server,
        current.number,
        current.name,
      );
      return;
    }
    await stopAndReset();
  }

  Future<void> _sleepNow() async {
    _sleepTimer = null;
    _sleepTimerDuration = null;
    if (isClosed) return;
    final state = this.state;
    if (state is PlaybackPlaying) {
      try {
        await _service.pause();
      } on Object catch (error, stackTrace) {
        // The timer still clears; the audio may keep playing and the user can
        // pause it manually.
        appLog('sleep timer pause failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      }
      if (isClosed) return;
      emit(PlaybackState.paused(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        surahName: state.surahName,
        position: state.position,
        duration: state.duration,
        speed: state.speed,
        repeatMode: state.repeatMode,
        sleepTimer: null,
      ));
    } else if (state is PlaybackPaused) {
      emit(state.copyWith(sleepTimer: null));
    }
  }

  ({double speed, PlaybackRepeatMode repeatMode, Duration? sleepTimer})
      _controlsOf(PlaybackState state) => switch (state) {
            PlaybackPlaying(
              :final speed,
              :final repeatMode,
              :final sleepTimer,
            ) =>
              (speed: speed, repeatMode: repeatMode, sleepTimer: sleepTimer),
            PlaybackPaused(
              :final speed,
              :final repeatMode,
              :final sleepTimer,
            ) =>
              (speed: speed, repeatMode: repeatMode, sleepTimer: sleepTimer),
            _ => (
                speed: _speed,
                repeatMode: _repeatMode,
                sleepTimer: _sleepTimerDuration,
              ),
          };

  void _emitControls() {
    if (isClosed) return;
    final state = this.state;
    if (state is PlaybackPlaying) {
      emit(state.copyWith(
        speed: _speed,
        repeatMode: _repeatMode,
        sleepTimer: _sleepTimerDuration,
      ));
    } else if (state is PlaybackPaused) {
      emit(state.copyWith(
        speed: _speed,
        repeatMode: _repeatMode,
        sleepTimer: _sleepTimerDuration,
      ));
    }
  }

  /// Stops the audio before a failed attempt becomes visible.
  ///
  /// The failure strip must never sit above a track that is still audible;
  /// a stop failure is logged and does not block the failure state.
  Future<void> _stopBestEffort() async {
    try {
      await _service.stop();
    } on Object catch (error, stackTrace) {
      appLog('playback stop failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
    }
  }

  /// Seeks inside the loaded track.
  ///
  /// A service without the [SeekablePlaybackService] capability (the plain
  /// test seam) ignores the request; a seek failure is logged and keeps the
  /// current state — the position stream remains the source of truth.
  Future<void> seek(Duration to) async {
    if (_service case final SeekablePlaybackService seekable) {
      try {
        await seekable.seek(to);
      } on Object catch (error, stackTrace) {
        appLog('seek failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      }
    }
  }

  /// Pauses a playing track, resumes a paused one; a no-op otherwise.
  ///
  /// A failed pause/resume keeps the current state: the audio is still
  /// audible (pause) or still paused (resume).
  Future<void> toggle() async {
    final state = this.state;
    final episode = _episode;
    if (state is PlaybackPlaying) {
      try {
        await _service.pause();
      } on Object catch (error, stackTrace) {
        // Keep the playing state: the audio is still audible.
        appLog('pause failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
        return;
      }
      if (isClosed || episode != _episode) return;
      emit(PlaybackState.paused(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        surahName: state.surahName,
        position: state.position,
        duration: state.duration,
        speed: state.speed,
        repeatMode: state.repeatMode,
        sleepTimer: state.sleepTimer,
      ));
    } else if (state is PlaybackPaused) {
      try {
        await _service.resume();
      } on Object catch (error, stackTrace) {
        // Keep the paused state: resume did not take effect.
        appLog('resume failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
        return;
      }
      if (isClosed || episode != _episode) return;
      emit(PlaybackState.playing(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        surahName: state.surahName,
        position: state.position,
        duration: state.duration,
        speed: state.speed,
        repeatMode: state.repeatMode,
        sleepTimer: state.sleepTimer,
      ));
    }
  }

  /// Stops the playback and returns to the idle (not-ready) state.
  ///
  /// The play-attempt counter is bumped, so a late success of the stopped
  /// attempt is discarded instead of resurrecting a track.
  Future<void> stopAndReset() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerDuration = null;
    _rowId = '';
    final episode = ++_episode;
    try {
      await _service.stop();
    } on Object catch (error, stackTrace) {
      appLog('stop failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
    }
    // A newer play (or stop) superseded this one: its streams must stay bound.
    if (isClosed || episode != _episode) return;
    await _unbindStreams();
    if (isClosed) return;
    emit(const PlaybackState.initial());
  }

  void _bindStreams() {
    _playingSub ??= _service
        .playingStream()
        .listen(_onPlayingChanged, onError: _onStreamError);
    _positionSub ??= _service
        .positionStream()
        .listen(_onPositionChanged, onError: _onStreamError);
    _durationSub ??= _service
        .durationStream()
        .listen(_onDurationChanged, onError: _onStreamError);
    if (_service case final CompletingPlaybackService completing) {
      _completionSub ??= completing.completionStream().listen(
            (_) => unawaited(_onCompleted()),
            onError: _onStreamError,
          );
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    appLog('playback stream error',
        name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
  }

  /// The adhan took over the shared player: clear the surah state without
  /// stopping the player (the adhan already did) and drop the recitation
  /// stream subscriptions so the adhan's events cannot be read as the surah's.
  void _onAdhanState(AdhanPlaybackState adhan) {
    if (isClosed) return;
    if (adhan.isPlaying) {
      if (_externalAudioActive) return;
      _externalAudioActive = true;
      _resetForExternalAudio();
    } else if (_externalAudioActive) {
      _externalAudioActive = false;
    }
  }

  void _resetForExternalAudio() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerDuration = null;
    _rowId = '';
    _episode++;
    unawaited(_unbindStreams());
    if (!isClosed) emit(const PlaybackState.initial());
  }

  Future<void> _unbindStreams() async {
    await _playingSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _completionSub?.cancel();
    _playingSub = null;
    _positionSub = null;
    _durationSub = null;
    _completionSub = null;
  }

  /// Unbinds the player streams and disposes the service when it owns
  /// platform resources.
  @override
  Future<void> close() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    try {
      await _adhanSub?.cancel();
      _adhanSub = null;
      await _unbindStreams();
      // The service owns the platform resources (ExoPlayer, audio focus). It
      // is disposed only when it exposes the capability - the frozen test
      // doubles implement the plain seam and own nothing.
      final Object service = _service;
      if (service is DisposablePlaybackService) {
        await service.dispose();
      }
    } finally {
      await super.close();
    }
  }

  void _onPlayingChanged(bool playing) {
    if (isClosed || _externalAudioActive) return;
    final state = this.state;
    if (playing && state is PlaybackLoading && state.reciterName != null) {
      emit(PlaybackState.playing(
        reciterName: state.reciterName!,
        surahNumber: state.surahNumber,
        surahName: state.surahName,
        duration: _lastDuration,
        speed: _speed,
        repeatMode: _repeatMode,
        sleepTimer: _sleepTimerDuration,
      ));
    } else if (playing && state is PlaybackPaused) {
      final controls = _controlsOf(state);
      emit(PlaybackState.playing(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        surahName: state.surahName,
        position: state.position,
        duration: state.duration,
        speed: controls.speed,
        repeatMode: controls.repeatMode,
        sleepTimer: controls.sleepTimer,
      ));
    } else if (!playing && state is PlaybackPlaying) {
      emit(PlaybackState.paused(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        surahName: state.surahName,
        position: state.position,
        duration: state.duration,
        speed: state.speed,
        repeatMode: state.repeatMode,
        sleepTimer: state.sleepTimer,
      ));
    }
  }

  void _onPositionChanged(Duration position) {
    if (isClosed || _externalAudioActive) return;
    final state = this.state;
    final current = switch (state) {
      PlaybackPlaying(position: final p) => p,
      PlaybackPaused(position: final p) => p,
      _ => null,
    };
    // The plugin stream is already capped at 1 Hz; this dedupe also protects
    // the UI from a replayed tick at the same wall-clock second.
    if (current != null && current.inSeconds == position.inSeconds) return;
    if (state is PlaybackPlaying) {
      emit(state.copyWith(position: position));
    } else if (state is PlaybackPaused) {
      emit(state.copyWith(position: position));
    }
  }

  void _onDurationChanged(Duration? duration) {
    if (isClosed || _externalAudioActive || duration == null) return;
    _lastDuration = duration;
    final state = this.state;
    if (state is PlaybackPlaying) {
      emit(state.copyWith(duration: duration));
    } else if (state is PlaybackPaused) {
      emit(state.copyWith(duration: duration));
    }
  }
}
