import 'package:hijri/hijri_calendar.dart';

/// Thin wrapper over the hijri package (`HijriCalendar`, 3.0.1 — Umm
/// al-Qura tables, pure Dart, no flutter binding).
///
/// [offsetDays] is the user's local correction: +1 means "the Hijri date is
/// one day later than the Umm al-Qura table". It shifts the conversion in
/// both directions and leaves the month length and the month name pure.
class HijriService {
  /// Creates the service; [offsetDays] is clamped to [-2, 2].
  HijriService({int offsetDays = 0}) : _offsetDays = _clamp(offsetDays) {
    HijriCalendar.setLocal('ar');
  }

  /// The widest correction a local moon-sighting convention needs.
  static const int minOffsetDays = -2;
  static const int maxOffsetDays = 2;

  int _offsetDays;

  /// The current local correction, in days.
  int get offsetDays => _offsetDays;

  /// Sets the local correction; out-of-range values are clamped.
  set offsetDays(int value) => _offsetDays = _clamp(value);

  /// Converts a Gregorian date to its Hijri calendar date.
  HijriCalendar fromGregorian(DateTime date) =>
      HijriCalendar.fromDate(_shift(date, _offsetDays));

  /// Converts a Hijri year/month/day back to a Gregorian date.
  DateTime toGregorian(int hijriYear, int hijriMonth, int hijriDay) => _shift(
        HijriCalendar().hijriToGregorian(hijriYear, hijriMonth, hijriDay),
        -_offsetDays,
      );

  /// Number of days in the given Hijri month (calendar-pure).
  int daysInMonth(int hijriYear, int hijriMonth) =>
      HijriCalendar().getDaysInMonth(hijriYear, hijriMonth);

  /// Arabic name of the given Hijri month (calendar-pure).
  String monthName(int hijriYear, int hijriMonth) {
    // Mid-month gregorian anchor is stable within the month.
    final anchor = HijriCalendar().hijriToGregorian(hijriYear, hijriMonth, 15);
    return HijriCalendar.fromDate(anchor).longMonthName;
  }

  static DateTime _shift(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static int _clamp(int value) {
    if (value < minOffsetDays) return minOffsetDays;
    if (value > maxOffsetDays) return maxOffsetDays;
    return value;
  }
}
