/// Pure backup payload models.
///
/// The data layer (encode/decode/merge) and the presentation layer (freezed
/// states) both depend on these; they carry no file, DB or JSON concerns.
library;

/// One bookmarked ayah — `bookmarks` table.
class BackupBookmark {
  /// One exported bookmark.
  const BackupBookmark({required this.ayahId, required this.createdAt});

  /// Global ayah number that was bookmarked.
  final int ayahId;

  /// When the bookmark was created.
  final DateTime createdAt;
}

/// One khatma/wird plan row — `khatma_progress` (single row by invariant).
class BackupKhatmaRow {
  /// The exported khatma plan row.
  const BackupKhatmaRow({
    required this.ayahId,
    required this.targetPages,
    required this.updatedAt,
  });

  /// Global ayah number the plan was anchored at.
  final int ayahId;

  /// Page count the plan aimed to finish.
  final int targetPages;

  /// When the plan last moved.
  final DateTime updatedAt;
}

/// One worship-tracker day — `prayer_log` (day PK + 5 bools).
class BackupPrayerDay {
  /// One exported day of the prayer log.
  const BackupPrayerDay({
    required this.day,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// The calendar day this row describes.
  final DateTime day;

  /// Fajr was marked on [day].
  final bool fajr;

  /// Dhuhr was marked on [day].
  final bool dhuhr;

  /// Asr was marked on [day].
  final bool asr;

  /// Maghrib was marked on [day].
  final bool maghrib;

  /// Isha was marked on [day].
  final bool isha;
}

/// Tasbih state — settings key `tasbih_state` (`{count, target}`).
class BackupTasbih {
  /// The exported tasbih counter.
  const BackupTasbih({required this.count, required this.target});

  /// Current number of tasbih repetitions.
  final int count;

  /// Repetition goal for the tasbih counter.
  final int target;
}

/// The typed `data` payload of a backup document.
class BackupData {
  /// The payload of a backup: everything the app restores.
  const BackupData({
    required this.bookmarks,
    required this.lastReadAyahId,
    required this.khatma,
    required this.prayerLog,
    required this.tasbih,
    required this.settings,
  });

  /// Exported bookmarks.
  final List<BackupBookmark> bookmarks;

  /// Last ayah the user read, if any.
  final int? lastReadAyahId;

  /// Exported khatma plan rows.
  final List<BackupKhatmaRow> khatma;

  /// Exported prayer-log days.
  final List<BackupPrayerDay> prayerLog;

  /// Exported tasbih counter, when the user had one.
  final BackupTasbih? tasbih;

  /// Exported settings, key to raw string value.
  final Map<String, String> settings;
}

/// A decoded, typed backup document (wrapper metadata + typed data).
class BackupDocument {
  /// A backup file: the payload plus its envelope.
  const BackupDocument({
    required this.exportedAt,
    required this.schemaVersion,
    required this.data,
  });

  /// When the backup was produced.
  final DateTime exportedAt;

  /// Schema version of the payload, used to migrate old backups.
  final int schemaVersion;

  /// The payload itself.
  final BackupData data;
}

/// Why a decode was rejected (fail-closed wrapper guards).
enum BackupDecodeFailureReason {
  tooLarge,
  malformed,
  wrongApp,
  wrongFormat,

  /// The file is an encrypted backup envelope: it cannot be decoded without
  /// the user's passphrase. Surfaced so the importer can offer the prompt.
  encrypted,
}

/// Sealed decode outcome: either a typed document — plus the count of corrupt
/// entries that were skipped, never applied — or a fail-closed reason.
sealed class BackupDecodeResult {
  const BackupDecodeResult();
}

/// The backup file could not be decoded.
class BackupDecodeFailure extends BackupDecodeResult {
  const BackupDecodeFailure(this.reason);

  /// Why decoding failed.
  final BackupDecodeFailureReason reason;
}

/// The backup file decoded cleanly.
class BackupDecodeSuccess extends BackupDecodeResult {
  const BackupDecodeSuccess({
    required this.document,
    required this.skippedEntries,
  });

  /// The decoded document.
  final BackupDocument document;

  /// How many malformed entries were skipped while decoding.
  final int skippedEntries;
}

/// What a backup import changed, in numbers.
class BackupSummary {
  /// Counts of the applied or previewed merge.
  const BackupSummary({
    required this.newBookmarks,
    required this.mergedPrayerDays,
    required this.planReplaced,
    required this.tasbihCountDelta,
    required this.tasbihChanged,
    required this.lastReadChanged,
    required this.settingsKeysApplied,
    this.rejectedEntries = 0,
  });

  /// New bookmarks a merge would add (existing rows stay).
  final int newBookmarks;

  /// Worship days a merge would update (OR-flips only).
  final int mergedPrayerDays;

  /// Whether the khatma/wird plan row would be replaced by a newer one.
  final bool planReplaced;

  /// Tasbih count gain from the max-merge.
  final int tasbihCountDelta;

  /// Whether any tasbih field (count or target) would change.
  final bool tasbihChanged;

  /// Whether the last-read pointer would move.
  final bool lastReadChanged;

  /// Whitelisted settings keys that would be (re)written.
  final int settingsKeysApplied;

  /// Imported bookmark/khatma rows rejected by the id/range guards.
  final int rejectedEntries;

  /// True when the import changed nothing at all.
  bool get isEmpty =>
      newBookmarks == 0 &&
      mergedPrayerDays == 0 &&
      !planReplaced &&
      !tasbihChanged &&
      !lastReadChanged &&
      settingsKeysApplied == 0 &&
      rejectedEntries == 0;
}
