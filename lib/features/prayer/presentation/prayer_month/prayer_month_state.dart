import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/city.dart';
import '../../../../core/domain/prayer_times.dart';

part 'prayer_month_state.freezed.dart';

/// One calendar day in the monthly timetable.
class PrayerMonthDay {
  /// Creates a day with its five prayers (sunrise is omitted).
  const PrayerMonthDay({required this.date, required this.prayers});

  /// The local calendar date.
  final DateTime date;

  /// The five prayer times, in calendar order.
  final List<PrayerChoice> prayers;
}

/// The monthly timetable state.
@freezed
sealed class PrayerMonthState with _$PrayerMonthState {
  /// The month is being computed.
  const factory PrayerMonthState.loading() = PrayerMonthLoading;

  /// The city lookup or the calculation failed.
  const factory PrayerMonthState.failed() = PrayerMonthFailed;

  /// A month is ready; [days] is empty when no city is selected.
  const factory PrayerMonthState.ready({
    @Default(null) City? city,
    required int year,
    required int month,
    @Default(<PrayerMonthDay>[]) List<PrayerMonthDay> days,
  }) = PrayerMonthReady;
}
