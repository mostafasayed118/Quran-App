import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _zonesReady = false;

void _ensureZones() {
  if (_zonesReady) return;
  tzdata.initializeTimeZones();
  _zonesReady = true;
}

/// The wall-clock time of [instant] in [timezone], for display only.
///
/// Prayer times are stored and compared as instants (countdowns, the next
/// prayer highlight and reminder scheduling all use `difference`). The device
/// zone is not necessarily the selected city's zone, so rendering must convert
/// the instant to the city's wall clock. A null/unknown zone keeps the old
/// behaviour: the instant's device-local components.
DateTime cityWallClock(DateTime instant, String? timezone) {
  if (timezone == null || timezone.isEmpty) return instant;
  _ensureZones();
  try {
    return tz.TZDateTime.from(instant, tz.getLocation(timezone));
  } on Object {
    return instant;
  }
}
