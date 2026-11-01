import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/quran/data/ayah_source.dart';
import 'package:quran_yahdi/features/quran/data/last_read_source.dart';
import 'package:quran_yahdi/features/quran/data/reader_settings_source.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/reader/reader_state.dart';

class _Ayahs implements AyahSource {
  @override
  Future<List<Ayah>> surahAyahs(int surahId) async => const [
        Ayah(
          id: 1,
          surahId: 1,
          numberInSurah: 1,
          juz: 1,
          page: 1,
          textUthmani: 'بسم الله',
          textImlaei: 'بسم الله',
          sajda: false,
        ),
      ];

  @override
  Future<Surah?> surahById(int surahId) async => const Surah(
        id: 1,
        nameAr: 'الفاتحة',
        nameEn: 'Al-Fatiha',
        revelationType: 'makki',
        ayahCount: 7,
        pagesStart: 1,
        pagesEnd: 1,
      );

  @override
  Stream<Set<int>> watchBookmarkedIds() => Stream.value(const <int>{});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LastRead implements LastReadSource {
  @override
  Future<int?> loadAyahId() async => null;

  @override
  Future<void> saveAyahId(int ayahId) async {}
}

class _Settings implements ReaderSettingsSource {
  double scale = 1;

  @override
  Future<double> loadFontScale() async => scale;

  @override
  Future<void> saveFontScale(double value) async {
    scale = value;
  }
}

void main() {
  test('the reader clamps and persists the font scale', () async {
    final settings = _Settings();
    final cubit = ReaderCubit(
      ayahRepository: _Ayahs(),
      lastReadRepository: _LastRead(),
      surahId: 1,
      initialAyah: 1,
      settings: settings,
    );
    addTearDown(cubit.close);

    await cubit.start();
    expect(cubit.state, isA<ReaderReady>());
    expect((cubit.state as ReaderReady).fontScale, 1);

    await cubit.setFontScale(1.5);
    expect((cubit.state as ReaderReady).fontScale, 1.5);
    expect(settings.scale, 1.5);

    await cubit.setFontScale(0.2);
    expect((cubit.state as ReaderReady).fontScale, 0.8);
    expect(settings.scale, 0.8);

    await cubit.setFontScale(3);
    expect((cubit.state as ReaderReady).fontScale, 2);
    expect(settings.scale, 2);
  });
}
