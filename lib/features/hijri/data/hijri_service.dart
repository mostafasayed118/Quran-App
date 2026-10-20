import 'package:hijri/hijri_calendar.dart';

/// Thin wrapper over the hijri package (`HijriCalendar`, 3.0.1 — Umm
/// al-Qura tables, pure Dart, no flutter binding).
class HijriService {
  HijriService() {
    HijriCalendar.setLocal('ar');
  }

  /// Converts a Gregorian date to its Hijri calendar date.
  HijriCalendar fromGregorian(DateTime date) => HijriCalendar.fromDate(date);

  /// Converts a Hijri year/month/day back to a Gregorian date.
  DateTime toGregorian(int hijriYear, int hijriMonth, int hijriDay) =>
      HijriCalendar().hijriToGregorian(hijriYear, hijriMonth, hijriDay);

  /// Number of days in the given Hijri month.
  int daysInMonth(int hijriYear, int hijriMonth) =>
      HijriCalendar().getDaysInMonth(hijriYear, hijriMonth);

  /// Arabic name of the given Hijri month.
  String monthName(int hijriYear, int hijriMonth) {
    // Mid-month gregorian anchor is stable within the month.
    final anchor = toGregorian(hijriYear, hijriMonth, 15);
    return HijriCalendar.fromDate(anchor).longMonthName;
  }
}
