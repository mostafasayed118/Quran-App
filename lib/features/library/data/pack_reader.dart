import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

/// Read side of the offline library packs: the bounded projection cache, the
/// per-pack ayah indexes, and the translation/tafsir/hadith read API.
///
/// Split out of the PackDownloader, which composes one and forwards to it.
/// The only writers of pack files (install/uninstall on the downloader) keep
/// the cache coherent by driving the prime APIs and [invalidate].
///
/// Memory discipline: a decoded pack is a deep JSON tree of tens of MB, so it
/// is never retained and — on the production path — never crosses an isolate
/// port. Cold reads project the file down to the structure the UI needs (an
/// ayah index, or the compact `(hadithnumber, text)` list) inside ONE worker
/// isolate; the cache only ever holds those projections.
class PackReader {
  PackReader({
    Future<dynamic> Function(String path)? fileDecoder,
    required Future<String?> Function(String packId) packPath,
  })  : _fileDecoder = fileDecoder,
        _packPath = packPath;

  /// The injectable decode seam, returning the DECODED JSON TREE for [path].
  ///
  /// Nullable by design: widget tests inject a plain synchronous tree decoder
  /// (isolate completions never arrive under FakeAsync's fake clock —
  /// probe-verified), while production leaves it null so cold reads take the
  /// isolate-projection path below.
  final Future<dynamic> Function(String path)? _fileDecoder;

  /// Resolves an installed pack id to its file path, null when absent.
  final Future<String?> Function(String packId) _packPath;

  /// Bounded projection cache: an ayah index (`surah * 1000 + ayah` → text)
  /// for translation/tafsir packs, the compact `(number, text)` list for
  /// hadith packs. Keyed by packId for full-pack entries and by the
  /// `packId#surah` slice form for single-surah reads, LRU-touched on every
  /// prime and read, capped at two entries (the ayah sheet's translation +
  /// tafsir pair) AND at [_decodedCacheMaxBytes] of estimated payload.
  final Map<String, Object> _cache = {};

  /// The estimated retained bytes of every entry currently in [_cache]; kept
  /// exact by [_remove] so eviction never has to rescan the projections.
  int _cacheBytes = 0;

  static const int _decodedCacheMaxEntries = 2;

  static const int _decodedCacheMaxBytes = 24 * 1024 * 1024;

  /// Per-pack-and-surah single-flight: concurrent cold reads of the same
  /// cache key share one in-flight projection instead of each starting their
  /// own decode.
  final Map<String, Future<Object?>> _inFlight = {};

  /// Global decode serialization: a cold decode is only started once the
  /// previous one has settled, so at most ONE multi-MB decode is in flight.
  /// The chain swallows errors, so a failed decode never wedges the queue.
  Future<void> _decodeQueue = Future<void>.value();

  static int _ayahKey(int surah, int ayah) => surah * 1000 + ayah;

  /// Cache key holding [packId]'s projection for one [surah]; the bare packId
  /// key holds the full-pack projection.
  static String _cacheKey(String packId, int? surah) =>
      surah == null ? packId : '$packId#$surah';

  /// Builds the `surah * 1000 + ayah` → text lookup from a pack entry list.
  ///
  /// Shared by the injected-decoder path (main isolate), the production path
  /// (inside the projection isolate) and the tafsir installer (per-surah
  /// merge). Keys are global, so merging per-surah lists is exact.
  /// A non-null [surah] keeps only that surah's entries.
  static Map<int, String> buildAyahIndex(List list, {int? surah}) {
    final index = <int, String>{};
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) continue;
      final entrySurah = entry['chapter'] ?? entry['surah'];
      if (surah != null && entrySurah != surah) continue;
      final ayah = entry['verse'] ?? entry['ayah'];
      final text = entry['text'];
      if (entrySurah is! num ||
          ayah is! num ||
          text is! String ||
          text.isEmpty) {
        continue;
      }
      index[_ayahKey(entrySurah.toInt(), ayah.toInt())] = text;
    }
    return index;
  }

  /// Builds the compact `(hadithnumber, text)` slot list from a pack entry
  /// list.
  ///
  /// The raw decoded entries are deep maps, but only the number and the text
  /// ever reach the UI — retaining the maps keeps the whole tree alive. A
  /// malformed slot stays as `null` so window offsets and `hasMore` keep the
  /// behaviour of the raw list. Shared by the projection path, the install
  /// sniff and [primeList].
  static List<(int, String)?> buildHadithList(List list) {
    final out = <(int, String)?>[];
    for (final entry in list) {
      if (entry is! Map<String, dynamic>) {
        out.add(null);
        continue;
      }
      final rawNumber = entry['hadithnumber'];
      final text = entry['text'];
      out.add(rawNumber is num && text is String
          ? (rawNumber.toInt(), text)
          : null);
    }
    return out;
  }

  /// True when [cached] is a projection of the shape [key] resolves to.
  static bool _matchesKind(Object? cached, String key) =>
      key == 'hadiths' ? cached is List : cached is Map<int, String>;

  /// Rough retained-size estimate of one cached projection: two bytes per
  /// UTF-16 code unit plus a small per-entry allowance for the container and
  /// the key. Unknown shapes count as zero (the cache only holds the two
  /// projections above).
  static int _estimateBytes(Object value) {
    if (value is Map<int, String>) {
      var bytes = 0;
      for (final text in value.values) {
        bytes += text.length * 2 + 32;
      }
      return bytes;
    }
    if (value is List<(int, String)?>) {
      var bytes = 0;
      for (final entry in value) {
        if (entry != null) bytes += entry.$2.length * 2 + 24;
      }
      return bytes;
    }
    return 0;
  }

  /// Drops [packId] from the cache, keeping the byte accounting exact.
  Object? _remove(String packId) {
    final removed = _cache.remove(packId);
    if (removed != null) _cacheBytes -= _estimateBytes(removed);
    return removed;
  }

  /// Drops [packId]'s full-pack entry plus its slice for [surah], or every
  /// `packId#...` slice when [surah] is null.
  void _removePack(String packId, {int? surah}) {
    _remove(packId);
    if (surah != null) {
      _remove(_cacheKey(packId, surah));
      return;
    }
    final prefix = '$packId#';
    for (final key in _cache.keys.where((k) => k.startsWith(prefix)).toList()) {
      _remove(key);
    }
  }

  /// Moves [packId] to the most-recently-used end without changing the size.
  void _touch(String packId) {
    final value = _cache.remove(packId);
    if (value != null) _cache[packId] = value;
  }

  /// Inserts [value] as the most-recently-used entry, evicting the LRU tail
  /// until BOTH the entry-count and the byte budget hold.
  ///
  /// A projection that alone exceeds the byte budget is never inserted: adding
  /// it would evict every other entry (and then itself) for no benefit.
  void _write(String packId, Object value) {
    final bytes = _estimateBytes(value);
    _remove(packId);
    if (bytes > _decodedCacheMaxBytes) return;
    _cache[packId] = value;
    _cacheBytes += bytes;
    while (_cache.isNotEmpty &&
        (_cache.length > _decodedCacheMaxEntries ||
            _cacheBytes > _decodedCacheMaxBytes)) {
      _remove(_cache.keys.first);
    }
  }

  /// Primes a freshly installed translation/tafsir pack with its ayah index,
  /// so the first read after install does not re-decode the file.
  void primeAyahIndex(String packId, Map<int, String> index) =>
      _write(packId, index);

  /// Primes a freshly installed hadith pack with its compact pair list; a raw
  /// entry list is normalized on the way in.
  void primeList(String packId, List list) {
    final compact = list is List<(int, String)?> ? list : buildHadithList(list);
    _write(packId, compact);
  }

  /// Projects an installed hadith pack file to the compact `(number, text)`
  /// list inside a worker isolate.
  ///
  /// This is the DB importer's cold path: only the projection crosses the
  /// port, mirroring the read path's memory discipline.
  static Future<List<(int, String)?>?> decodeHadithProjectionInIsolate(
      String path) async {
    final result = await _decodeProjectionInIsolate(path, 'hadiths');
    return result is List<(int, String)?> ? result : null;
  }

  /// Drops a pack's cached projection and every per-surah slice (install
  /// failure and uninstall both call this).
  void invalidate(String packId) {
    _removePack(packId);
  }

  /// Estimated retained bytes of the decoded projections (test/diagnostic).
  int get cachedBytes => _cacheBytes;

  /// Drops every decoded projection. Called when the app is backgrounded;
  /// the next read re-decodes from disk.
  void trim() {
    _cache.clear();
    _cacheBytes = 0;
  }

  /// Production cold decode: reads, parses AND projects inside the isolate.
  /// Only the projection crosses the port; an absent/unreadable/corrupt file
  /// projects to null (the same "absent" semantics the read API exposes).
  static Future<Object?> _decodeProjectionInIsolate(String path, String key,
          {int? surah}) =>
      Isolate.run(() => _projectFile(path, key, surah: surah));

  static Object? _projectFile(String path, String key, {int? surah}) {
    dynamic decoded;
    try {
      decoded = jsonDecode(File(path).readAsStringSync());
    } on Object {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final list = decoded[key];
    if (list is! List) return null;
    return _projectList(key, list, surah: surah);
  }

  /// Projects a decoded entry list to what the read API actually needs.
  static Object? _projectList(String key, List list, {int? surah}) =>
      key == 'hadiths'
          ? buildHadithList(list)
          : buildAyahIndex(list, surah: surah);

  /// One cold decode through the injected seam (tree on the main isolate) or
  /// through the production isolate projection. Never throws: failures read
  /// as absent.
  Future<Object?> _decode(String path, String key, {int? surah}) async {
    final injected = _fileDecoder;
    if (injected == null) {
      try {
        return await _decodeProjectionInIsolate(path, key, surah: surah);
      } on Object {
        return null;
      }
    }
    try {
      final decoded = await injected(path);
      if (decoded is! Map<String, dynamic>) return null;
      final list = decoded[key];
      if (list is! List) return null;
      return _projectList(key, list, surah: surah);
    } on Object {
      return null;
    }
  }

  /// Schedules one decode for [cacheKey], sharing it with concurrent readers
  /// and chaining it behind every earlier decode.
  Future<Object?> _scheduledDecode(String cacheKey, String path, String key,
      {int? surah}) {
    final pending = _inFlight[cacheKey];
    if (pending != null) return pending;
    final task = _decodeQueue.then((_) => _decode(path, key, surah: surah));
    _inFlight[cacheKey] = task;
    final settled = task.then<void>((_) {}, onError: (Object _) {});
    _decodeQueue = settled;
    settled.whenComplete(() {
      if (identical(_inFlight[cacheKey], task)) _inFlight.remove(cacheKey);
    });
    return task;
  }

  /// Returns the cached projection for [packId] when it matches [key],
  /// otherwise schedules a cold decode and caches its projection.
  ///
  /// With [surah], the primed full-pack index is preferred (it already holds
  /// every surah), then the `packId#surah` slice; a cold decode only keeps
  /// that one surah, so a huge tafsir index stays out of the byte budget.
  ///
  /// Trade-off: the pack format has no random access, so a cold slice decode
  /// still parses the whole file; that CPU cost is paid once per surah instead
  /// of retaining the full index in memory.
  Future<Object?> _load(String packId, String key, {int? surah}) async {
    final path = await _packPath(packId);
    if (path == null) {
      _removePack(packId, surah: surah);
      return null;
    }
    final cached = _cache[packId];
    if (_matchesKind(cached, key)) {
      _touch(packId);
      return cached;
    }
    final cacheKey = _cacheKey(packId, surah);
    if (surah != null) {
      final slice = _cache[cacheKey];
      if (_matchesKind(slice, key)) {
        _touch(cacheKey);
        return slice;
      }
    }
    final projection =
        await _scheduledDecode(cacheKey, path, key, surah: surah);
    if (projection == null) return null;
    _write(cacheKey, projection);
    return projection;
  }

  /// Translation text for an ayah from an installed translation pack.
  Future<String?> translationFor(String packId, int surah, int ayah) async {
    final index = await _load(packId, 'quran', surah: surah);
    if (index is! Map<int, String>) return null;
    return index[_ayahKey(surah, ayah)];
  }

  /// Tafsir text for an ayah from an installed tafsir wrapper.
  Future<String?> tafsirFor(String packId, int surah, int ayah) async {
    final index = await _load(packId, 'tafsirs', surah: surah);
    if (index is! Map<int, String>) return null;
    return index[_ayahKey(surah, ayah)];
  }

  /// A paged window of an installed hadith pack:
  /// `([ (hadithnumber, text), ... ], hasMore)`.
  Future<(List<(int, String)>, bool)> hadithPage(
      String packId, int offset, int limit) async {
    final list = await _load(packId, 'hadiths');
    if (list is! List || offset >= list.length || offset < 0 || limit <= 0) {
      return (const <(int, String)>[], false);
    }
    final end = (offset + limit).clamp(0, list.length);
    final out = <(int, String)>[];
    for (final entry in list.sublist(offset, end)) {
      if (entry is (int, String)) out.add(entry);
    }
    return (out, end < list.length);
  }
}
