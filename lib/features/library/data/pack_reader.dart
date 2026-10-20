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
/// ayah index, or the raw hadith list) inside ONE worker isolate; the cache
/// only ever holds those projections.
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
  /// for translation/tafsir packs, the raw hadith list for hadith packs.
  /// Keyed by packId, LRU-touched on every prime and read, capped at exactly
  /// two entries (the ayah sheet's translation + tafsir pair).
  final Map<String, Object> _cache = {};

  static const int _decodedCacheMaxEntries = 2;

  /// Per-pack single-flight: concurrent cold reads of the same pack share one
  /// in-flight projection instead of each starting their own decode.
  final Map<String, Future<Object?>> _inFlight = {};

  /// Global decode serialization: a cold decode is only started once the
  /// previous one has settled, so at most ONE multi-MB decode is in flight.
  /// The chain swallows errors, so a failed decode never wedges the queue.
  Future<void> _decodeQueue = Future<void>.value();

  static int _ayahKey(int surah, int ayah) => surah * 1000 + ayah;

  /// Builds the `surah * 1000 + ayah` → text lookup from a pack entry list.
  ///
  /// Shared by the injected-decoder path (main isolate), the production path
  /// (inside the projection isolate) and the tafsir installer (per-surah
  /// merge). Keys are global, so merging per-surah lists is exact.
  static Map<int, String> buildAyahIndex(List list) {
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
  }

  /// True when [cached] is a projection of the shape [key] resolves to.
  static bool _matchesKind(Object? cached, String key) =>
      key == 'hadiths' ? cached is List : cached is Map<int, String>;

  /// Moves [packId] to the most-recently-used end without changing the size.
  void _touch(String packId) {
    final value = _cache.remove(packId);
    if (value != null) _cache[packId] = value;
  }

  /// Inserts [value] as the most-recently-used entry, evicting the LRU tail.
  void _write(String packId, Object value) {
    _cache.remove(packId);
    _cache[packId] = value;
    while (_cache.length > _decodedCacheMaxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Primes a freshly installed translation/tafsir pack with its ayah index,
  /// so the first read after install does not re-decode the file.
  void primeAyahIndex(String packId, Map<int, String> index) =>
      _write(packId, index);

  /// Primes a freshly installed hadith pack with its raw entry list.
  void primeList(String packId, List list) => _write(packId, list);

  /// Drops a pack's cached projection (install failure and uninstall both
  /// call this).
  void invalidate(String packId) {
    _cache.remove(packId);
  }

  /// Production cold decode: reads, parses AND projects inside the isolate.
  /// Only the projection crosses the port; an absent/unreadable/corrupt file
  /// projects to null (the same "absent" semantics the read API exposes).
  static Future<Object?> _decodeProjectionInIsolate(String path, String key) =>
      Isolate.run(() => _projectFile(path, key));

  static Object? _projectFile(String path, String key) {
    dynamic decoded;
    try {
      decoded = jsonDecode(File(path).readAsStringSync());
    } on Object {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final list = decoded[key];
    if (list is! List) return null;
    return _projectList(key, list);
  }

  /// Projects a decoded entry list to what the read API actually needs.
  static Object? _projectList(String key, List list) =>
      key == 'hadiths' ? list : buildAyahIndex(list);

  /// One cold decode through the injected seam (tree on the main isolate) or
  /// through the production isolate projection. Never throws: failures read
  /// as absent.
  Future<Object?> _decode(String path, String key) async {
    final injected = _fileDecoder;
    if (injected == null) {
      try {
        return await _decodeProjectionInIsolate(path, key);
      } on Object {
        return null;
      }
    }
    try {
      final decoded = await injected(path);
      if (decoded is! Map<String, dynamic>) return null;
      final list = decoded[key];
      if (list is! List) return null;
      return _projectList(key, list);
    } on Object {
      return null;
    }
  }

  /// Schedules one decode for [packId], sharing it with concurrent readers and
  /// chaining it behind every earlier decode.
  Future<Object?> _scheduledDecode(String packId, String path, String key) {
    final pending = _inFlight[packId];
    if (pending != null) return pending;
    final task = _decodeQueue.then((_) => _decode(path, key));
    _inFlight[packId] = task;
    final settled = task.then<void>((_) {}, onError: (Object _) {});
    _decodeQueue = settled;
    settled.whenComplete(() {
      if (identical(_inFlight[packId], task)) _inFlight.remove(packId);
    });
    return task;
  }

  /// Returns the cached projection for [packId] when it matches [key],
  /// otherwise schedules a cold decode and caches its projection.
  Future<Object?> _load(String packId, String key) async {
    final path = await _packPath(packId);
    if (path == null) {
      _cache.remove(packId);
      return null;
    }
    final cached = _cache[packId];
    if (_matchesKind(cached, key)) {
      _touch(packId);
      return cached;
    }
    final projection = await _scheduledDecode(packId, path, key);
    if (projection == null) return null;
    _write(packId, projection);
    return projection;
  }

  /// Translation text for an ayah from an installed translation pack.
  Future<String?> translationFor(String packId, int surah, int ayah) async {
    final index = await _load(packId, 'quran');
    if (index is! Map<int, String>) return null;
    return index[_ayahKey(surah, ayah)];
  }

  /// Tafsir text for an ayah from an installed tafsir wrapper.
  Future<String?> tafsirFor(String packId, int surah, int ayah) async {
    final index = await _load(packId, 'tafsirs');
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
