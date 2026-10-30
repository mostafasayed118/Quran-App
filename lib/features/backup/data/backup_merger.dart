import '../../../core/utils/date_only.dart';
import 'backup_codec.dart';
import 'backup_inventory.dart';

/// Highest global ayah id (1..6236) accepted for the last-read pointer.
const int kBackupMaxAyahId = 6236;

/// Day-key normalization: local midnight; a day's identity is its local
/// calendar date. Shared through `core/utils/date_only.dart` so backup and the
/// tracker cannot drift apart (backup still imports no other feature).
DateTime backupDateOnly(DateTime d) => dateOnly(d);

/// Stable day key for merge batching (same shape as the tracker's own keys).
String backupDayKey(DateTime d) => dayKey(d);

/// Result of merging imported bookmarks with the local ones.
class BookmarkMerge {
  const BookmarkMerge(this.toInsert, {this.rejected = 0});

  /// Bookmarks that are new and must be written.
  final List<BackupBookmark> toInsert;

  /// Imported bookmarks whose ayah id was outside 1..6236.
  final int rejected;

  int get newCount => toInsert.length;
}

/// Union by `ayahId`: existing rows are kept (never deleted, never rewritten);
/// the file's first occurrence wins for duplicate ids inside the file.
BookmarkMerge mergeBookmarks({
  required Set<int> existingAyahIds,
  required List<BackupBookmark> imported,
}) {
  final seen = <int>{...existingAyahIds};
  final toInsert = <BackupBookmark>[];
  var rejected = 0;
  for (final bookmark in imported) {
    if (bookmark.ayahId < 1 || bookmark.ayahId > kBackupMaxAyahId) {
      rejected++;
      continue;
    }
    if (seen.add(bookmark.ayahId)) toInsert.add(bookmark);
  }
  return BookmarkMerge(
    List<BackupBookmark>.unmodifiable(toInsert),
    rejected: rejected,
  );
}

/// Result of merging the imported last-read position.
class LastReadMerge {
  const LastReadMerge({required this.toWrite, required this.changed});

  /// Ayah id to store, or null when nothing changes.
  final int? toWrite;

  /// True when the imported position differs from the stored one.
  final bool changed;
}

/// Import wins when present and valid (1..6236); otherwise no change.
LastReadMerge mergeLastRead({required int? existing, required int? imported}) {
  if (imported == null || imported < 1 || imported > kBackupMaxAyahId) {
    return const LastReadMerge(toWrite: null, changed: false);
  }
  return LastReadMerge(toWrite: imported, changed: imported != existing);
}

/// Result of merging the imported khatma plan.
class KhatmaMerge {
  const KhatmaMerge({
    required this.toWrite,
    required this.replaced,
    this.rejected = 0,
  });

  /// The plan row to write, or null to keep the current plan.
  final BackupKhatmaRow? toWrite;

  /// True when the imported plan replaced the existing one.
  final bool replaced;

  /// Imported rows with an out-of-range ayah id or a non-positive target.
  final int rejected;
}

/// Newer `updatedAt` wins (the file may carry several historical rows; the
/// newest one is the candidate). Empty target takes the file's newest plan.
KhatmaMerge mergeKhatma({
  required BackupKhatmaRow? existing,
  required List<BackupKhatmaRow> imported,
}) {
  BackupKhatmaRow? newest;
  var rejected = 0;
  for (final row in imported) {
    if (row.ayahId < 1 ||
        row.ayahId > kBackupMaxAyahId ||
        row.targetPages <= 0) {
      rejected++;
      continue;
    }
    if (newest == null || row.updatedAt.isAfter(newest.updatedAt)) newest = row;
  }
  if (newest == null) {
    return KhatmaMerge(toWrite: null, replaced: false, rejected: rejected);
  }
  if (existing == null) {
    return KhatmaMerge(
      toWrite: newest,
      replaced: true,
      rejected: rejected,
    );
  }
  if (newest.updatedAt.isAfter(existing.updatedAt)) {
    return KhatmaMerge(
      toWrite: newest,
      replaced: true,
      rejected: rejected,
    );
  }
  return KhatmaMerge(toWrite: null, replaced: false, rejected: rejected);
}

/// Result of merging the imported prayer log.
class PrayerLogMerge {
  const PrayerLogMerge(this.daysToWrite);

  /// Merged days that still have to be written.
  final List<BackupPrayerDay> daysToWrite;

  int get mergedDays => daysToWrite.length;
}

/// OR-merge per local day (`true` wins): only days that flip at least one
/// mark from false to true are written; days outside the file are untouched
/// (an import never deletes worship marks). Duplicate file days merge first.
PrayerLogMerge mergePrayerLog({
  required List<BackupPrayerDay> existing,
  required List<BackupPrayerDay> imported,
}) {
  final currentByDay = <String, BackupPrayerDay>{
    for (final day in existing) backupDayKey(backupDateOnly(day.day)): day,
  };
  final mergedByDay = <String, BackupPrayerDay>{};
  for (final day in imported) {
    final key = backupDayKey(backupDateOnly(day.day));
    final base = mergedByDay[key] ?? currentByDay[key];
    mergedByDay[key] = BackupPrayerDay(
      day: backupDateOnly(day.day),
      fajr: day.fajr || (base?.fajr ?? false),
      dhuhr: day.dhuhr || (base?.dhuhr ?? false),
      asr: day.asr || (base?.asr ?? false),
      maghrib: day.maghrib || (base?.maghrib ?? false),
      isha: day.isha || (base?.isha ?? false),
    );
  }
  final toWrite = <BackupPrayerDay>[];
  for (final entry in mergedByDay.entries) {
    final current = currentByDay[entry.key];
    if (current == null || _flipsMark(current, entry.value)) {
      toWrite.add(entry.value);
    }
  }
  return PrayerLogMerge(List<BackupPrayerDay>.unmodifiable(toWrite));
}

bool _flipsMark(BackupPrayerDay current, BackupPrayerDay merged) =>
    (merged.fajr && !current.fajr) ||
    (merged.dhuhr && !current.dhuhr) ||
    (merged.asr && !current.asr) ||
    (merged.maghrib && !current.maghrib) ||
    (merged.isha && !current.isha);

/// Result of merging the imported tasbih counter.
class TasbihMerge {
  const TasbihMerge({required this.toWrite, required this.countDelta});

  /// The counter to write, or null when nothing changed.
  final BackupTasbih? toWrite;

  /// How much the count grew against the stored value.
  final int countDelta;

  /// True when the merged counter differs from the stored one.
  bool get changed => toWrite != null;
}

/// `count` = max(current, imported); `target` = import wins when valid (> 0),
/// otherwise the existing target survives. Identical values write nothing.
TasbihMerge mergeTasbih({
  required BackupTasbih? existing,
  required BackupTasbih? imported,
}) {
  if (imported == null) return const TasbihMerge(toWrite: null, countDelta: 0);
  final currentCount = existing?.count ?? 0;
  final count = imported.count > currentCount ? imported.count : currentCount;
  final target = imported.target > 0
      ? imported.target
      : (existing?.target ?? imported.target);
  final merged = BackupTasbih(count: count, target: target);
  final changed = existing == null ||
      existing.count != merged.count ||
      existing.target != merged.target;
  return TasbihMerge(
    toWrite: changed ? merged : null,
    countDelta: count - currentCount,
  );
}

/// Result of merging imported settings.
class SettingsMerge {
  const SettingsMerge(this.toWrite);

  /// Settings that differ from the stored ones and must be written.
  final Map<String, String> toWrite;

  int get appliedCount => toWrite.length;
}

/// Whitelist-filtered import-wins: only whitelisted keys present in the file
/// are written, and only when the value actually differs.
SettingsMerge mergeSettings({
  required Map<String, String> existing,
  required Map<String, String> imported,
}) {
  final toWrite = <String, String>{};
  for (final entry in imported.entries) {
    if (!kBackupSettingsWhitelist.contains(entry.key)) continue;
    if (existing[entry.key] == entry.value) continue;
    toWrite[entry.key] = entry.value;
  }
  return SettingsMerge(Map<String, String>.unmodifiable(toWrite));
}

/// Per-entity summary of a plan (preview counts and apply outcome).
class BackupSummary {
  /// What a backup import changed, in numbers.
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
