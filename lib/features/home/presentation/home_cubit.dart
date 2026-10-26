import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/last_read.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';

import 'home_state.dart';

/// The home screen's two cards: the last-read ayah and the next prayer.
class HomeCubit extends Cubit<HomeState> {
  /// Creates the cubit; the constructor is side-effect free and does no
  /// work — [start] performs the first load.
  HomeCubit({
    required LastReadMarker lastRead,
    required AyahLookup ayahs,
    required PrayerTimesPort prayer,
    required CitySource city,
  })  : _lastRead = lastRead,
        _ayahs = ayahs,
        _prayer = prayer,
        _city = city,
        super(const HomeState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() => reload();

  final LastReadMarker _lastRead;
  final AyahLookup _ayahs;
  final PrayerTimesPort _prayer;
  final CitySource _city;

  /// Loads both cards and emits the ready state.
  ///
  /// The two reads are independent and run concurrently; the first failure
  /// wins and emits [HomeState.failed] (the other chain is consumed, never
  /// an unhandled async error).
  Future<void> reload() async {
    try {
      // The two cards are independent. The LIST form of Future.wait completes
      // with the first error and consumes the rest, so a second failing chain
      // can never surface as an unhandled async error.
      final results = await Future.wait<Object?>([
        _loadLastReadCard(),
        _loadNextPrayerCard(),
      ]);
      final lastReadCard = results[0] as LastReadCard?;
      final nextPrayerCard = results[1] as NextPrayerCard?;
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
    final ayah = await _ayahs.ayahRefById(ayahId);
    if (ayah == null) return null;
    final surah = await _ayahs.surahRefById(ayah.surahId);
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
