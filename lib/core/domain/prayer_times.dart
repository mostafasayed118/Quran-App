import 'city.dart';
import 'prayer_name.dart';

export 'prayer_name.dart' show PrayerName;

/// One prayer (or sunrise) and its local time.
class PrayerChoice {
  /// Creates a prayer entry for [name] at [time].
  const PrayerChoice(this.name, this.time);

  /// Which prayer (or sunrise) this entry is.
  final PrayerName name;

  /// The local time of the entry on the requested day.
  final DateTime time;
}

/// Cross-feature seam: the prayer feature owns the calculation, every other
/// consumer reaches it through this port.
abstract interface class PrayerTimesPort {
  /// The six times of [dayLocal] at [c], in calendar order.
  List<PrayerChoice> today(CityCoordinates c, DateTime dayLocal);

  /// The next prayer still ahead at [whenLocal] (sunrise is not a prayer).
  PrayerChoice nextPrayer(CityCoordinates c, DateTime whenLocal);
}
