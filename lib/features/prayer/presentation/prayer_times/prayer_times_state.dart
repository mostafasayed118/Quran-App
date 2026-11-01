import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/city_repository.dart';
import '../../data/prayer_time_service.dart';

part 'prayer_times_state.freezed.dart';

class PrayerEntry {
  const PrayerEntry({
    required this.name,
    required this.time,
    required this.isNext,
  });

  final PrayerName name;
  final DateTime time;
  final bool isNext;
}

@freezed
sealed class PrayerTimesState with _$PrayerTimesState {
  const factory PrayerTimesState.loading() = PrayerTimesLoading;

  const factory PrayerTimesState.failed() = PrayerTimesFailed;

  const factory PrayerTimesState.ready({
    City? city,
    @Default(<PrayerEntry>[]) List<PrayerEntry> entries,
    @Default(null) Duration? remaining,

    /// The first prayer after today's list is over (after Isha this is
    /// tomorrow's Fajr). Null while a today entry is still ahead.
    ///
    /// Carried separately instead of appended to [entries] because the panel
    /// must stay "today's six times"; the screen renders this as a footer.
    @Default(null) PrayerName? nextTomorrowName,
    @Default(null) DateTime? nextTomorrowTime,

    /// Countdown to [nextTomorrowTime]. Kept apart from [remaining], which
    /// stays null once no row is next — the frozen contract the row subtitle
    /// and the ticker tests rely on.
    @Default(null) Duration? nextTomorrowRemaining,
  }) = PrayerTimesReady;
}
