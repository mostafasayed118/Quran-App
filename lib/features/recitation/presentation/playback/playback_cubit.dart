import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/db/app_database.dart';
import '../../data/audio_downloader.dart';
import '../../data/reciter_repository.dart';
import '../../playback/playback_service.dart';
import 'playback_state.dart';

class PlaybackCubit extends Cubit<PlaybackState> {
  PlaybackCubit({
    required PlaybackService service,
    required ReciterRepository reciters,
    required AudioDownloader downloader,
  })  : _service = service,
        _reciters = reciters,
        _downloader = downloader,
        super(const PlaybackState.initial());

  final PlaybackService _service;
  final ReciterRepository _reciters;
  final AudioDownloader _downloader;

  String _reciterName = '';

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  Future<void> playSurah(ReciterRow row, int surahNumber) async {
    if (isClosed) return;
    _reciterName = row.reciterName;
    emit(PlaybackState.loading(
      reciterName: row.reciterName,
      surahNumber: surahNumber,
    ));
    final downloaded = await _downloader.downloadedPath(row.id, surahNumber);
    if (isClosed) return;
    final source = downloaded != null
        ? PlaybackSource.file(
            downloaded,
            mediaTitle: row.reciterName,
            artist: row.reciterName,
          )
        : PlaybackSource.url(
            Uri.parse(surahAudioUrl(row.server, surahNumber)),
            mediaTitle: row.reciterName,
            artist: row.reciterName,
          );
    _bindStreams();
    try {
      await _service.loadAndPlay(source);
      if (isClosed) return;
      emit(PlaybackState.playing(
        reciterName: _reciterName,
        surahNumber: surahNumber,
      ));
    } on Object {
      if (isClosed) return;
      emit(const PlaybackState.failed(kind: PlaybackFailureKind.network));
    }
  }

  Future<void> playDefaultForSurah(int surahNumber) async {
    final ReciterRow row;
    try {
      final selectedId = await _reciters.loadSelectedMoshaf();
      var candidate =
          selectedId == null ? null : await _reciters.byId(selectedId);
      if (candidate == null) {
        final all = sortReciters(await _reciters.watchAll().first);
        if (isClosed) return;
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
      if (isClosed) return;
      emit(const PlaybackState.failed(kind: PlaybackFailureKind.network));
      return;
    }
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
