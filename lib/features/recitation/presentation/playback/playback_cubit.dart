import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../data/audio_downloader.dart';
import '../../data/reciter_repository.dart';
import '../../data/reciter_source.dart';
import '../../domain/reciter_info.dart';
import '../../playback/background_init_guard.dart';
import '../../playback/playback_service.dart';
import 'playback_state.dart';

class PlaybackCubit extends Cubit<PlaybackState> {
  PlaybackCubit({
    required PlaybackService service,
    required ReciterSource reciters,
    required AudioDownloader downloader,
    bool Function()? backgroundActive,
  })  : _service = service,
        _reciters = reciters,
        _downloader = downloader,
        _backgroundActive = backgroundActive ?? _probeBackgroundInit,
        super(const PlaybackState.initial());

  final PlaybackService _service;
  final ReciterSource _reciters;
  final AudioDownloader _downloader;

  /// Whether the background-audio bootstrap succeeded. When it did not, a
  /// failed load is labelled [PlaybackFailureKind.backgroundUnavailable]
  /// instead of masquerading as a network failure.
  final bool Function() _backgroundActive;

  static bool _probeBackgroundInit() => BackgroundInitGuard.active;

  String _reciterName = '';

  /// Monotonic play-attempt counter: bumped by every play attempt and by
  /// [stopAndReset], so a hung attempt's late success/failure is discarded
  /// once a newer attempt (or a stop) superseded it.
  int _episode = 0;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  /// Row-typed entry: the frozen recitation doubles call it with
  /// `ReciterRow` literals, so the signature stays pinned; it funnels into
  /// the same shared start path as [playReciter].
  Future<void> playSurah(ReciterRow row, int surahNumber) =>
      _start(row.id, row.reciterName, row.server, surahNumber);

  /// Entity entry for the re-typed screens (ready states carry
  /// [ReciterInfo], never drift rows).
  Future<void> playReciter(ReciterInfo reciter, int surahNumber) =>
      _start(reciter.id, reciter.reciterName, reciter.server, surahNumber);

  Future<void> _start(
      String rowId, String reciterName, String server, int surahNumber) async {
    if (isClosed) return;
    final episode = ++_episode;
    _reciterName = reciterName;
    emit(PlaybackState.loading(
      reciterName: reciterName,
      surahNumber: surahNumber,
    ));
    final downloaded = await _downloader.downloadedPath(rowId, surahNumber);
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
      emit(PlaybackState.playing(
        reciterName: _reciterName,
        surahNumber: surahNumber,
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

  Future<void> playDefaultForSurah(int surahNumber) async {
    final episode = ++_episode;
    final ReciterRow row;
    try {
      final selectedId = await _reciters.loadSelectedMoshaf();
      var candidate =
          selectedId == null ? null : await _reciters.byId(selectedId);
      if (candidate == null) {
        final all = sortReciters(await _reciters.watchAll().first);
        if (isClosed || episode != _episode) return;
        if (all.isEmpty) {
          emit(const PlaybackState.failed(
            kind: PlaybackFailureKind.noReciters,
          ));
          return;
        }
        candidate = all.first;
      }
      row = candidate;
    } on Object catch (error, stackTrace) {
      dev.log('reciter lookup failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
      if (isClosed || episode != _episode) return;
      emit(const PlaybackState.failed(kind: PlaybackFailureKind.network));
      return;
    }
    if (isClosed || episode != _episode) return;
    await playSurah(row, surahNumber);
  }

  Future<void> toggle() async {
    final state = this.state;
    if (state is PlaybackPlaying) {
      try {
        await _service.pause();
      } on Object catch (error, stackTrace) {
        // Keep the playing state: the audio is still audible.
        dev.log('pause failed',
            name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
        return;
      }
      if (isClosed) return;
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
      if (isClosed) return;
      emit(PlaybackState.playing(
        reciterName: state.reciterName,
        surahNumber: state.surahNumber,
        position: state.position,
        duration: state.duration,
      ));
    }
  }

  Future<void> stopAndReset() async {
    _episode++;
    try {
      await _service.stop();
    } on Object catch (error, stackTrace) {
      dev.log('stop failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
    }
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
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    dev.log('playback stream error',
        name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
  }

  Future<void> _unbindStreams() async {
    await _playingSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    _playingSub = null;
    _positionSub = null;
    _durationSub = null;
  }

  @override
  Future<void> close() async {
    await _unbindStreams();
    return super.close();
  }

  void _onPlayingChanged(bool playing) {
    if (isClosed) return;
    final state = this.state;
    if (playing && state is PlaybackPaused) {
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
