import 'package:freezed_annotation/freezed_annotation.dart';

part 'ramadan_state.freezed.dart';

/// One day of the Ramadan timetable.
class RamadanDay {
  /// Creates a row.
  const RamadanDay({
    required this.hijriDay,
    required this.date,
    required this.imsak,
    required this.iftar,
    required this.isToday,
  });

  /// The Hijri day of the month (1..29/30).
  final int hijriDay;

  /// The Gregorian date of the row.
  final DateTime date;

  /// When the fast starts (Fajr minus the lead).
  final DateTime imsak;

  /// When the fast ends (Maghrib).
  final DateTime iftar;

  /// Whether this row is today in the device's time zone.
  final bool isToday;
}

@freezed
sealed class RamadanState with _$RamadanState {
  const factory RamadanState.loading() = RamadanLoading;

  const factory RamadanState.failed() = RamadanFailed;

  const factory RamadanState.ready({
    required int hijriYear,
    required String monthName,
    required List<RamadanDay> days,
    @Default(null) RamadanDay? today,
  }) = RamadanReady;
}
