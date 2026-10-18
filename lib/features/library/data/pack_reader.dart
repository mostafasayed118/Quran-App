import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

/// Read side of the offline library packs: the bounded decoded-pack cache,
/// the per-pack ayah indexes, and the translation/tafsir/hadith read API.
///
/// Split out of the PackDownloader, which composes one and forwards to it.
/// The only writers of pack files (install/uninstall on the downloader) keep
/// the cache coherent by driving [prime] and [invalidate].
class PackReader {
  PackReader({
    required Future<dynamic> Function(String path) fileDecoder,
    required Future<String?> Function(String packId) packPath,
  })  : _fileDecoder = fileDecoder,
        _packPath = packPath;

  /// Decodes a pack file at [path] to its JSON value.
  ///
  /// Defaults to [decodeFileInIsolate]: cold decodes of multi-MB packs (the
  /// catalog's largest is ~82 MB) must never block the UI isolate. Widget
  /// tests inject a plain synchronous decoder instead — isolate completions
  /// never arrive under FakeAsync's fake clock (probe-verified), the same
  /// constraint that keeps the pack folder's mkdir synchronous.
  final Future<dynamic> Function(String path) _fileDecoder;

  static Future<dynamic> decodeFileInIsolate(String path) =>
      Isolate.run(() => jsonDecode(File(path).readAsStringSync()));

  /// Resolves an installed pack id to its file path, null when absent.
  final Future<String?> Function(String packId) _packPath;

  /// Decoded-pack cache: the read API is called per ayah-sheet open and per
  /// hadith page turn, and re-reading + re-decoding multi-MB pack files per
  /// call froze the app. Keyed by packId; the only writers of pack files
  /// (install/uninstall) invalidate it. Bounded: one decoded pack can be
  /// tens of MB of heap, so at most two entries survive (the ayah sheet's
  /// translation + tafsir pair), evicting least-recently-used first.
  final Map<String, dynamic> _decodedCache = {};

  static const int _decodedCacheMaxEntries = 2;

  /// Per-pack ayah lookup indexes (`surah * 1000 + ayah` → text), built once
  /// from the decoded pack and evicted together with [_decodedCache] — the
  /// flat tafsir wrapper holds up to ~6.2k entries and was scanned per sheet
  /// open.
  final Map<String, Map<int, String>> _ayahIndexCache = {};

  static int _ayahKey(int surah, int ayah) => surah * 1000 + ayah;

  void _dropAyahIndexes(String packId) {
    _ayahIndexCache.removeWhere((key, _) => key.startsWith('$packId#'));
  }

  void _cacheDecoded(String packId, dynamic decoded) {
    _decodedCache.remove(packId);
    _decodedCache[packId] = decoded;
    while (_decodedCache.length > _decodedCacheMaxEntries) {
      final evicted = _decodedCache.keys.first;
      _decodedCache.remove(evicted);
      _dropAyahIndexes(evicted);
    }
  }

  Map<int, String> _ayahIndex(String packId, String listKey, List list) {
    final cacheKey = '$packId#$listKey';
    return _ayahIndexCache.putIfAbsent(cacheKey, () {
      final index = <int, String>{};
      for (final entry in list) {
        if (entry is! Map<String, dynamic>) continue;
        final surah = entry['chapter'] ?? entry['surah'];
        final ayah = entry['verse'] ?? entry['ayah'];
        final text = entry['text'];
        if (surah is! num || ayah is! num || text is! String || text.isEmpty) {
          continue;
        }
        index[_ayahKey(surah.toInt(), ayah.toInt())] = text;
      }
      return index;
    });
  }

  /// Primes the decoded cache with a freshly installed pack, so the first
  /// read after install does not re-decode the file.
  void prime(String packId, dynamic decoded) => _cacheDecoded(packId, decoded);

  /// Drops a pack's decoded entry and its ayah indexes (install failure and
  /// uninstall both call this).
  void invalidate(String packId) {
    _decodedCache.remove(packId);
    _dropAyahIndexes(packId);
  }

  Future<dynamic> _decodeInstalled(String packId,
      {String? key, bool Function(List)? nonEmpty}) async {
    final path = await _packPath(packId);
    if (path == null) {
      _decodedCache.remove(packId);
      _dropAyahIndexes(packId);
      return null;
    }
    var decoded = _decodedCache[packId];
    if (decoded != null) {
      _cacheDecoded(packId, decoded); // LRU touch
    } else {
      try {
        decoded = await _fileDecoder(path);
      } on Object {
        return null; // corrupted pack reads as absent, never throws upward
      }
      _cacheDecoded(packId, decoded);
    }
    if (key != null && decoded is Map<String, dynamic>) {
      final list = decoded[key];
      if (list is! List || (nonEmpty != null && !nonEmpty(list))) return null;
      return list;
    }
    return decoded;
  }

  /// Translation text for an ayah from an installed translation pack.
  Future<String?> translationFor(String packId, int surah, int ayah) async {
    final list = await _decodeInstalled(packId, key: 'quran');
    if (list is! List) return null;
    return _ayahIndex(packId, 'quran', list)[_ayahKey(surah, ayah)];
  }

  /// Tafsir text for an ayah from an installed tafsir wrapper.
  Future<String?> tafsirFor(String packId, int surah, int ayah) async {
    final list = await _decodeInstalled(packId, key: 'tafsirs');
    if (list is! List) return null;
    return _ayahIndex(packId, 'tafsirs', list)[_ayahKey(surah, ayah)];
  }

  /// A paged window of an installed hadith pack:
  /// `([ (hadithnumber, text), ... ], hasMore)`.
  Future<(List<(int, String)>, bool)> hadithPage(
      String packId, int offset, int limit) async {
    final list = await _decodeInstalled(packId, key: 'hadiths');
    if (list is! List || offset >= list.length || offset < 0 || limit <= 0) {
      return (const <(int, String)>[], false);
    }
    final end = (offset + limit).clamp(0, list.length);
    final out = <(int, String)>[];
    for (final entry in list.sublist(offset, end)) {
      if (entry is Map<String, dynamic>) {
        final rawNumber = entry['hadithnumber'];
        final number = rawNumber is num ? rawNumber.toInt() : null;
        final text = entry['text'];
        if (number != null && text is String) {
          out.add((number, text));
        }
      }
    }
    return (out, end < list.length);
  }
}
