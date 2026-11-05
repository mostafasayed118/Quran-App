import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';

/// A silent playback double: every stream is empty and every call completes.
///
/// The reader/downloads tests used to carry 12 copies of this class; the two
/// tests that need live controllers extend it and override the streams.
class FakePlaybackService implements PlaybackService {
  @override
  Stream<bool> playingStream() => const Stream<bool>.empty();

  @override
  Stream<Duration> positionStream() => const Stream<Duration>.empty();

  @override
  Stream<Duration?> durationStream() => const Stream<Duration?>.empty();

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}
