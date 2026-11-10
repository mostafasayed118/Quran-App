import 'package:quran_yahdi/core/utils/app_log.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/city.dart';
import '../../../../core/domain/prayer_times.dart';
import '../../../../core/domain/ramadan_calendar.dart';
import '../domain/ramadan_times.dart';
import 'ramadan_state.dart';

/// The Ramadan timetable: the current (or next) Ramadan month, one row per
/// day, with the imsak and iftar derived from the configured prayer times.
class RamadanCubit extends Cubit<RamadanState> {
  /// Creates the cubit; [clock] is the time seam for tests.
  RamadanCubit({
    required CitySource city,
    required PrayerTimesPort prayer,
    required RamadanCalendar calendar,
    DateTime Function()? clock,
  })  : _city = city,
        _prayer = prayer,
        _calendar = calendar,
        _clock = clock ?? DateTime.now,
        super(const RamadanState.loading());

  final CitySource _city;
  final PrayerTimesPort _prayer;
  final RamadanCalendar _calendar;
  final DateTime Function() _clock;

  /// Builds the current Ramadan month, or the next one when today is after
  /// it. No city means a ready state with no rows (the screen shows the
  /// localized empty state).
  Future<void> start() async {
    try {
      final city = await _city.selectedCity();
      final now = _clock();
      final today = _calendar.hijriDate(now);
      final year = today.month <= 9 ? today.year : today.year + 1;
      final monthName = _calendar.monthName(year, 9);
      if (city == null) {
        if (!isClosed) {
          emit(RamadanState.ready(
            hijriYear: year,
            monthName: monthName,
            days: const <RamadanDay>[],
          ));
        }
        return;
      }
      final count = _calendar.daysInMonth(year, 9);
      final days = <RamadanDay>[];
      for (var day = 1; day <= count; day++) {
        final date = _calendar.gregorianDate(year, 9, day);
        final prayers = _prayer.today(city.coordinates, date);
        final times = ramadanTimesFor(
          fajr: _timeOf(prayers, PrayerName.fajr),
          maghrib: _timeOf(prayers, PrayerName.maghrib),
        );
        days.add(RamadanDay(
          hijriDay: day,
          date: date,
          imsak: times.imsak,
          iftar: times.iftar,
          isToday: _sameDay(date, now),
        ));
      }
      RamadanDay? todayRow;
      for (final day in days) {
        if (day.isToday) {
          todayRow = day;
          break;
        }
      }
      if (isClosed) return;
      emit(RamadanState.ready(
        hijriYear: year,
        monthName: monthName,
        days: List<RamadanDay>.unmodifiable(days),
        today: todayRow,
      ));
    } on Object catch (error, stackTrace) {
      appLog('ramadan load failed',
          name: 'quran_yahdi/ramadan', error: error, stackTrace: stackTrace);
      if (!isClosed) emit(const RamadanState.failed());
    }
  }

  static DateTime _timeOf(List<PrayerChoice> prayers, PrayerName name) =>
      prayers.firstWhere((prayer) => prayer.name == name).time;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
