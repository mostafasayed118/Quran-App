import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/prayer_name.dart';

part 'home_state.freezed.dart';

typedef LastReadCard = ({int surahId, String surahName, int ayahNumber});

/// The next prayer plus the city it was calculated for.
///
/// [cityName] travels with the prayer because the dashboard shows one card
/// ("next prayer in Cairo"); leaving it out forced the screen to print a
/// time with no place attached to it.
typedef NextPrayerCard = ({PrayerName name, DateTime time, String cityName});

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.loading() = HomeLoading;

  /// Load failed (e.g. a DB read threw): the screen shows the localized
  /// error pane instead of hanging on [HomeState.loading] forever.
  const factory HomeState.failed() = HomeFailed;

  const factory HomeState.ready({
    @Default(null) LastReadCard? lastRead,
    @Default(null) NextPrayerCard? nextPrayer,
    @Default(null) String? cityTimezone,
  }) = HomeReady;
}
