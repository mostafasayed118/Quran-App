/// Cross-feature seam: the Hijri calendar the Ramadan screen reads.
///
/// The hijri feature implements it over its own `HijriService` (with the
/// user's local +/- day correction), so the Ramadan feature never imports
/// another feature's data layer.
abstract interface class RamadanCalendar {
  /// The Hijri date of [date] as a simple record.
  ({int year, int month, int day}) hijriDate(DateTime date);

  /// The Gregorian date of a Hijri year/month/day.
  DateTime gregorianDate(int year, int month, int day);

  /// Number of days in the given Hijri month.
  int daysInMonth(int year, int month);

  /// Arabic name of the given Hijri month.
  String monthName(int year, int month);
}
