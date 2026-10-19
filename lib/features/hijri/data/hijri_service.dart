import 'package:hijri/hijri_calendar.dart';

/// Thin wrapper over the hijri package (`HijriCalendar`, 3.0.1 — Umm
/// al-Qura tables, pure Dart, no flutter binding).
class HijriService {
  HijriService() {
    HijriCalendar.setLocal('ar');
  }

  HijriCalendar fromGregorian(DateTime date) => HijriCalendar.fromDate(date);

  DateTime toGregorian(int hijriYear, int hijriMonth, int hijriDay) =>
      HijriCalendar().hijriToGregorian(hijriYear, hijriMonth, hijriDay);

  int daysInMonth(int hijriYear, int hijriMonth) =>
      HijriCalendar().getDaysInMonth(hijriYear, hijriMonth);

  String monthName(int hijriYear, int hijriMonth) {
    // Mid-month gregorian anchor is stable within the month.
    final anchor = toGregorian(hijriYear, hijriMonth, 15);
    return HijriCalendar.fromDate(anchor).longMonthName;
  }
}
