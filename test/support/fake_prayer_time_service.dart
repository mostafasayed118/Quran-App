import 'package:quran_yahdi/features/prayer/data/prayer_time_service.dart';

/// One prayer-time double for the home and prayer-times suites.
///
/// The two tests used to carry independent bodies; [todayResult] is null in
/// the home suite (it never calls [today]) and set in the prayer suite. The
/// default next prayer matches the home suite's fixed day.
class FakePrayerTimeService implements PrayerTimeService {
  List<PrayerChoice>? todayResult;
  PrayerChoice? nextResult;
  bool throwOnNext = false;

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) =>
      todayResult ?? (throw UnimplementedError());

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) {
    if (throwOnNext) throw StateError('prayer service down');
    return nextResult ??
        PrayerChoice(PrayerName.fajr, DateTime(2026, 3, 16, 4, 45));
  }
}
