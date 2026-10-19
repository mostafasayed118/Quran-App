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

class FakePlaybackService implements PlaybackService {
  final playing = StreamController<bool>.broadcast();
  final positionCtrl = StreamController<Duration>.broadcast();
  final durationCtrl = StreamController<Duration?>.broadcast();

  final List<PlaybackSource> loaded = <PlaybackSource>[];

  @override
  Stream<bool> playingStream() => playing.stream;

  @override
  Stream<Duration> positionStream() => positionCtrl.stream;

  @override
  Stream<Duration?> durationStream() => durationCtrl.stream;

  @override
  Future<void> loadAndPlay(PlaybackSource source) async => loaded.add(source);

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  late AppDatabase db;
  late Directory tempRoot;
  late FakePlaybackService fake;
  late PlaybackCubit cubit;

  setUp(() async {
    db = newTestDb();
    tempRoot = await Directory.systemTemp.createTemp('qy_mini_player_test');
    fake = FakePlaybackService();
    cubit = PlaybackCubit(
      service: fake,
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(db, audioRootResolver: () async => tempRoot),
    );
  });

  tearDown(() async {
    await cubit.close();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await pumpAppHost(
      tester,
      wrap: (app) => MultiBlocProvider(
        providers: [
          BlocProvider<PlaybackCubit>.value(value: cubit),
        ],
        child: app,
      ),
      home: const Scaffold(bottomSheet: MiniPlayerBar()),
      settle: false,
    );
  }

  Future<void> seedRow() async {
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
  }

  testWidgets('idle state renders nothing', (tester) async {
    await pumpHost(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets(
      'playing state shows names, progress, and pause→resume flips the icon',
      (tester) async {
    await seedRow();
    final row = (await ReciterRepository(db).byId('51-53'))!;
    await pumpHost(tester);
    await tester.pumpAndSettle();

    await cubit.playSurah(row, 1);
    fake.durationCtrl.add(const Duration(minutes: 6));
    fake.positionCtrl.add(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.textContaining('عبدالباسط عبدالصمد'), findsOneWidget);
    expect(find.text('سورة ١'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byTooltip('إيقاف مؤقت'), findsOneWidget);

    await tester.tap(find.byTooltip('إيقاف مؤقت'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('تشغيل'), findsOneWidget);
    expect(find.byTooltip('إيقاف مؤقت'), findsNothing);
  });
}
