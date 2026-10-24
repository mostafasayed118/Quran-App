import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_info_source.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart'
    show surahAudioUrl;
import 'package:quran_yahdi/features/recitation/domain/reciter_info.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

import 'support/test_db.dart';

/// Download registry whose lookup always fails, to pin the URL fallback.
class _ThrowingLookupDownloader extends AudioDownloader {
  _ThrowingLookupDownloader(super.db);

  @override
  Future<String?> downloadedPath(String rowId, int surahNumber) async {
    throw StateError('registry read failed');
  }
}

/// Playback service that records what the cubit asked it to load.
class _RecordingService implements PlaybackService {
  final List<PlaybackSource> loaded = <PlaybackSource>[];

  @override
  Stream<bool> playingStream() => const Stream<bool>.empty();

  @override
  Stream<Duration> positionStream() => const Stream<Duration>.empty();

  @override
  Stream<Duration?> durationStream() => const Stream<Duration?>.empty();

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {
    loaded.add(source);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}

class _NoReciters implements ReciterInfoSource {
  @override
  Future<ReciterInfo?> defaultReciter() async => null;
}

const ReciterInfo _reciter = ReciterInfo(
  id: '51-53',
  reciterName: 'عبدالباسط عبدالصمد',
  moshafName: 'حفص مرتل',
  server: 'https://server.example/mp3',
  surahList: '1',
  surahTotal: 114,
);

void main() {
  test('a failing download lookup falls back to the URL and reaches playing',
      () async {
    final db = newTestDb();
    final service = _RecordingService();
    final cubit = PlaybackCubit(
      service: service,
      reciters: _NoReciters(),
      downloader: _ThrowingLookupDownloader(db),
      backgroundActive: () => true,
    );
    addTearDown(cubit.close);

    await cubit.playReciter(_reciter, 1).timeout(const Duration(seconds: 10));

    expect(cubit.state, isA<PlaybackPlaying>(),
        reason: 'a registry failure must not leave the player loading');
    expect(service.loaded, hasLength(1));
    expect(service.loaded.single.kind, PlaybackSourceKind.url);
    expect(
      service.loaded.single.uri.toString(),
      surahAudioUrl(_reciter.server, 1),
    );
  });
}
