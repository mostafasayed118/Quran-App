import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

/// Day-key normalization: midnight, local. Never compare raw DateTimes.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

enum PrayerSlot { fajr, dhuhr, asr, maghrib, isha }

class TrackerDay {
  const TrackerDay({
    required this.day,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime day;
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;

  bool get anyMarked => fajr || dhuhr || asr || maghrib || isha;

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

class PrayerLogRepository {
  PrayerLogRepository(this._db);

  final AppDatabase _db;

  Future<TrackerDay> dayView(DateTime day) async {
    final key = dateOnly(day);
    final row = await (_db.select(_db.prayerLog)
          ..where((p) => p.day.equals(key)))
        .getSingleOrNull();
    return row == null ? TrackerDay.empty(key) : TrackerDay.fromRow(row);
  }

  Future<bool> getForDay(DateTime day) async => (await dayView(day)).anyMarked;

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

  Future<List<DateTime>> markedDaysRange(
      DateTime fromInclusive, int daysBack) async {
    final from = dateOnly(fromInclusive);
    final days = <DateTime>[
      for (var i = 0; i < daysBack; i++) from.subtract(Duration(days: i)),
    ];
    final rows =
        await (_db.select(_db.prayerLog)..where((p) => p.day.isIn(days))).get();
    final marked = <String>{
      for (final row in rows)
        if (TrackerDay.fromRow(row).anyMarked)
          '${row.day.year}-${row.day.month}-${row.day.day}',
    };
    return [
      for (final day in days)
        if (marked.contains('${day.year}-${day.month}-${day.day}')) day,
    ];
  }
}
