import '../../../core/domain/city.dart';
import '../../../core/domain/prayer_config.dart';
import '../../../core/domain/prayer_times.dart';
import 'prayer_calculator.dart';

/// A [PrayerTimesPort] that applies the user's persisted calculation method.
///
/// The port is synchronous, so this reads [PrayerConfigSource.current], a cache
/// that starts at the historical Egyptian/Shafi default and is refreshed by
/// `load()` behind the first frame.
class ConfiguredPrayerTimes implements PrayerTimesPort {
  /// Creates the port over [config].
  ConfiguredPrayerTimes(this._config);

  final PrayerConfigSource _config;

  @override
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal) {
    return prayerTimesFor(c, dayLocal, _config.current);
  }

  @override
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal) {
    return nextPrayerAfter(c, whenLocal, _config.current);
  }
}
