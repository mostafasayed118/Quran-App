import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../prayer/data/city_repository.dart';
import '../../prayer/data/prayer_time_service.dart';
import '../../quran/data/ayah_repository.dart';
import '../../quran/data/last_read_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required LastReadRepository lastRead,
    required AyahRepository ayahs,
    required PrayerTimeService prayer,
    required CityRepository city,
  })  : _lastRead = lastRead,
        _ayahs = ayahs,
        _prayer = prayer,
        _city = city,
        super(const HomeState.loading()) {
    unawaited(reload());
  }

  final LastReadRepository _lastRead;
  final AyahRepository _ayahs;
  final PrayerTimeService _prayer;
  final CityRepository _city;

  Future<void> reload() async {
    try {
      final lastReadCard = await _loadLastReadCard();
      final nextPrayerCard = await _loadNextPrayerCard();
      if (isClosed) return;
      emit(HomeState.ready(
        lastRead: lastReadCard,
        nextPrayer: nextPrayerCard,
      ));
    } on Object catch (error, stackTrace) {
      dev.log('home load failed',
          name: 'quran_yahdi/home', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const HomeState.failed());
    }
  }

  Future<LastReadCard?> _loadLastReadCard() async {
    final ayahId = await _lastRead.loadAyahId();
    if (ayahId == null) return null;
    final ayah = await _ayahs.ayahById(ayahId);
    if (ayah == null) return null;
    final surah = await _ayahs.surahById(ayah.surahId);
    if (surah == null) return null;
    return (
      surahId: ayah.surahId,
      surahName: surah.nameAr,
      ayahNumber: ayah.numberInSurah,
    );
  }

  Future<NextPrayerCard?> _loadNextPrayerCard() async {
    final selected = await _city.selectedCity();
    if (selected == null) return null;
    final next = _prayer.nextPrayer(selected.coordinates, DateTime.now());
    return (name: next.name, time: next.time);
  }
}
