import 'dart:async';

enum PlaybackSourceKind { file, url }

class PlaybackSource {
  const PlaybackSource.file(this.path)
      : kind = PlaybackSourceKind.file,
        uri = null;

  const PlaybackSource.url(this.uri)
      : kind = PlaybackSourceKind.url,
        path = null;

  final PlaybackSourceKind kind;
  final String? path;
  final Uri? uri;
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
