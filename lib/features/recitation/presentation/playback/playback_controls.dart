part of 'playback_cubit.dart';

extension PlaybackControls on PlaybackCubit {
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
        appLog(
          'speed change failed',
          name: 'quran_yahdi/playback',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    _emitControls();
  }

  /// Advances to the next speed in [speeds].
  Future<void> cycleSpeed() {
    final index = PlaybackCubit.speeds.indexOf(_speed);
    final next = PlaybackCubit
        .speeds[(index < 0 ? 0 : index + 1) % PlaybackCubit.speeds.length];
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
        appLog(
          'repeat change failed',
          name: 'quran_yahdi/playback',
          error: error,
          stackTrace: stackTrace,
        );
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
        appLog(
          'seek failed',
          name: 'quran_yahdi/playback',
          error: error,
          stackTrace: stackTrace,
        );
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
        appLog(
          'pause failed',
          name: 'quran_yahdi/playback',
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }
      if (isClosed || episode != _episode) return;
      _emit(state.toPaused());
    } else if (state is PlaybackPaused) {
      try {
        await _service.resume();
      } on Object catch (error, stackTrace) {
        // Keep the paused state: resume did not take effect.
        appLog(
          'resume failed',
          name: 'quran_yahdi/playback',
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }
      if (isClosed || episode != _episode) return;
      _emit(state.toPlaying());
    }
  }

  ({double speed, PlaybackRepeatMode repeatMode, Duration? sleepTimer})
  _controlsOf(PlaybackState state) => switch (state) {
    PlaybackPlaying(:final speed, :final repeatMode, :final sleepTimer) => (
      speed: speed,
      repeatMode: repeatMode,
      sleepTimer: sleepTimer,
    ),
    PlaybackPaused(:final speed, :final repeatMode, :final sleepTimer) => (
      speed: speed,
      repeatMode: repeatMode,
      sleepTimer: sleepTimer,
    ),
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
      _emit(
        state.copyWith(
          speed: _speed,
          repeatMode: _repeatMode,
          sleepTimer: _sleepTimerDuration,
        ),
      );
    } else if (state is PlaybackPaused) {
      _emit(
        state.copyWith(
          speed: _speed,
          repeatMode: _repeatMode,
          sleepTimer: _sleepTimerDuration,
        ),
      );
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
      appLog(
        'playback stop failed',
        name: 'quran_yahdi/playback',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
