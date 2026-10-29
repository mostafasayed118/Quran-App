import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_info_source.dart';
import 'package:quran_yahdi/features/recitation/domain/reciter_info.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

import 'support/test_db.dart';

/// Plain seam: no seek capability (the frozen doubles' shape).
class _PlainService implements PlaybackService {
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

/// Seam that also reports the seek capability.
class _SeekableService extends _PlainService
    implements SeekablePlaybackService {
  final List<Duration> seeks = <Duration>[];

  @override
  Future<void> seek(Duration position) async => seeks.add(position);
}

class _NoReciters implements ReciterInfoSource {
  @override
  Future<ReciterInfo?> defaultReciter() async => null;
}

PlaybackCubit _cubitWith(PlaybackService service) {
  final db = newTestDb();
  return PlaybackCubit(
    service: service,
    reciters: _NoReciters(),
    downloader: AudioDownloader(db,
        audioRootResolver: () async => throw StateError('unused')),
    backgroundActive: () => true,
  );
}

void main() {
  test('seek forwards to a service that exposes the capability', () async {
    final service = _SeekableService();
    final cubit = _cubitWith(service);
    addTearDown(cubit.close);

    await cubit.seek(const Duration(seconds: 42));

    expect(service.seeks, [const Duration(seconds: 42)]);
  });

  test('seek is a no-op on the plain seam (no capability)', () async {
    final cubit = _cubitWith(_PlainService());
    addTearDown(cubit.close);

    await cubit.seek(const Duration(seconds: 42));

    expect(cubit.state, isA<PlaybackLoading>());
    expect(cubit.state, isNot(isA<PlaybackFailed>()));
  });
}
