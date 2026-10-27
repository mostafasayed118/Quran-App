import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/playback/playback_service.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/mini_player_bar.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';

import 'support/host.dart';
import 'support/test_db.dart';

class _FakePlaybackService implements PlaybackService {
  final playing = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();

  @override
  Stream<bool> playingStream() => playing.stream;

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
  Future<void> stop() async {}
}

const double kHeight = 800;
const double kInset = 48;

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late _FakePlaybackService fake;
  late PlaybackCubit cubit;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_mini_inset_test');
    fake = _FakePlaybackService();
    cubit = PlaybackCubit(
      service: fake,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
    );
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'عبدالباسط عبدالصمد',
            moshafName: 'حفص مرتل',
            server: 'https://server.example/mp3',
            surahList: '1,2',
            surahTotal: 114,
          ),
        );
  });

  tearDown(() async {
    await cubit.close();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  testWidgets('the playing strip clears the nav bar and paints behind it',
      (tester) async {
    tester.view.physicalSize = const Size(400, kHeight);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: kInset);
    tester.view.viewPadding = const FakeViewPadding(bottom: kInset);
    addTearDown(tester.view.reset);

    await pumpAppHost(
      tester,
      wrap: (app) =>
          BlocProvider<PlaybackCubit>.value(value: cubit, child: app),
      home: const Scaffold(bottomSheet: MiniPlayerBar()),
      settle: false,
    );
    await tester.pumpAndSettle();

    final row = (await ReciterRepository(db).byId('51-53'))!;
    await cubit.playSurah(row, 1);
    fake.durationCtrl.add(const Duration(minutes: 6));
    fake.positionCtrl.add(Duration.zero);
    await tester.pumpAndSettle();

    final stopButton = tester.getRect(find.byTooltip('إيقاف'));
    expect(stopButton.bottom, lessThanOrEqualTo(kHeight - kInset));

    final strip = tester.getRect(
      find.byWidgetPredicate((w) => w is Material && w.elevation == 4),
    );
    expect(strip.bottom, kHeight);
  });
}
