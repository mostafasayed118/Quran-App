import 'package:adhan/adhan.dart';

import '../../../core/domain/city.dart';
import '../../../core/domain/prayer_config.dart';
import '../../../core/domain/prayer_times.dart';

/// Maps the app's persisted preferences to adhan's calculation parameters.
///
/// The mapping is exhaustive on purpose: adding a method to
/// [PrayerCalculationMethod] fails compilation here until it is mapped.
CalculationParameters parametersFor(PrayerConfig config) {
  final method = switch (config.method) {
    PrayerCalculationMethod.egyptian => CalculationMethod.egyptian,
    PrayerCalculationMethod.muslimWorldLeague =>
      CalculationMethod.muslim_world_league,
    PrayerCalculationMethod.karachi => CalculationMethod.karachi,
    PrayerCalculationMethod.ummAlQura => CalculationMethod.umm_al_qura,
    PrayerCalculationMethod.dubai => CalculationMethod.dubai,
    PrayerCalculationMethod.kuwait => CalculationMethod.kuwait,
    PrayerCalculationMethod.qatar => CalculationMethod.qatar,
    PrayerCalculationMethod.turkey => CalculationMethod.turkey,
    PrayerCalculationMethod.northAmerica => CalculationMethod.north_america,
  };
  final parameters = method.getParameters();
  parameters.madhab =
      config.madhab == PrayerMadhab.hanafi ? Madhab.hanafi : Madhab.shafi;
  final adjustments = parameters.adjustments;
  adjustments.fajr = config.adjustmentFor(PrayerName.fajr);
  adjustments.dhuhr = config.adjustmentFor(PrayerName.dhuhr);
  adjustments.asr = config.adjustmentFor(PrayerName.asr);
  adjustments.maghrib = config.adjustmentFor(PrayerName.maghrib);
  adjustments.isha = config.adjustmentFor(PrayerName.isha);
  final highLatitude = switch (config.highLatitude) {
    PrayerHighLatitudeRule.none => null,
    PrayerHighLatitudeRule.middleOfTheNight =>
      HighLatitudeRule.middle_of_the_night,
    PrayerHighLatitudeRule.seventhOfTheNight =>
      HighLatitudeRule.seventh_of_the_night,
    PrayerHighLatitudeRule.twilightAngle => HighLatitudeRule.twilight_angle,
  };
  if (highLatitude != null) parameters.highLatitudeRule = highLatitude;
  return parameters;
}

PrayerTimes _timesFor(
  CityCoordinates c,
  DateTime dayLocal,
  PrayerConfig config,
) {
  return PrayerTimes(
    Coordinates(c.latitude, c.longitude),
    DateComponents(dayLocal.year, dayLocal.month, dayLocal.day),
    parametersFor(config),
  );
}

/// The six times of [dayLocal] at [c], in calendar order, for [config].
List<PrayerChoice> prayerTimesFor(
  CityCoordinates c,
  DateTime dayLocal,
  PrayerConfig config,
) {
  final t = _timesFor(c, dayLocal, config);
  return <PrayerChoice>[
    PrayerChoice(PrayerName.fajr, t.fajr),
    PrayerChoice(PrayerName.sunrise, t.sunrise),
    PrayerChoice(PrayerName.dhuhr, t.dhuhr),
    PrayerChoice(PrayerName.asr, t.asr),
    PrayerChoice(PrayerName.maghrib, t.maghrib),
    PrayerChoice(PrayerName.isha, t.isha),
  ];
}

/// The next prayer still ahead at [whenLocal] for [config].
///
/// Calendar-day arithmetic, not `+ Duration(days: 1)`: a DST transition makes
/// a local day 23 h or 25 h long, so adding a duration can land back on the
/// same calendar date (Egypt, 2026-10-29) and return today's fajr.
PrayerChoice nextPrayerAfter(
  CityCoordinates c,
  DateTime whenLocal,
  PrayerConfig config,
) {
  final day = DateTime(whenLocal.year, whenLocal.month, whenLocal.day);
  final entries = prayerTimesFor(c, day, config);
  for (final choice in entries) {
    if (choice.name == PrayerName.sunrise) continue;
    if (choice.time.isAfter(whenLocal)) return choice;
  }
  final tomorrow = DateTime(day.year, day.month, day.day + 1);
  final tomorrowTimes = _timesFor(c, tomorrow, config);
  return PrayerChoice(PrayerName.fajr, tomorrowTimes.fajr);
}
