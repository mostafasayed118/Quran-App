import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'backup_codec.dart';
import 'backup_inventory.dart';
import 'backup_merger.dart';

/// Result of a completed [BackupService.apply] — the preview-identical
/// summary plus whether the injected reschedule hook ran after the commit.
class BackupOutcome {
  const BackupOutcome({required this.summary, required this.rescheduled});

  final BackupSummary summary;
  final bool rescheduled;
}

/// Gather / preview / transactional-apply for the user-controlled backup file.
///
/// Merges are computed by the pure merger functions; writes happen in ONE
/// drift transaction (a failure rolls everything back — never a partial
/// import). Rescheduling reuses the composition-root hook (the boot-schedule
/// path); it runs only after a successful commit and only when a
/// reminder-relevant settings key changed. An import never deletes user data.
class BackupService {
  BackupService({
    required AppDatabase db,
    required Future<void> Function() reschedule,
  })  : _db = db,
        _reschedule = reschedule;

  final AppDatabase _db;
  final Future<void> Function() _reschedule;

  /// Gathers every backed-up entity in one read transaction and encodes the
  /// versioned document (settings filtered to the whitelist).
  Future<String> exportJson() async {
    final data = await _db.transaction(_gather);
    return encode(BackupDocument(
      exportedAt: DateTime.now(),
      schemaVersion: _db.schemaVersion,
      data: data,
    ));
  }

  /// Computes the per-entity merge counts WITHOUT writing anything.
  Future<BackupSummary> preview(BackupDocument document) async {
    final plan = await _planFor(document.data);
    return plan.summary;
  }

  /// Merges and writes in ONE transaction, then reschedules reminders only
  /// when a reminder-relevant key changed and the apply committed.
  Future<BackupOutcome> apply(BackupDocument document) async {
    final plan = await _db.transaction(() async {
      final plan = await _planFor(document.data);
      await _writePlan(plan);
      return plan;
    });
    final rescheduled = plan.reminderRelevantChanged;
    if (rescheduled) {
      await _reschedule();
    }
    return BackupOutcome(summary: plan.summary, rescheduled: rescheduled);
  }

  Future<BackupData> _gather() async {
    final bookmarkRows = await _db.select(_db.bookmarks).get();
    final khatmaRow = await _db.select(_db.khatmaProgress).getSingleOrNull();
    final prayerRows = await _db.select(_db.prayerLog).get();
    final lastReadRow = await _readSetting(backupKeyLastReadAyahId);
    final tasbihRow = await _readSetting(backupKeyTasbihState);
    final whitelistRows = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.isIn(kBackupSettingsWhitelist)))
        .get();

    return BackupData(
      bookmarks: [
        for (final row in bookmarkRows)
          BackupBookmark(ayahId: row.ayahId, createdAt: row.createdAt),
      ],
      lastReadAyahId: int.tryParse(lastReadRow?.value ?? ''),
      khatma: [
        if (khatmaRow != null)
          BackupKhatmaRow(
            ayahId: khatmaRow.ayahId,
            targetPages: khatmaRow.targetPages,
            updatedAt: khatmaRow.updatedAt,
          ),
      ],
      prayerLog: [
        for (final row in prayerRows)
          BackupPrayerDay(
            day: backupDateOnly(row.day),
            fajr: row.fajr,
            dhuhr: row.dhuhr,
            asr: row.asr,
            maghrib: row.maghrib,
            isha: row.isha,
          ),
      ],
      tasbih: _decodeTasbihValue(tasbihRow?.value),
      settings: {
        for (final row in whitelistRows) row.key: row.value,
      },
    );
  }

  Future<SettingsTableData?> _readSetting(String key) =>
      (_db.select(_db.settingsTable)..where((s) => s.key.equals(key)))
          .getSingleOrNull();

  /// Mirrors `TasbihRepository.load`'s tolerant JSON read (corrupt → null).
  static BackupTasbih? _decodeTasbihValue(String? value) {
    if (value == null) return null;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return BackupTasbih(
        count: (json['count'] as num).toInt(),
        target: (json['target'] as num).toInt(),
      );
    } on Object {
      return null;
    }
  }

  Future<_ApplyPlan> _planFor(BackupData data) async {
    final bookmarkRows = await _db.select(_db.bookmarks).get();
    final khatmaRow = await _db.select(_db.khatmaProgress).getSingleOrNull();
    final prayerRows = await _db.select(_db.prayerLog).get();
    final lastReadRow = await _readSetting(backupKeyLastReadAyahId);
    final tasbihRow = await _readSetting(backupKeyTasbihState);
    final whitelistRows = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.isIn(kBackupSettingsWhitelist)))
        .get();

    return _ApplyPlan(
      bookmarks: mergeBookmarks(
        existingAyahIds: {for (final row in bookmarkRows) row.ayahId},
        imported: data.bookmarks,
      ),
      lastRead: mergeLastRead(
        existing: int.tryParse(lastReadRow?.value ?? ''),
        imported: data.lastReadAyahId,
      ),
      khatma: mergeKhatma(
        existing: khatmaRow == null
            ? null
            : BackupKhatmaRow(
                ayahId: khatmaRow.ayahId,
                targetPages: khatmaRow.targetPages,
                updatedAt: khatmaRow.updatedAt,
              ),
        imported: data.khatma,
      ),
      prayerLog: mergePrayerLog(
        existing: [
          for (final row in prayerRows)
            BackupPrayerDay(
              day: backupDateOnly(row.day),
              fajr: row.fajr,
              dhuhr: row.dhuhr,
              asr: row.asr,
              maghrib: row.maghrib,
              isha: row.isha,
            ),
        ],
        imported: data.prayerLog,
      ),
      tasbih: mergeTasbih(
        existing: _decodeTasbihValue(tasbihRow?.value),
        imported: data.tasbih,
      ),
      settings: mergeSettings(
        existing: {for (final row in whitelistRows) row.key: row.value},
        imported: data.settings,
      ),
      khatmaRowId: khatmaRow?.id,
    );
  }

  /// All writes for one plan — called inside the apply transaction only.
  /// Inserts/upserts only; nothing is ever deleted.
  Future<void> _writePlan(_ApplyPlan plan) async {
    for (final bookmark in plan.bookmarks.toInsert) {
      await _db.into(_db.bookmarks).insert(BookmarksCompanion.insert(
            ayahId: bookmark.ayahId,
            createdAt: Value(bookmark.createdAt),
          ));
    }

    final lastRead = plan.lastRead.toWrite;
    if (lastRead != null) {
      await _writeSetting(backupKeyLastReadAyahId, lastRead.toString());
    }

    final khatma = plan.khatma.toWrite;
    if (khatma != null) {
      final existingRowId = plan.khatmaRowId;
      if (existingRowId != null) {
        await (_db.update(_db.khatmaProgress)
              ..where((t) => t.id.equals(existingRowId)))
            .write(KhatmaProgressCompanion(
          ayahId: Value(khatma.ayahId),
          targetPages: Value(khatma.targetPages),
          updatedAt: Value(khatma.updatedAt),
        ));
      } else {
        await _db.into(_db.khatmaProgress).insert(
              KhatmaProgressCompanion.insert(
                ayahId: khatma.ayahId,
                targetPages: khatma.targetPages,
                updatedAt: Value(khatma.updatedAt),
              ),
            );
      }
    }

    for (final day in plan.prayerLog.daysToWrite) {
      await _db.into(_db.prayerLog).insertOnConflictUpdate(
            PrayerLogCompanion.insert(
              day: day.day,
              fajr: Value(day.fajr),
              dhuhr: Value(day.dhuhr),
              asr: Value(day.asr),
              maghrib: Value(day.maghrib),
              isha: Value(day.isha),
            ),
          );
    }

    final tasbih = plan.tasbih.toWrite;
    if (tasbih != null) {
      await _writeSetting(
        backupKeyTasbihState,
        jsonEncode({'count': tasbih.count, 'target': tasbih.target}),
      );
    }

    for (final entry in plan.settings.toWrite.entries) {
      await _writeSetting(entry.key, entry.value);
    }
  }

  Future<void> _writeSetting(String key, String value) =>
      _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(key: key, value: value),
          );
}

class _ApplyPlan {
  const _ApplyPlan({
    required this.bookmarks,
    required this.lastRead,
    required this.khatma,
    required this.prayerLog,
    required this.tasbih,
    required this.settings,
    required this.khatmaRowId,
  });

  final BookmarkMerge bookmarks;
  final LastReadMerge lastRead;
  final KhatmaMerge khatma;
  final PrayerLogMerge prayerLog;
  final TasbihMerge tasbih;
  final SettingsMerge settings;

  /// Row id of the existing single khatma row (update-in-place target).
  final int? khatmaRowId;

  BackupSummary get summary => BackupSummary(
        newBookmarks: bookmarks.newCount,
        mergedPrayerDays: prayerLog.mergedDays,
        planReplaced: khatma.replaced,
        tasbihCountDelta: tasbih.countDelta,
        tasbihChanged: tasbih.changed,
        lastReadChanged: lastRead.changed,
        settingsKeysApplied: settings.appliedCount,
      );

  bool get reminderRelevantChanged =>
      settings.toWrite.keys.any(kBackupReminderRelevantKeys.contains);
}
