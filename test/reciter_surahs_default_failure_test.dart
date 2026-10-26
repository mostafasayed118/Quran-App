import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/audio_downloader.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_source.dart';
import 'package:quran_yahdi/features/recitation/presentation/downloads/downloads_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciter_surahs/reciter_surahs_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciter_surahs/reciter_surahs_state.dart';

import 'support/test_db.dart';

const ReciterRow _row = ReciterRow(
  id: '51-53',
  reciterName: 'عبدالباسط عبدالصمد',
  moshafName: 'حفص مرتل',
  server: 'https://server.example/mp3',
  surahList: '1',
  surahTotal: 114,
);

/// Reciter seam: one known row, an optional failing moshaf write, and
/// instrumentation for the two surah read calls.
class _FakeReciters implements ReciterSource {
  _FakeReciters({this.failSelect = false});

  final bool failSelect;
  bool selectAttempted = false;
  bool namesFinished = false;
  bool teasersStartedAfterNamesFinished = false;

  @override
  Future<void> refreshFromApi() async {}

  @override
  Stream<List<ReciterRow>> watchAll() => const Stream<List<ReciterRow>>.empty();

  @override
  Future<ReciterRow?> byId(String rowId) async => _row;

  @override
  Future<void> selectMoshaf(String rowId) async {
    selectAttempted = true;
    if (failSelect) throw StateError('moshaf write failed');
  }

  @override
  Future<String?> loadSelectedMoshaf() async => null;

  @override
  Future<Map<int, String>> surahNamesFor(List<int> surahIds) async {
    await Future<void>.delayed(Duration.zero);
    namesFinished = true;
    return {for (final id in surahIds) id: 'الفاتحة'};
  }

  @override
  Future<Map<int, String>> ayahTeasersFor(List<int> surahIds) async {
    teasersStartedAfterNamesFinished = namesFinished;
    return {for (final id in surahIds) id: 'الم'};
  }
}

/// Catalog seam for the downloads cubit (no catalog reads happen here).
class _StaticReciters extends ReciterRepository {
  _StaticReciters(super.db);

  @override
  Future<ReciterRow?> byId(String rowId) async => _row;
}

void main() {
  late AppDatabase db;
  late DownloadsCubit downloads;

  setUp(() {
    db = newTestDb();
    downloads = DownloadsCubit(
      downloader: AudioDownloader(db),
      reciters: _StaticReciters(db),
    );
    addTearDown(downloads.close);
  });

  test('setAsDefault completes when the moshaf write throws', () async {
    final reciters = _FakeReciters(failSelect: true);
    final cubit = ReciterSurahsCubit(
      reciters: reciters,
      downloads: downloads,
      rowId: '51-53',
    );
    addTearDown(cubit.close);
    await cubit.start().timeout(const Duration(seconds: 10));
    expect(cubit.state, isA<ReciterSurahsReady>());

    await cubit.setAsDefault().timeout(const Duration(seconds: 10));

    expect(reciters.selectAttempted, isTrue);
    expect(cubit.state, isA<ReciterSurahsReady>(),
        reason: 'setAsDefault must not emit a state change');
  });

  test('surah names and teasers are read concurrently', () async {
    final reciters = _FakeReciters();
    final cubit = ReciterSurahsCubit(
      reciters: reciters,
      downloads: downloads,
      rowId: '51-53',
    );
    addTearDown(cubit.close);
    await cubit.start().timeout(const Duration(seconds: 10));
    final ready = cubit.state as ReciterSurahsReady;

    expect(ready.names, {1: 'الفاتحة'});
    expect(ready.previews, {1: 'الم'});
    expect(reciters.teasersStartedAfterNamesFinished, isFalse,
        reason: 'both reads must be in flight together (Future.wait)');
  });
}
