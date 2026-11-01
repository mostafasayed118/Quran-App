import '../../../core/domain/city.dart';
import '../../../core/domain/prayer_config.dart';
import '../../../core/domain/prayer_times.dart';
import 'prayer_calculator.dart';

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

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) {
    return prayerTimesFor(c, dayLocal, PrayerConfig.egyptian);
  }

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) {
    return nextPrayerAfter(c, whenLocal, PrayerConfig.egyptian);
  }
}
