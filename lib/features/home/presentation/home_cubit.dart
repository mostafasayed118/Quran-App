import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/ayah_lookup.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/last_read.dart';
import 'package:quran_yahdi/core/domain/prayer_config.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/l10n/app_localizations_digits.dart';
import 'package:quran_yahdi/core/l10n/platform_localizations.dart';
import 'package:quran_yahdi/core/l10n/prayer_names.dart';
import 'package:quran_yahdi/core/platform/home_widget_updater.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';
import 'package:quran_yahdi/core/utils/arabic_numbers.dart';

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
    Stream<PrayerConfig>? configChanges,
    HomeWidgetUpdater? widgetUpdater,
  })  : _lastRead = lastRead,
        _ayahs = ayahs,
        _prayer = prayer,
        _city = city,
        _configChanges = configChanges,
        _widgetUpdater = widgetUpdater,
        super(const HomeState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() async {
    final changes = _configChanges;
    if (changes != null) {
      _configSub ??= changes.listen((_) {
        if (!isClosed) unawaited(reload());
      });
    }
    await reload();
  }

  final LastReadMarker _lastRead;
  final AyahLookup _ayahs;
  final PrayerTimesPort _prayer;
  final CitySource _city;
  final Stream<PrayerConfig>? _configChanges;
  final HomeWidgetUpdater? _widgetUpdater;
  StreamSubscription<PrayerConfig>? _configSub;

  /// Monotonic token: only the newest [reload] may emit, so a slow older
  /// load can never overwrite the result of a newer one.
  int _reloadSeq = 0;

  /// Wakes the card when the shown prayer time passes; a Home screen left
  /// open must not keep advertising a past prayer as "next".
  Timer? _nextPrayerRefresh;

  /// Loads both cards and emits the ready state.
  ///
  /// The two reads are independent and run concurrently; the first failure
  /// wins and emits [HomeState.failed] (the other chain is consumed, never
  /// an unhandled async error).
  Future<void> reload() async {
    final seq = ++_reloadSeq;
    _nextPrayerRefresh?.cancel();
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
      if (isClosed || seq != _reloadSeq) return;
      emit(HomeState.ready(
        lastRead: lastReadCard,
        nextPrayer: nextPrayerCard,
      ));
      await _syncWidget(nextPrayerCard);
      _scheduleNextPrayerRefresh(nextPrayerCard);
    } on Object catch (error, stackTrace) {
      appLog('home load failed',
          name: 'quran_yahdi/home', error: error, stackTrace: stackTrace);
      if (isClosed || seq != _reloadSeq) return;
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
    return (
      name: next.name,
      time: next.time,
      cityName: selected.nameAr,
    );
  }

  /// Mirrors the next prayer into the Android home-screen widget.
  ///
  /// Best-effort: a missing card or updater is a no-op, and a platform failure
  /// is logged instead of failing the home load.
  Future<void> _syncWidget(NextPrayerCard? card) async {
    final updater = _widgetUpdater;
    if (card == null || updater == null) return;
    final loc = platformLocalizations();
    try {
      await updater.update(
        appName: loc.appName,
        label: loc.nextPrayer,
        prayer: card.name.label(loc),
        time: formatHm(card.time, arabicIndic: loc.usesArabicIndicDigits),
        city: card.cityName,
      );
    } on Object catch (error, stackTrace) {
      appLog('home widget sync failed',
          name: 'quran_yahdi/home', error: error, stackTrace: stackTrace);
    }
  }

  void _scheduleNextPrayerRefresh(NextPrayerCard? card) {
    _nextPrayerRefresh?.cancel();
    if (card == null) return;
    final delay = card.time.difference(DateTime.now());
    if (delay.isNegative) return;
    _nextPrayerRefresh = Timer(
      delay + const Duration(seconds: 1),
      () {
        if (!isClosed) unawaited(reload());
      },
    );
  }

  @override
  Future<void> close() async {
    await _configSub?.cancel();
    _nextPrayerRefresh?.cancel();
    return super.close();
  }
}
