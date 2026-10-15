import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';

import 'playback_service.dart';

class JustAudioPlaybackService implements PlaybackService {
  JustAudioPlaybackService([AudioPlayer? player]) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<bool> playingStream() => _player.playerStateStream.map((s) => s.playing);

  @override
  Stream<Duration> positionStream() => _player.positionStream;

  @override
  Stream<Duration?> durationStream() => _player.durationStream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {
    switch (source.kind) {
      case PlaybackSourceKind.file:
        final file = File(source.path!);
        await _player.setFilePath(file.path);
      case PlaybackSourceKind.url:
        await _player.setUrl(source.uri!.toString());
    }
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.play();

  @override
  Future<void> stop() => _player.stop();
}
