import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/date_only.dart';

export '../../../core/utils/date_only.dart' show dateOnly;

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

  factory TrackerDay.fromRow(PrayerLogData row) => TrackerDay(
        day: dateOnly(row.day),
        fajr: row.fajr,
        dhuhr: row.dhuhr,
        asr: row.asr,
        maghrib: row.maghrib,
        isha: row.isha,
      );

  factory TrackerDay.empty(DateTime day) => TrackerDay(
        day: dateOnly(day),
        fajr: false,
        dhuhr: false,
        asr: false,
        maghrib: false,
        isha: false,
      );
}

/// Reads and toggles the daily prayer log.
class PrayerLogRepository {
  PrayerLogRepository(this._db);

  final AppDatabase _db;

  /// The marked prayers of [day]; an unmarked day returns all-false.
  Future<TrackerDay> dayView(DateTime day) async {
    final key = dateOnly(day);
    final row = await (_db.select(_db.prayerLog)
          ..where((p) => p.day.equals(key)))
        .getSingleOrNull();
    return row == null ? TrackerDay.empty(key) : TrackerDay.fromRow(row);
  }

  /// True when at least one prayer is marked on [day].
  Future<bool> getForDay(DateTime day) async => (await dayView(day)).anyMarked;

  /// Marks or unmarks the prayer of [slot] on [day].
  Future<void> togglePrayer(DateTime day, PrayerSlot slot) async {
    final key = dateOnly(day);
    final current = await dayView(key);
    final flipped = !current.forSlot(slot);
    final companion = switch (slot) {
      PrayerSlot.fajr =>
        PrayerLogCompanion.insert(day: key, fajr: Value(flipped)),
      PrayerSlot.dhuhr =>
        PrayerLogCompanion.insert(day: key, dhuhr: Value(flipped)),
      PrayerSlot.asr =>
        PrayerLogCompanion.insert(day: key, asr: Value(flipped)),
      PrayerSlot.maghrib =>
        PrayerLogCompanion.insert(day: key, maghrib: Value(flipped)),
      PrayerSlot.isha =>
        PrayerLogCompanion.insert(day: key, isha: Value(flipped)),
    };
    await _db.into(_db.prayerLog).insertOnConflictUpdate(companion);
  }

  /// Days with at least one marked prayer, from [fromInclusive] going [daysBack] days back.
  Future<List<DateTime>> markedDaysRange(
      DateTime fromInclusive, int daysBack) async {
    final from = dateOnly(fromInclusive);
    final days = <DateTime>[
      for (var i = 0; i < daysBack; i++)
        DateTime(from.year, from.month, from.day - i),
    ];
    final rows =
        await (_db.select(_db.prayerLog)..where((p) => p.day.isIn(days))).get();
    final marked = <String>{
      for (final row in rows)
        if (TrackerDay.fromRow(row).anyMarked) dayKey(row.day),
    };
    return [
      for (final day in days)
        if (marked.contains(dayKey(day))) day,
    ];
  }
}
