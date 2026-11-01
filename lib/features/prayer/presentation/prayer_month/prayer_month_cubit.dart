import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';

import 'prayer_month_state.dart';

/// Builds a month of prayer times from the selected city and the configured
/// [PrayerTimesPort].
class PrayerMonthCubit extends Cubit<PrayerMonthState> {
  /// Creates the cubit; [clock] is the time seam for the initial month.
  PrayerMonthCubit({
    required CitySource city,
    required PrayerTimesPort prayer,
    DateTime Function()? clock,
  })  : _city = city,
        _prayer = prayer,
        _month = _firstOfMonth((clock ?? DateTime.now)()),
        super(const PrayerMonthState.loading());

  final CitySource _city;
  final PrayerTimesPort _prayer;
  DateTime _month;

  /// Loads the initial month.
  Future<void> start() => _load(_month);

  /// Moves one month back.
  Future<void> previousMonth() =>
      _load(DateTime(_month.year, _month.month - 1));

  /// Moves one month forward.
  Future<void> nextMonth() => _load(DateTime(_month.year, _month.month + 1));

  Future<void> _load(DateTime month) async {
    _month = _firstOfMonth(month);
    if (!isClosed) emit(const PrayerMonthState.loading());
    try {
      final city = await _city.selectedCity();
      if (isClosed) return;
      final days = <PrayerMonthDay>[];
      if (city != null) {
        final count = DateTime(_month.year, _month.month + 1, 0).day;
        for (var day = 1; day <= count; day++) {
          final date = DateTime(_month.year, _month.month, day);
          final prayers = _prayer
              .today(city.coordinates, date)
              .where((prayer) => prayer.name != PrayerName.sunrise)
              .toList(growable: false);
          days.add(PrayerMonthDay(date: date, prayers: prayers));
        }
      }
      if (isClosed) return;
      emit(PrayerMonthState.ready(
        city: city,
        year: _month.year,
        month: _month.month,
        days: List<PrayerMonthDay>.unmodifiable(days),
      ));
    } on Object catch (error, stackTrace) {
      dev.log('prayer month load failed',
          name: 'quran_yahdi/prayer', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(const PrayerMonthState.failed());
    }
  }

  static DateTime _firstOfMonth(DateTime value) =>
      DateTime(value.year, value.month);
}
