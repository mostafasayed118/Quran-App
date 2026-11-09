import '../../../core/utils/date_only.dart';

/// The prayers of a day, in order.
enum PrayerSlot { fajr, dhuhr, asr, maghrib, isha }

/// The prayers marked on one calendar day.
class TrackerDay {
  const TrackerDay({
    required this.day,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// The calendar day this record describes.
  final DateTime day;

  /// Fajr marked.
  final bool fajr;

  /// Dhuhr marked.
  final bool dhuhr;

  /// Asr marked.
  final bool asr;

  /// Maghrib marked.
  final bool maghrib;

  /// Isha marked.
  final bool isha;

  /// True when at least one prayer is marked.
  bool get anyMarked => fajr || dhuhr || asr || maghrib || isha;

  /// Whether the prayer of [slot] is marked.
  bool forSlot(PrayerSlot slot) => switch (slot) {
        PrayerSlot.fajr => fajr,
        PrayerSlot.dhuhr => dhuhr,
        PrayerSlot.asr => asr,
        PrayerSlot.maghrib => maghrib,
        PrayerSlot.isha => isha,
      };

  factory TrackerDay.empty(DateTime day) => TrackerDay(
        day: dateOnly(day),
        fajr: false,
        dhuhr: false,
        asr: false,
        maghrib: false,
        isha: false,
      );
}
