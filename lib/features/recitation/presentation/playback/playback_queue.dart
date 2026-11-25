part of 'playback_cubit.dart';

extension PlaybackQueue on PlaybackCubit {
  /// Plays the next surah of the current reciter when one exists.
  Future<void> nextSurah() => _skipTo(1);

  /// Plays the previous surah of the current reciter when one exists.
  Future<void> previousSurah() => _skipTo(-1);

  /// Whether the current track has a next surah in this reciter's list.
  bool get hasNextSurah => _stepTarget(1) != null;

  /// Whether the current track has a previous surah in this reciter's list.
  bool get hasPreviousSurah => _stepTarget(-1) != null;

  /// Applies the retained speed/loop preference to a freshly loaded source.
  Future<void> _applyTuning() async {
    if (_service case final TunablePlaybackService tunable) {
      try {
        await tunable.setSpeed(_speed);
        await tunable.setLoopMode(_repeatMode == PlaybackRepeatMode.one);
      } on Object catch (error, stackTrace) {
        appLog(
          'playback tuning failed',
          name: 'quran_yahdi/playback',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _skipTo(int delta) async {
    final target = _stepTarget(delta);
    if (target == null || _rowId.isEmpty) return;
    final name = await _resolveName(target);
    if (isClosed) return;
    await _start(_rowId, _reciterName, _server, target, name);
  }

  /// The surah [delta] steps away in the reciter's list, or null at an edge.
  ///
  /// A reciter that serves a subset must step within that subset (1, 3, 7 -
  /// never the missing 2); an unknown/empty list falls back to 1..114.
  int? _stepTarget(int delta) {
    final state = this.state;
    final current = switch (state) {
      PlaybackPlaying(:final surahNumber) => surahNumber,
      PlaybackPaused(:final surahNumber) => surahNumber,
      PlaybackLoading(:final surahNumber) => surahNumber,
      PlaybackFailed() => 0,
    };
    if (current <= 0) return null;
    final queue = _surahNumbers;
    final index = queue.indexOf(current);
    if (index >= 0) {
      final nextIndex = index + delta;
      return nextIndex < 0 || nextIndex >= queue.length
          ? null
          : queue[nextIndex];
    }
    final next = current + delta;
    if (next < kFirstSurahId || next > kSurahCount) return null;
    return next;
  }

  /// The end-of-track policy: repeat the surah or stop.
  Future<void> _onCompleted() async {
    if (isClosed || _externalAudioActive) return;
    final state = this.state;
    final current = switch (state) {
      PlaybackPlaying(:final surahNumber, :final surahName) => (
        number: surahNumber,
        name: surahName,
      ),
      PlaybackPaused(:final surahNumber, :final surahName) => (
        number: surahNumber,
        name: surahName,
      ),
      _ => null,
    };
    if (current == null || _rowId.isEmpty) {
      await stopAndReset();
      return;
    }
    if (_repeatMode == PlaybackRepeatMode.one) {
      await _start(_rowId, _reciterName, _server, current.number, current.name);
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
        appLog(
          'sleep timer pause failed',
          name: 'quran_yahdi/playback',
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (isClosed) return;
      _emit(state.toPaused(clearSleepTimer: true));
    } else if (state is PlaybackPaused) {
      _emit(state.copyWith(sleepTimer: null));
    }
  }

  void _bindStreams() {
    _playingSub ??= _service.playingStream().listen(
      _onPlayingChanged,
      onError: _onStreamError,
    );
    _positionSub ??= _service.positionStream().listen(
      _onPositionChanged,
      onError: _onStreamError,
    );
    _durationSub ??= _service.durationStream().listen(
      _onDurationChanged,
      onError: _onStreamError,
    );
    if (_service case final CompletingPlaybackService completing) {
      _completionSub ??= completing.completionStream().listen(
        (_) => unawaited(_onCompleted()),
        onError: _onStreamError,
      );
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    appLog(
      'playback stream error',
      name: 'quran_yahdi/playback',
      error: error,
      stackTrace: stackTrace,
    );
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
    _surahNumbers = const <int>[];
    _episode++;
    unawaited(_unbindStreams());
    if (!isClosed) _emit(const PlaybackState.initial());
  }

  void _onPlayingChanged(bool playing) {
    if (isClosed || _externalAudioActive) return;
    final state = this.state;
    if (playing && state is PlaybackLoading && state.reciterName != null) {
      _emit(
        state.toPlaying(
          duration: _lastDuration,
          speedOverride: _speed,
          repeatModeOverride: _repeatMode,
          sleepTimerOverride: _sleepTimerDuration,
        ),
      );
    } else if (playing && state is PlaybackPaused) {
      final controls = _controlsOf(state);
      _emit(
        state.toPlaying(
          speedOverride: controls.speed,
          repeatModeOverride: controls.repeatMode,
          sleepTimerOverride: controls.sleepTimer,
        ),
      );
    } else if (!playing && state is PlaybackPlaying) {
      _emit(state.toPaused());
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
      _emit(state.copyWith(position: position));
    } else if (state is PlaybackPaused) {
      _emit(state.copyWith(position: position));
    }
  }

  void _onDurationChanged(Duration? duration) {
    if (isClosed || _externalAudioActive || duration == null) return;
    _lastDuration = duration;
    final state = this.state;
    if (state is PlaybackPlaying) {
      _emit(state.copyWith(duration: duration));
    } else if (state is PlaybackPaused) {
      _emit(state.copyWith(duration: duration));
    }
  }
}
