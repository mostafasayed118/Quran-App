import 'package:adhan/adhan.dart';

import '../../../core/domain/city.dart';
import '../../../core/domain/prayer_times.dart';

// Compat: existing importers of this file keep resolving [PrayerChoice],
// [PrayerName] and [CityCoordinates].
export '../../../core/domain/city.dart' show CityCoordinates;
export '../../../core/domain/prayer_times.dart' show PrayerChoice, PrayerName;

/// Computes prayer times with the Egyptian calculation method.
class PrayerTimeService implements PrayerTimesPort {
  /// Creates the service; it holds no state.
  const PrayerTimeService();

  /// Label of the calculation method, 'egyptian'.
  static const String methodLabel = 'egyptian';

  PrayerTimes _timesFor(CityCoordinates c, DateTime dayLocal) {
    return PrayerTimes(
      Coordinates(c.latitude, c.longitude),
      DateComponents(dayLocal.year, dayLocal.month, dayLocal.day),
      CalculationMethod.egyptian.getParameters(),
    );
  }

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) {
    final t = _timesFor(c, dayLocal);
    return <PrayerChoice>[
      PrayerChoice(PrayerName.fajr, t.fajr),
      PrayerChoice(PrayerName.sunrise, t.sunrise),
      PrayerChoice(PrayerName.dhuhr, t.dhuhr),
      PrayerChoice(PrayerName.asr, t.asr),
      PrayerChoice(PrayerName.maghrib, t.maghrib),
      PrayerChoice(PrayerName.isha, t.isha),
    ];
  }

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) {
    final day = DateTime(whenLocal.year, whenLocal.month, whenLocal.day);
    final entries = today(c, day);
    for (final choice in entries) {
      if (choice.name == PrayerName.sunrise) continue;
      if (choice.time.isAfter(whenLocal)) return choice;
    }
    final tomorrow = day.add(const Duration(days: 1));
    final tomorrowTimes = _timesFor(c, tomorrow);
    return PrayerChoice(PrayerName.fajr, tomorrowTimes.fajr);
  }
}
