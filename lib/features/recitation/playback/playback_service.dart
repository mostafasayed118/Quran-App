import 'dart:async';

enum PlaybackSourceKind { file, url }

class PlaybackSource {
  const PlaybackSource.file(this.path, {this.mediaTitle = '', this.artist = ''})
      : kind = PlaybackSourceKind.file,
        uri = null;

  const PlaybackSource.url(this.uri, {this.mediaTitle = '', this.artist = ''})
      : kind = PlaybackSourceKind.url,
        path = null;

  final PlaybackSourceKind kind;
  final String? path;
  final Uri? uri;
  final String mediaTitle;
  final String artist;
}

abstract interface class PlaybackService {
  Stream<bool> playingStream();
  Stream<Duration> positionStream();
  Stream<Duration?> durationStream();
  Future<void> loadAndPlay(PlaybackSource source);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
}

/// Optional capability: a playback service that owns platform resources (the
/// ExoPlayer instance, the audio focus, the platform media session).
///
/// It is a SEPARATE interface on purpose: [PlaybackService] is implemented by
/// the frozen test doubles, so adding a member to it would break them. The
/// cubit disposes the service only when it implements this capability.
abstract interface class DisposablePlaybackService {
  /// Releases the platform resources. Safe to call once.
  Future<void> dispose();
}
