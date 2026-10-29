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

  /// Issues the load and the play request.
  ///
  /// The returned future completes when the request has been issued; it must
  /// NOT wait for playback to pause, stop, or finish.
  Future<void> loadAndPlay(PlaybackSource source);
  Future<void> pause();

  /// Issues the resume request; completes when issued, not when playback ends.
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

/// Optional capability: a playback service that can seek inside the loaded
/// track.
///
/// Kept separate from [PlaybackService] for the same reason as
/// [DisposablePlaybackService]: the frozen test doubles implement the plain
/// seam, and adding a member there would break them.
abstract interface class SeekablePlaybackService {
  /// Moves the playhead to [position].
  Future<void> seek(Duration position);
}

/// Optional capability: a playback service that reports when the loaded
/// track reaches its end.
///
/// Kept separate from [PlaybackService] for the same reason as
/// [DisposablePlaybackService]: the frozen test doubles implement the plain
/// seam, and adding a member there would break them.
abstract interface class CompletingPlaybackService {
  /// Emits one event each time the current track completes.
  Stream<void> completionStream();
}
