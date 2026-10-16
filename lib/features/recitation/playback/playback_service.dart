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
