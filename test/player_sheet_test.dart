import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_info_source.dart';
import 'package:quran_yahdi/features/recitation/domain/reciter_info.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/player_sheet.dart';

import 'support/host.dart';
import 'support/test_db.dart';

class _OneReciter implements ReciterInfoSource {
  @override
  Future<ReciterInfo?> defaultReciter() async => const ReciterInfo(
        id: '1-1',
        reciterName: 'القارئ',
        moshafName: 'حفص',
        server: 'https://server.example/mp3',
        surahList: '1',
        surahTotal: 114,
      );
}

class _SpyPlaybackCubit extends PlaybackCubit {
  _SpyPlaybackCubit({
    required super.service,
    required super.reciters,
    required super.downloader,
    super.backgroundActive,
  });

  int stops = 0;

  @override
  Future<void> stopAndReset() async {
    stops++;
    emit(const PlaybackState.initial());
  }
}

class _FakeService implements PlaybackService, SeekablePlaybackService {
  final playingCtrl = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();
  final seekCalls = <Duration>[];
  int stopCount = 0;

  @override
  Stream<bool> playingStream() => playingCtrl.stream;

  @override
  Stream<Duration> positionStream() => positionCtrl.stream;

  @override
  Stream<Duration?> durationStream() => durationCtrl.stream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> seek(Duration position) async => seekCalls.add(position);
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late _FakeService service;
  late PlaybackCubit cubit;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_player_sheet');
    service = _FakeService();
    cubit = PlaybackCubit(
      service: service,
      reciters: _OneReciter(),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => true,
    );
  });

  tearDown(() async {
    await cubit.close();
    await service.playingCtrl.close();
    await service.positionCtrl.close();
    await service.durationCtrl.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    await db.close();
  });

  Future<void> openSheet(
    WidgetTester tester,
    PlaybackCubit target, {
    Duration duration = const Duration(minutes: 2),
  }) async {
    await target.playReciter(
      const ReciterInfo(
        id: '1-1',
        reciterName: 'القارئ',
        moshafName: 'حفص',
        server: 'https://server.example/mp3',
        surahList: '1',
        surahTotal: 114,
      ),
      1,
      surahName: 'الفاتحة',
    );
    await pumpAppHost(
      tester,
      settle: false,
      home: BlocProvider<PlaybackCubit>.value(
        value: target,
        child: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showPlayerSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    service.durationCtrl.add(duration);
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('the sheet shows the track and seeks through the cubit',
      (tester) async {
    await openSheet(tester, cubit);

    expect(find.text('الفاتحة'), findsOneWidget);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.max, 120000);
    slider.onChangeEnd!(60000);
    await tester.pump();

    expect(service.seekCalls, [const Duration(minutes: 1)]);
  });

  testWidgets('stop closes the sheet once and leaves the underlying route',
      (tester) async {
    final spy = _SpyPlaybackCubit(
      service: service,
      reciters: _OneReciter(),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
      backgroundActive: () => true,
    );
    addTearDown(spy.close);
    await openSheet(tester, spy);

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(spy.stops, 1);
    expect(find.byIcon(Icons.stop), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('the sheet clock includes hours for long tracks', (tester) async {
    await openSheet(
      tester,
      cubit,
      duration: const Duration(hours: 2, minutes: 3, seconds: 4),
    );

    expect(find.text('٢:٠٣:٠٤'), findsOneWidget);
  });
}
