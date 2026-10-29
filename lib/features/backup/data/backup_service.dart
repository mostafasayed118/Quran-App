import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'backup_codec.dart';
import 'backup_inventory.dart';
import 'backup_merger.dart';

/// Result of a completed [BackupService.apply] — the preview-identical
/// summary plus whether the injected reschedule hook ran after the commit.
class BackupOutcome {
  /// What an applied backup did.
  const BackupOutcome({required this.summary, required this.rescheduled});

  /// Counts of what changed.
  final BackupSummary summary;

  /// True when reminders were rescheduled after the import.
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

  /// Small imports keep the per-row path (it preserves statement order and
  /// keeps the rollback probe observable); a real import batches the writes
  /// into one round-trip.
  static const int _batchThreshold = 64;

  /// Gathers every backed-up entity in one read transaction and encodes the
  /// versioned document (settings filtered to the whitelist).
  Future<String> exportJson() async {
    final data = await _db.transaction(_gather);
    final payload = encodeMap(BackupDocument(
      exportedAt: DateTime.now(),
      schemaVersion: _db.schemaVersion,
      data: data,
    ));
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      return jsonEncode(payload);
    }
    return Isolate.run(() => jsonEncode(payload));
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
      settings: _exportedSettings(whitelistRows),
    );
  }

  /// The whitelisted settings as they may leave the app.
  ///
  /// The selected city is redacted: a backup file is a file the user hands
  /// to somebody else, so the GPS coordinates never travel with it (the
  /// city id does, so an import can restore the selection).
  static Map<String, String> _exportedSettings(List<SettingsTableData> rows) {
    final exported = <String, String>{};
    for (final row in rows) {
      final value = row.key == backupKeySelectedCity
          ? redactedSelectedCity(row.value)
          : row.value;
      if (value != null) exported[row.key] = value;
    }
    return exported;
  }

  /// The imported settings, with the selected city redacted.
  ///
  /// The redaction runs on the import too: a file that carries coordinates
  /// must not be able to write them into the settings table.
  static Map<String, String> _redactedSettings(Map<String, String> imported) {
    final redacted = <String, String>{};
    for (final entry in imported.entries) {
      if (entry.key == backupKeySelectedCity) {
        final value = redactedSelectedCity(entry.value);
        if (value != null) redacted[entry.key] = value;
        continue;
      }
      redacted[entry.key] = entry.value;
    }
    return redacted;
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
        imported: _redactedSettings(data.settings),
      ),
      khatmaRowId: khatmaRow?.id,
    );
  }

  /// All writes for one plan — called inside the apply transaction only.
  /// Inserts/upserts only; nothing is ever deleted.
  Future<void> _writePlan(_ApplyPlan plan) async {
    final bookmarks = <BookmarksCompanion>[
      for (final bookmark in plan.bookmarks.toInsert)
        BookmarksCompanion.insert(
          ayahId: bookmark.ayahId,
          createdAt: Value(bookmark.createdAt),
        ),
    ];

    final prayerDays = <PrayerLogCompanion>[
      for (final day in plan.prayerLog.daysToWrite)
        PrayerLogCompanion.insert(
          day: day.day,
          fajr: Value(day.fajr),
          dhuhr: Value(day.dhuhr),
          asr: Value(day.asr),
          maghrib: Value(day.maghrib),
          isha: Value(day.isha),
        ),
    ];

    final settings = <SettingsTableCompanion>[];
    final lastRead = plan.lastRead.toWrite;
    if (lastRead != null) {
      settings.add(SettingsTableCompanion.insert(
        key: backupKeyLastReadAyahId,
        value: lastRead.toString(),
      ));
    }
    final tasbih = plan.tasbih.toWrite;
    if (tasbih != null) {
      settings.add(SettingsTableCompanion.insert(
        key: backupKeyTasbihState,
        value: jsonEncode({'count': tasbih.count, 'target': tasbih.target}),
      ));
    }
    for (final entry in plan.settings.toWrite.entries) {
      settings.add(SettingsTableCompanion.insert(
        key: entry.key,
        value: entry.value,
      ));
    }

    final khatma = plan.khatma.toWrite;
    final khatmaWrite = khatma == null
        ? null
        : KhatmaProgressCompanion(
            ayahId: Value(khatma.ayahId),
            targetPages: Value(khatma.targetPages),
            updatedAt: Value(khatma.updatedAt),
          );
    final khatmaRowId = plan.khatmaRowId;
    final totalWrites = bookmarks.length +
        prayerDays.length +
        settings.length +
        (khatmaWrite == null ? 0 : 1);
    if (totalWrites < _batchThreshold) {
      for (final bookmark in bookmarks) {
        await _db.into(_db.bookmarks).insert(bookmark);
      }
      if (khatmaWrite != null) {
        await _writeKhatma(khatmaWrite, khatmaRowId);
      }
      for (final day in prayerDays) {
        await _db.into(_db.prayerLog).insertOnConflictUpdate(day);
      }
      for (final setting in settings) {
        await _db.into(_db.settingsTable).insertOnConflictUpdate(setting);
      }
      return;
    }

    await _db.batch((batch) {
      batch.insertAll(_db.bookmarks, bookmarks);
      if (khatmaWrite != null) {
        if (khatmaRowId != null) {
          batch.update(
            _db.khatmaProgress,
            khatmaWrite,
            where: (t) => t.id.equals(khatmaRowId),
          );
        } else {
          batch.insert(_db.khatmaProgress, khatmaWrite);
        }
      }
      batch.insertAllOnConflictUpdate(_db.prayerLog, prayerDays);
      batch.insertAllOnConflictUpdate(_db.settingsTable, settings);
    });
  }

  /// Single khatma row: update in place when one exists, insert otherwise.
  Future<void> _writeKhatma(
    KhatmaProgressCompanion values,
    int? rowId,
  ) async {
    if (rowId == null) {
      await _db.into(_db.khatmaProgress).insert(values);
      return;
    }
    await (_db.update(_db.khatmaProgress)..where((t) => t.id.equals(rowId)))
        .write(values);
  }
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
