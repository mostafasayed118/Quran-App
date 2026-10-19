import 'backup_codec.dart';
import 'backup_inventory.dart';

/// Highest global ayah id (1..6236) accepted for the last-read pointer.
const int kBackupMaxAyahId = 6236;

/// Day-key normalization mirroring `prayer_log_repository.dart`'s convention:
/// local midnight; a day's identity is its local calendar date. The rule is
/// replicated (not imported) because backup production code is forbidden from
/// importing other features.
DateTime backupDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Stable day key for merge batching (same shape as the tracker's own keys).
String backupDayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

class BookmarkMerge {
  const BookmarkMerge(this.toInsert);

  final List<BackupBookmark> toInsert;

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
  for (final bookmark in imported) {
    if (seen.add(bookmark.ayahId)) toInsert.add(bookmark);
  }
  return BookmarkMerge(List<BackupBookmark>.unmodifiable(toInsert));
}

class LastReadMerge {
  const LastReadMerge({required this.toWrite, required this.changed});

  final int? toWrite;
  final bool changed;
}

/// Import wins when present and valid (1..6236); otherwise no change.
LastReadMerge mergeLastRead({required int? existing, required int? imported}) {
  if (imported == null || imported < 1 || imported > kBackupMaxAyahId) {
    return const LastReadMerge(toWrite: null, changed: false);
  }
  return LastReadMerge(toWrite: imported, changed: imported != existing);
}

class KhatmaMerge {
  const KhatmaMerge({required this.toWrite, required this.replaced});

  final BackupKhatmaRow? toWrite;
  final bool replaced;
}

/// Newer `updatedAt` wins (the file may carry several historical rows; the
/// newest one is the candidate). Empty target takes the file's newest plan.
KhatmaMerge mergeKhatma({
  required BackupKhatmaRow? existing,
  required List<BackupKhatmaRow> imported,
}) {
  BackupKhatmaRow? newest;
  for (final row in imported) {
    if (newest == null || row.updatedAt.isAfter(newest.updatedAt)) newest = row;
  }
  if (newest == null) return const KhatmaMerge(toWrite: null, replaced: false);
  if (existing == null) return KhatmaMerge(toWrite: newest, replaced: true);
  if (newest.updatedAt.isAfter(existing.updatedAt)) {
    return KhatmaMerge(toWrite: newest, replaced: true);
  }
  return const KhatmaMerge(toWrite: null, replaced: false);
}

class PrayerLogMerge {
  const PrayerLogMerge(this.daysToWrite);

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

class TasbihMerge {
  const TasbihMerge({required this.toWrite, required this.countDelta});

  final BackupTasbih? toWrite;
  final int countDelta;

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

class SettingsMerge {
  const SettingsMerge(this.toWrite);

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
  const BackupSummary({
    required this.newBookmarks,
    required this.mergedPrayerDays,
    required this.planReplaced,
    required this.tasbihCountDelta,
    required this.tasbihChanged,
    required this.lastReadChanged,
    required this.settingsKeysApplied,
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

  bool get isEmpty =>
      newBookmarks == 0 &&
      mergedPrayerDays == 0 &&
      !planReplaced &&
      !tasbihChanged &&
      !lastReadChanged &&
      settingsKeysApplied == 0;
}
