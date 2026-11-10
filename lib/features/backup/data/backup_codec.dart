import 'dart:convert';

import '../domain/backup_models.dart';

// Compat: existing importers of this file keep resolving the backup models,
// which now live in domain/ so presentation stays off the data layer.
export '../domain/backup_models.dart';

/// File-format constants for the user-controlled backup file (design spec §3).
const String kBackupAppId = 'quran_yahdi';
const int kBackupFormat = 1;
const int kBackupMaxBytes = 2 * 1024 * 1024;

/// Encodes [document] to the versioned UTF-8 JSON string (spec §3);
/// settings keys are sorted so identical state encodes identically.
String encode(BackupDocument document) => jsonEncode(encodeMap(document));

/// The versioned JSON payload of [document] as sendable primitives — the
/// exact map [encode] serializes, so the JSON can be built on a worker
/// isolate. Settings keys are sorted so identical state encodes identically.
Map<String, Object?> encodeMap(BackupDocument document) {
  final data = document.data;
  final lastRead = data.lastReadAyahId;
  final tasbih = data.tasbih;
  final sortedSettings = data.settings.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return <String, Object?>{
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
        for (final entry in sortedSettings) entry.key: entry.value,
      },
    },
  };
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
