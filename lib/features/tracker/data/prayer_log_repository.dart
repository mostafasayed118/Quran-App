import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/date_only.dart';
import '../domain/tracker_day.dart';

export '../../../core/utils/date_only.dart' show dateOnly;
export '../domain/tracker_day.dart';

/// The prayers marked on one calendar day as stored in the database; the
/// pure record lives in [tracker_day.dart].
TrackerDay trackerDayFromRow(PrayerLogData row) => TrackerDay(
      day: dateOnly(row.day),
      fajr: row.fajr,
      dhuhr: row.dhuhr,
      asr: row.asr,
      maghrib: row.maghrib,
      isha: row.isha,
    );

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
    return row == null ? TrackerDay.empty(key) : trackerDayFromRow(row);
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
        if (trackerDayFromRow(row).anyMarked) dayKey(row.day),
    };
    return [
      for (final day in days)
        if (marked.contains(dayKey(day))) day,
    ];
  }
}
