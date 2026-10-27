import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/audio_downloader.dart';
import '../../data/reciter_info_source.dart';
import '../../data/reciter_repository.dart' show surahAudioUrl;
import '../../domain/reciter_info.dart';
import '../../playback/background_init_guard.dart';
import '../../playback/playback_service.dart';
import 'playback_state.dart';

// The row-typed entry point lives in its own file so this surface never
// imports a drift row; it is re-exported for the frozen recitation doubles.
export 'playback_row_entry.dart';

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
  })  : _service = service,
        _reciters = reciters,
        _downloader = downloader,
        _backgroundActive = backgroundActive ?? _probeBackgroundInit,
        super(const PlaybackState.initial());

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

  /// Entity entry for the re-typed screens (ready states carry
  /// [ReciterInfo], never drift rows).
  Future<void> playReciter(ReciterInfo reciter, int surahNumber) =>
      _start(reciter.id, reciter.reciterName, reciter.server, surahNumber);

  Future<void> _start(
      String rowId, String reciterName, String server, int surahNumber) async {
    if (isClosed) return;
    final episode = ++_episode;
    _lastDuration = Duration.zero;
    _reciterName = reciterName;
    emit(PlaybackState.loading(
      reciterName: reciterName,
      surahNumber: surahNumber,
    ));
    String? downloaded;
    try {
      downloaded = await _downloader.downloadedPath(rowId, surahNumber);
    } on Object catch (error, stackTrace) {
      // A registry read failure is not a playback failure: fall back to the
      // remote URL instead of leaving the state stuck in loading.
      dev.log('download lookup failed',
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
      if (isClosed || episode != _episode) return;
      if (state is! PlaybackLoading) return;
      emit(PlaybackState.playing(
        reciterName: _reciterName,
        surahNumber: surahNumber,
        duration: _lastDuration,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('playback load failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
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
  Future<void> playDefaultForSurah(int surahNumber) async {
    final episode = ++_episode;
    final ReciterInfo? reciter;
    try {
      reciter = await _reciters.defaultReciter();
    } on Object catch (error, stackTrace) {
      dev.log('reciter lookup failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      if (isClosed || episode != _episode) return;
      emit(const PlaybackState.failed(kind: PlaybackFailureKind.network));
      return;
    }
    if (isClosed || episode != _episode) return;
    if (reciter == null) {
      emit(const PlaybackState.failed(
        kind: PlaybackFailureKind.noReciters,
      ));
      return;
    }
    await playReciter(reciter, surahNumber);
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
        dev.log('pause failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
        return;
      }
      if (isClosed || episode != _episode) return;
      emit(PlaybackState.paused(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: state.position,
        duration: state.duration,
      ));
    } else if (state is PlaybackPaused) {
      try {
        await _service.resume();
      } on Object catch (error, stackTrace) {
        // Keep the paused state: resume did not take effect.
        dev.log('resume failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
        return;
      }
      if (isClosed || episode != _episode) return;
      emit(PlaybackState.playing(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: state.position,
        duration: state.duration,
      ));
    }
  }

  /// Stops the playback and returns to the idle (not-ready) state.
  ///
  /// The play-attempt counter is bumped, so a late success of the stopped
  /// attempt is discarded instead of resurrecting a track.
  Future<void> stopAndReset() async {
    final episode = ++_episode;
    try {
      await _service.stop();
    } on Object catch (error, stackTrace) {
      dev.log('stop failed',
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
            (_) => unawaited(stopAndReset()),
            onError: _onStreamError,
          );
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    dev.log('playback stream error',
        name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
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
    try {
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
    if (isClosed) return;
    final state = this.state;
    if (playing && state is PlaybackLoading && state.reciterName != null) {
      emit(PlaybackState.playing(
        reciterName: state.reciterName!,
        surahNumber: state.surahNumber,
        duration: _lastDuration,
      ));
    } else if (playing && state is PlaybackPaused) {
      emit(PlaybackState.playing(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: state.position,
        duration: state.duration,
      ));
    } else if (!playing && state is PlaybackPlaying) {
      emit(PlaybackState.paused(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: state.position,
        duration: state.duration,
      ));
    }
  }

  void _onPositionChanged(Duration position) {
    if (isClosed) return;
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
      emit(PlaybackState.playing(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: position,
        duration: state.duration,
      ));
    } else if (state is PlaybackPaused) {
      emit(PlaybackState.paused(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: position,
        duration: state.duration,
      ));
    }
  }

  void _onDurationChanged(Duration? duration) {
    if (isClosed || duration == null) return;
    _lastDuration = duration;
    final state = this.state;
    if (state is PlaybackPlaying) {
      emit(PlaybackState.playing(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: state.position,
        duration: duration,
      ));
    } else if (state is PlaybackPaused) {
      emit(PlaybackState.paused(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: state.position,
        duration: duration,
      ));
    }
  }
}
