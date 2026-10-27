import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../core/l10n/platform_localizations.dart';
import 'playback_service.dart';

/// Drops the seed a seeded stream replays to each new listener.
Stream<Duration?> withoutReplaySeed(Stream<Duration?> source) => source.skip(1);

class JustAudioPlaybackService
    implements
        PlaybackService,
        DisposablePlaybackService,
        CompletingPlaybackService {
  JustAudioPlaybackService([AudioPlayer? player])
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  /// The single 1 Hz position stream for this service.
  ///
  /// `createPositionStream` allocates a controller, a player-event
  /// subscription, and a timer per call and exposes no close API.
  late final Stream<Duration> _positionStream = _player.createPositionStream(
    minPeriod: const Duration(seconds: 1),
    maxPeriod: const Duration(seconds: 1),
  );

  @override
  Stream<bool> playingStream() =>
      _player.playerStateStream.map((s) => s.playing);

  @override
  Stream<Duration> positionStream() => _positionStream;

  @override
  Stream<Duration?> durationStream() =>
      withoutReplaySeed(_player.durationStream);

  @override
  Stream<void> completionStream() => _player.processingStateStream
      .where((s) => s == ProcessingState.completed)
      .map((_) {});

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {
    switch (source.kind) {
      case PlaybackSourceKind.file:
        final path = source.path;
        if (path == null) {
          throw StateError('file playback source without a path');
        }
        final file = File(path);
        await _player.setFilePath(
          file.path,
          tag: _mediaItem(id: file.path, source: source),
        );
      case PlaybackSourceKind.url:
        final uri = source.uri;
        if (uri == null) {
          throw StateError('url playback source without a uri');
        }
        final id = uri.toString();
        await _player.setUrl(
          id,
          tag: _mediaItem(id: id, source: source),
        );
    }
    // just_audio's play() future resolves on pause/stop/completion, not when
    // playback starts. Awaiting it here would block the cubit's loading state
    // for the whole track and let a later pause emit "playing".
    unawaited(_player.play().catchError((Object error, StackTrace stackTrace) {
      dev.log('playback play request failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
    }));
  }

  MediaItem _mediaItem({required String id, required PlaybackSource source}) {
    final appName = platformLocalizations().appName;
    return MediaItem(
      id: id,
      title: source.mediaTitle.isEmpty
          ? appName
          : '$appName — ${source.mediaTitle}',
      artist: source.artist.isEmpty ? null : source.artist,
    );
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() async {
    unawaited(_player.play().catchError((Object error, StackTrace stackTrace) {
      dev.log('playback resume request failed',
          name: 'quran_yahdi/playback', error: error, stackTrace: stackTrace);
    }));
  }

  @override
  Future<void> stop() => _player.stop();

  /// Releases the ExoPlayer instance, the audio focus and the platform
  /// media session. Without it the player is held for the whole process
  /// lifetime.
  @override
  Future<void> dispose() => _player.dispose();
}
