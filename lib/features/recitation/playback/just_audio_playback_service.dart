import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../core/l10n/platform_localizations.dart';
import 'playback_service.dart';

class JustAudioPlaybackService
    implements PlaybackService, DisposablePlaybackService {
  JustAudioPlaybackService([AudioPlayer? player])
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<bool> playingStream() =>
      _player.playerStateStream.map((s) => s.playing);

  @override
  Stream<Duration> positionStream() => _player.positionStream;

  @override
  Stream<Duration?> durationStream() => _player.durationStream;

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
    await _player.play();
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
  Future<void> resume() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  /// Releases the ExoPlayer instance, the audio focus and the platform
  /// media session. Without it the player is held for the whole process
  /// lifetime.
  @override
  Future<void> dispose() => _player.dispose();
}
