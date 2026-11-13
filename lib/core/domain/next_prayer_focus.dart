import 'prayer_times.dart';

/// What the next-prayer focus view needs, carried across a route boundary.
///
/// It lives in `core/domain` because both the home card (the producer) and the
/// prayer feature's screen (the consumer) read it, and a feature-to-feature
/// import is not allowed.
class NextPrayerFocus {
  /// Creates the focus payload.
  const NextPrayerFocus({
    required this.prayer,
    required this.time,
    required this.cityName,
    this.timezone,
  });

  /// Which prayer is coming.
  final PrayerName prayer;

  /// Its instant, in UTC as the prayer engine returns it.
  final DateTime time;

  /// The selected city's display name.
  final String cityName;

  /// The city's IANA zone, when known; the wall clock is derived from it.
  final String? timezone;
}
