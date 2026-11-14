import 'prayer_name.dart';

/// The period whose palette should cover the chrome at [now].
///
/// [now] and the six markers are absolute instants; the calculation layer has
/// already turned the persisted configuration, the selected city and the local
/// calendar date into them. This function therefore never reads a clock, a time
/// zone or a calculation method — which is what makes the boundary behaviour
/// (midnight, DST, a traveller) testable.
///
/// Rules:
///  * Before today's [fajr] the period is **isha** (last night's): a phone
///    opened at 00:30 keeps the night palette instead of falling back to
///    nothing.
///  * [sunrise] is nullable and may be degenerate (not before [dhuhr]) on a
///    high-latitude plan: then **fajr extends to dhuhr** — no gap, no throw.
///  * From [isha] onwards the period is isha until next fajr (the next day's
///    markers replace these, not a date comparison).
PrayerName prayerPeriodAt({
  required DateTime now,
  required DateTime fajr,
  required DateTime? sunrise,
  required DateTime dhuhr,
  required DateTime asr,
  required DateTime maghrib,
  required DateTime isha,
}) {
  // A sunrise that is not before dhuhr leaves the sunrise window empty; the
  // day is fajr -> dhuhr.
  final hasSunrise = sunrise != null && sunrise.isBefore(dhuhr);
  if (now.isBefore(fajr)) return PrayerName.isha;
  if (now.isBefore(hasSunrise ? sunrise : dhuhr)) return PrayerName.fajr;
  if (hasSunrise && now.isBefore(dhuhr)) return PrayerName.sunrise;
  if (now.isBefore(asr)) return PrayerName.dhuhr;
  if (now.isBefore(maghrib)) return PrayerName.asr;
  if (now.isBefore(isha)) return PrayerName.maghrib;
  return PrayerName.isha;
}

/// The first marker strictly after [now], so the caller can sleep until it.
///
/// [nextFajr] is tomorrow's fajr: it is the boundary that ends the isha
/// window. Sunrise is included when it is a real window — it changes the
/// palette even though it is not a prayer.
DateTime? nextPeriodBoundary({
  required DateTime now,
  required DateTime fajr,
  required DateTime? sunrise,
  required DateTime dhuhr,
  required DateTime asr,
  required DateTime maghrib,
  required DateTime isha,
  required DateTime nextFajr,
}) {
  final hasSunrise = sunrise != null && sunrise.isBefore(dhuhr);
  final candidates = <DateTime>[
    fajr,
    if (hasSunrise) sunrise,
    dhuhr,
    asr,
    maghrib,
    isha,
    nextFajr,
  ];
  DateTime? next;
  for (final candidate in candidates) {
    if (!candidate.isAfter(now)) continue;
    if (next == null || candidate.isBefore(next)) next = candidate;
  }
  return next;
}
