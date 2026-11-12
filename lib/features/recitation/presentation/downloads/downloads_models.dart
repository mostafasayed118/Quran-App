part of 'downloads_cubit.dart';

/// One installed download with its display names resolved.
///
/// A read-side projection, not cubit state: the list is rebuilt from the
/// downloader on every read, so it never needs to ride the freezed state.
/// [reciterName] and [surahName] are empty when the catalog cannot resolve
/// them; the screen owns the localized fallback.
class InstalledDownload {
  /// Creates one row of the installed list.
  const InstalledDownload({
    required this.rowId,
    required this.surahNumber,
    required this.reciterName,
    required this.surahName,
    required this.bytes,
  });

  /// Reciter (moshaf) row id that owns the file.
  final String rowId;

  /// Surah number of the installed file.
  final int surahNumber;

  /// Display name of the reciter.
  final String reciterName;

  /// Display name of the surah.
  final String surahName;

  /// Size of the installed file in bytes.
  final int bytes;
}

/// How much space the installed downloads take, and in how many files.
///
/// Another read-side projection (see [InstalledDownload]) built on every
/// read: the registry is the owner, the cubit holds no copy.
class DownloadsSummary {
  /// Creates an aggregate of [count] files totalling [bytes].
  const DownloadsSummary({required this.count, required this.bytes});

  /// Number of installed files.
  final int count;

  /// Total size of the installed files, in bytes.
  final int bytes;
}
