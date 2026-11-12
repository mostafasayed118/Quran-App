import 'dart:async';

import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';

import 'fake_playback_service.dart';

/// A playback double whose streams and call counts are driven by the test.
///
/// Extends the silent [FakePlaybackService] so the reader/downloads suites keep
/// the no-op base, while the cubit and mini-player suites get live controllers
/// without a second hand-written implementation.
class ControllablePlaybackService extends FakePlaybackService {
  final playing = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();

  final List<PlaybackSource> loaded = <PlaybackSource>[];
  Object? loadError;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;

  @override
  Stream<bool> playingStream() => playing.stream;

  @override
  Stream<Duration> positionStream() => positionCtrl.stream;

  @override
  Stream<Duration?> durationStream() => durationCtrl.stream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {
    final error = loadError;
    if (error != null) throw error;
    loaded.add(source);
  }

  @override
  Future<void> pause() async => pauseCount += 1;

  @override
  Future<void> resume() async => resumeCount += 1;

  @override
  Future<void> stop() async => stopCount += 1;
}
