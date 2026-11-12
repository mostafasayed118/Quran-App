import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_mapping.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/playback/playback_state.dart';

import 'support/fake_playback_service.dart';
import 'support/test_db.dart';

int? _number(PlaybackState state) => switch (state) {
      PlaybackPlaying(:final surahNumber) => surahNumber,
      PlaybackPaused(:final surahNumber) => surahNumber,
      PlaybackLoading(:final surahNumber) => surahNumber,
      _ => null,
    };

void main() {
  test('next/previous walk the reciter surah list, not 1..114', () async {
    final db = newTestDb();
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'قارئ',
            moshafName: 'حفص',
            server: 'https://server.example/mp3',
            surahList: '1,3,7',
            surahTotal: 3,
          ),
        );
    final row = (await ReciterRepository(db).byId('51-53'))!;
    final cubit = PlaybackCubit(
      service: FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(
        db,
        audioRootResolver: () async => Directory.systemTemp,
      ),
    );
    addTearDown(cubit.close);

    await cubit.playReciter(row.toInfo(), 1);
    expect(_number(cubit.state), 1);
    expect(cubit.hasNextSurah, isTrue);
    expect(cubit.hasPreviousSurah, isFalse);

    await cubit.nextSurah();
    expect(_number(cubit.state), 3,
        reason: 'surah 2 is not in this reciter\'s list');

    await cubit.nextSurah();
    expect(_number(cubit.state), 7);
    expect(cubit.hasNextSurah, isFalse);

    await cubit.previousSurah();
    expect(_number(cubit.state), 3);
    expect(cubit.hasPreviousSurah, isTrue);
  });

  test('an empty surah list keeps the 1..114 fallback', () async {
    final db = newTestDb();
    await db.into(db.reciters).insert(
          RecitersCompanion.insert(
            id: '51-53',
            reciterName: 'قارئ',
            moshafName: 'حفص',
            server: 'https://server.example/mp3',
            surahList: '',
            surahTotal: 114,
          ),
        );
    final row = (await ReciterRepository(db).byId('51-53'))!;
    final cubit = PlaybackCubit(
      service: FakePlaybackService(),
      reciters: ReciterRepository(db),
      downloader: AudioDownloader(
        db,
        audioRootResolver: () async => Directory.systemTemp,
      ),
    );
    addTearDown(cubit.close);

    await cubit.playReciter(row.toInfo(), 1);
    await cubit.nextSurah();

    expect(_number(cubit.state), 2);
  });
}
