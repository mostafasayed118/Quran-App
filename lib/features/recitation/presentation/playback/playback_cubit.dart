import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/adhan_player.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../../../../core/domain/quran_limits.dart';
import '../../data/audio_downloader.dart';
import '../../data/reciter_info_source.dart';
import '../../data/reciter_repository.dart' show surahAudioUrl;
import '../../data/surah_name_source.dart';
import '../../domain/reciter_info.dart';
import '../../playback/background_init_guard.dart';
import '../../playback/playback_service.dart';
import 'playback_state.dart';

// The row-typed entry point lives in its own file so this surface never
// imports a drift row; it is re-exported for the frozen recitation doubles.
export '../../data/playback_row_entry.dart';

part 'playback_controls.dart';
part 'playback_queue.dart';

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
    SurahNameSource? surahNames,
  }) : _service = service,
       _reciters = reciters,
       _downloader = downloader,
       _surahNames = surahNames,
       _backgroundActive = backgroundActive ?? _probeBackgroundInit,
       super(const PlaybackState.initial()) {
    _adhanSub = adhanStates?.listen(_onAdhanState, onError: _onStreamError);
  }

  final PlaybackService _service;
  final ReciterInfoSource _reciters;
  final AudioDownloader _downloader;

  /// Optional catalog lookup for the track title on next/previous.
  final SurahNameSource? _surahNames;

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

  /// The surahs the current reciter serves, in catalog order. Empty falls
  /// back to the whole 1..114 range (old behaviour).
  List<int> _surahNumbers = const <int>[];

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

  /// The single `emit` bridge for the part files.
  ///
  /// `Cubit.emit` is `@protected`, so an extension on this cubit cannot call
  /// it; the class keeps the one legal call and the parts go through here.
  void _emit(PlaybackState next) => emit(next);

  /// Cancels every player subscription and forgets them.
  ///
  /// Lives in the class body (not the stream part) because the
  /// `cancel_subscriptions` lint only pairs a field's creation with a cancel
  /// it can see on the declaring class.
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

  /// Entity entry for the re-typed screens (ready states carry
  /// [ReciterInfo], never drift rows).
  ///
  /// [surahName] is the display name when the caller knows it; the player
  /// shows it instead of a bare number.
  Future<void> playReciter(
    ReciterInfo reciter,
    int surahNumber, {
    String surahName = '',
  }) async {
    _useQueue(reciter.surahList);
    final name = surahName.isNotEmpty
        ? surahName
        : await _resolveName(surahNumber);
    if (isClosed) return;
    await _start(
      reciter.id,
      reciter.reciterName,
      reciter.server,
      surahNumber,
      name,
    );
  }

  /// The Arabic name of [surahNumber], or an empty string when unavailable.
  Future<String> _resolveName(int surahNumber) async {
    final source = _surahNames;
    if (source == null) return '';
    try {
      final names = await source.surahNamesFor([surahNumber]);
      return names[surahNumber] ?? '';
    } on Object catch (error, stackTrace) {
      appLog(
        'surah name lookup failed',
        name: 'quran_yahdi/playback',
        error: error,
        stackTrace: stackTrace,
      );
      return '';
    }
  }

  /// Parses the reciter's comma-separated surah list into a queue.
  void _useQueue(String surahList) {
    final numbers = <int>[];
    for (final part in surahList.split(',')) {
      final number = int.tryParse(part.trim());
      if (number != null && number >= kFirstSurahId && number <= kSurahCount) {
        numbers.add(number);
      }
    }
    _surahNumbers = numbers;
  }

  Future<void> _start(
    String rowId,
    String reciterName,
    String server,
    int surahNumber,
    String surahName,
  ) async {
    if (isClosed) return;
    final episode = ++_episode;
    _lastDuration = Duration.zero;
    _reciterName = reciterName;
    _rowId = rowId;
    _server = server;
    _emit(
      PlaybackState.loading(
        reciterName: reciterName,
        surahNumber: surahNumber,
        surahName: surahName,
      ),
    );
    String? downloaded;
    try {
      downloaded = await _downloader.downloadedPath(rowId, surahNumber);
    } on Object catch (error, stackTrace) {
      // A registry read failure is not a playback failure: fall back to the
      // remote URL instead of leaving the state stuck in loading.
      appLog(
        'download lookup failed',
        name: 'quran_yahdi/playback',
        error: error,
        stackTrace: stackTrace,
      );
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
      _emit(
        state.toPlaying(
          duration: _lastDuration,
          speedOverride: _speed,
          repeatModeOverride: _repeatMode,
          sleepTimerOverride: _sleepTimerDuration,
        ),
      );
    } on Object catch (error, stackTrace) {
      appLog(
        'playback load failed',
        name: 'quran_yahdi/playback',
        error: error,
        stackTrace: stackTrace,
      );
      if (isClosed || episode != _episode) return;
      await _stopBestEffort();
      if (isClosed || episode != _episode) return;
      _emit(
        PlaybackState.failed(
          kind: _backgroundActive()
              ? PlaybackFailureKind.network
              : PlaybackFailureKind.backgroundUnavailable,
        ),
      );
    }
  }

  /// Plays the default reciter's audio for [surahNumber].
  ///
  /// A missing default reciter fails with [PlaybackFailureKind.noReciters];
  /// a lookup error fails with [PlaybackFailureKind.network].
  Future<void> playDefaultForSurah(
    int surahNumber, {
    String surahName = '',
  }) async {
    final episode = ++_episode;
    final ReciterInfo? reciter;
    try {
      reciter = await _reciters.defaultReciter();
    } on Object catch (error, stackTrace) {
      appLog(
        'reciter lookup failed',
        name: 'quran_yahdi/playback',
        error: error,
        stackTrace: stackTrace,
      );
      if (isClosed || episode != _episode) return;
      await _stopBestEffort();
      if (isClosed || episode != _episode) return;
      _emit(const PlaybackState.failed(kind: PlaybackFailureKind.network));
      return;
    }
    if (isClosed || episode != _episode) return;
    if (reciter == null) {
      await _stopBestEffort();
      if (isClosed || episode != _episode) return;
      _emit(const PlaybackState.failed(kind: PlaybackFailureKind.noReciters));
      return;
    }
    await playReciter(reciter, surahNumber, surahName: surahName);
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
    _surahNumbers = const <int>[];
    final episode = ++_episode;
    try {
      await _service.stop();
    } on Object catch (error, stackTrace) {
      appLog(
        'stop failed',
        name: 'quran_yahdi/playback',
        error: error,
        stackTrace: stackTrace,
      );
    }
    // A newer play (or stop) superseded this one: its streams must stay bound.
    if (isClosed || episode != _episode) return;
    await _unbindStreams();
    if (isClosed) return;
    _emit(const PlaybackState.initial());
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
}
