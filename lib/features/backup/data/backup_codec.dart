import 'dart:convert';

/// File-format constants for the user-controlled backup file (design spec §3).
const String kBackupAppId = 'quran_yahdi';
const int kBackupFormat = 1;
const int kBackupMaxBytes = 2 * 1024 * 1024;

/// One bookmarked ayah — `bookmarks` table.
class BackupBookmark {
  const BackupBookmark({required this.ayahId, required this.createdAt});

  final int ayahId;
  final DateTime createdAt;
}

/// One khatma/wird plan row — `khatma_progress` (single row by invariant).
class BackupKhatmaRow {
  const BackupKhatmaRow({
    required this.ayahId,
    required this.targetPages,
    required this.updatedAt,
  });

  final int ayahId;
  final int targetPages;
  final DateTime updatedAt;
}

/// One worship-tracker day — `prayer_log` (day PK + 5 bools).
class BackupPrayerDay {
  const BackupPrayerDay({
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
}

/// Tasbih state — settings key `tasbih_state` (`{count, target}`).
class BackupTasbih {
  const BackupTasbih({required this.count, required this.target});

  final int count;
  final int target;
}

/// The typed `data` payload of a backup document.
class BackupData {
  const BackupData({
    required this.bookmarks,
    required this.lastReadAyahId,
    required this.khatma,
    required this.prayerLog,
    required this.tasbih,
    required this.settings,
  });

  final List<BackupBookmark> bookmarks;
  final int? lastReadAyahId;
  final List<BackupKhatmaRow> khatma;
  final List<BackupPrayerDay> prayerLog;
  final BackupTasbih? tasbih;
  final Map<String, String> settings;
}

/// A decoded, typed backup document (wrapper metadata + typed data).
class BackupDocument {
  const BackupDocument({
    required this.exportedAt,
    required this.schemaVersion,
    required this.data,
  });

  final DateTime exportedAt;
  final int schemaVersion;
  final BackupData data;
}

/// Why a decode was rejected (fail-closed wrapper guards).
enum BackupDecodeFailureReason { tooLarge, malformed, wrongApp, wrongFormat }

/// Sealed decode outcome: either a typed document — plus the count of corrupt
/// entries that were skipped, never applied — or a fail-closed reason.
sealed class BackupDecodeResult {
  const BackupDecodeResult();
}

class BackupDecodeFailure extends BackupDecodeResult {
  const BackupDecodeFailure(this.reason);

  final BackupDecodeFailureReason reason;
}

class BackupDecodeSuccess extends BackupDecodeResult {
  const BackupDecodeSuccess({
    required this.document,
    required this.skippedEntries,
  });

  final BackupDocument document;
  final int skippedEntries;
}

/// Encodes [document] to the versioned UTF-8 JSON string (spec §3);
/// settings keys are sorted so identical state encodes identically.
String encode(BackupDocument document) {
  final data = document.data;
  final lastRead = data.lastReadAyahId;
  final tasbih = data.tasbih;
  final settings = Map<String, String>.of(data.settings);
  final sortedKeys = settings.keys.toList()..sort();
  return jsonEncode(<String, Object?>{
    'app': kBackupAppId,
    'format': kBackupFormat,
    'exportedAt': document.exportedAt.toIso8601String(),
    'schemaVersion': document.schemaVersion,
    'data': <String, Object?>{
      'bookmarks': [
        for (final bookmark in data.bookmarks)
          <String, Object?>{
            'ayahId': bookmark.ayahId,
            'createdAt': bookmark.createdAt.toIso8601String(),
          },
      ],
      'lastRead':
          lastRead == null ? null : <String, Object?>{'ayahId': lastRead},
      'khatma': [
        for (final row in data.khatma)
          <String, Object?>{
            'ayahId': row.ayahId,
            'targetPages': row.targetPages,
            'updatedAt': row.updatedAt.toIso8601String(),
          },
      ],
      'prayerLog': [
        for (final day in data.prayerLog)
          <String, Object?>{
            'day': day.day.toIso8601String(),
            'fajr': day.fajr,
            'dhuhr': day.dhuhr,
            'asr': day.asr,
            'maghrib': day.maghrib,
            'isha': day.isha,
          },
      ],
      'tasbih': tasbih == null
          ? null
          : <String, Object?>{'count': tasbih.count, 'target': tasbih.target},
      'settings': <String, String>{
        for (final key in sortedKeys) key: settings[key]!,
      },
    },
  });
}

/// Decodes [raw] with fail-closed wrapper guards (size cap before parsing;
/// `app`/`format` must match) and per-entry decode with skip+count for corrupt
/// entries — a corrupt entry never crashes and is never half-read. Unknown
/// keys are ignored; metadata (`exportedAt`, `schemaVersion`) is informational.
BackupDecodeResult decode(String raw) {
  if (utf8.encode(raw).length > kBackupMaxBytes) {
    return const BackupDecodeFailure(BackupDecodeFailureReason.tooLarge);
  }
  final Object? root;
  try {
    root = jsonDecode(raw);
  } on FormatException {
    return const BackupDecodeFailure(BackupDecodeFailureReason.malformed);
  }
  if (root is! Map<String, dynamic>) {
    return const BackupDecodeFailure(BackupDecodeFailureReason.malformed);
  }
  if (root['app'] != kBackupAppId) {
    return const BackupDecodeFailure(BackupDecodeFailureReason.wrongApp);
  }
  if (root['format'] != kBackupFormat) {
    return const BackupDecodeFailure(BackupDecodeFailureReason.wrongFormat);
  }

  final skipped = _SkipCounter();
  final exportedAtRaw = root['exportedAt'];
  final schemaRaw = root['schemaVersion'];
  return BackupDecodeSuccess(
    document: BackupDocument(
      exportedAt: exportedAtRaw is String
          ? DateTime.tryParse(exportedAtRaw) ?? _epoch
          : _epoch,
      schemaVersion: schemaRaw is num ? schemaRaw.toInt() : 0,
      data: _decodeData(root['data'], skipped),
    ),
    skippedEntries: skipped.value,
  );
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

class _SkipCounter {
  int value = 0;
}

BackupData _decodeData(Object? raw, _SkipCounter skipped) {
  if (raw is! Map<String, dynamic>) {
    if (raw != null) skipped.value++;
    return const BackupData(
      bookmarks: [],
      lastReadAyahId: null,
      khatma: [],
      prayerLog: [],
      tasbih: null,
      settings: {},
    );
  }
  return BackupData(
    bookmarks: _decodeList(raw['bookmarks'], skipped, _decodeBookmark),
    lastReadAyahId: _decodeLastRead(raw['lastRead'], skipped),
    khatma: _decodeList(raw['khatma'], skipped, _decodeKhatmaRow),
    prayerLog: _decodeList(raw['prayerLog'], skipped, _decodePrayerDay),
    tasbih: _decodeTasbih(raw['tasbih'], skipped),
    settings: _decodeSettings(raw['settings'], skipped),
  );
}

List<T> _decodeList<T>(
  Object? raw,
  _SkipCounter skipped,
  T? Function(Object?) decodeEntry,
) {
  if (raw == null) return <T>[];
  if (raw is! List) {
    skipped.value++;
    return <T>[];
  }
  final result = <T>[];
  for (final entry in raw) {
    final decoded = decodeEntry(entry);
    if (decoded == null) {
      skipped.value++;
    } else {
      result.add(decoded);
    }
  }
  return List<T>.unmodifiable(result);
}

BackupBookmark? _decodeBookmark(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final ayahId = raw['ayahId'];
  final createdAtRaw = raw['createdAt'];
  if (ayahId is! num || createdAtRaw is! String) return null;
  final createdAt = DateTime.tryParse(createdAtRaw);
  if (createdAt == null) return null;
  return BackupBookmark(ayahId: ayahId.toInt(), createdAt: createdAt);
}

int? _decodeLastRead(Object? raw, _SkipCounter skipped) {
  if (raw == null) return null;
  final ayahId = raw is Map<String, dynamic> ? raw['ayahId'] : null;
  if (ayahId is! num) {
    skipped.value++;
    return null;
  }
  return ayahId.toInt();
}

BackupKhatmaRow? _decodeKhatmaRow(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final ayahId = raw['ayahId'];
  final targetPages = raw['targetPages'];
  final updatedAtRaw = raw['updatedAt'];
  if (ayahId is! num || targetPages is! num || updatedAtRaw is! String) {
    return null;
  }
  final updatedAt = DateTime.tryParse(updatedAtRaw);
  if (updatedAt == null) return null;
  return BackupKhatmaRow(
    ayahId: ayahId.toInt(),
    targetPages: targetPages.toInt(),
    updatedAt: updatedAt,
  );
}

BackupPrayerDay? _decodePrayerDay(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final dayRaw = raw['day'];
  if (dayRaw is! String) return null;
  final day = DateTime.tryParse(dayRaw);
  if (day == null) return null;
  // Bools are read leniently (`== true`): a garbage slot decodes false, and
  // the OR-merge can never remove a true mark, so this is loss-free.
  return BackupPrayerDay(
    day: day,
    fajr: raw['fajr'] == true,
    dhuhr: raw['dhuhr'] == true,
    asr: raw['asr'] == true,
    maghrib: raw['maghrib'] == true,
    isha: raw['isha'] == true,
  );
}

BackupTasbih? _decodeTasbih(Object? raw, _SkipCounter skipped) {
  if (raw == null) return null;
  if (raw is! Map<String, dynamic>) {
    skipped.value++;
    return null;
  }
  final count = raw['count'];
  final target = raw['target'];
  if (count is! num || target is! num) {
    skipped.value++;
    return null;
  }
  return BackupTasbih(count: count.toInt(), target: target.toInt());
}

Map<String, String> _decodeSettings(Object? raw, _SkipCounter skipped) {
  if (raw == null) return const {};
  if (raw is! Map<String, dynamic>) {
    skipped.value++;
    return const {};
  }
  final result = <String, String>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is String) {
      result[entry.key] = value;
    } else {
      skipped.value++;
    }
  }
  return Map<String, String>.unmodifiable(result);
}
