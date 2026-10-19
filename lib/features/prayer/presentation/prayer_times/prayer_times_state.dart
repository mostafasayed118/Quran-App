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
  }) = PrayerTimesReady;
}
