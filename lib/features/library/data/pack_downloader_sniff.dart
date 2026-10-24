part of 'pack_downloader.dart';

/// Decodes a batch of tafsir surah bodies in ONE worker isolate and returns
/// ONLY what the install needs: the ayah index and the array interior the
/// wrapper splices verbatim. The per-surah sha256 check and the JSON parse
/// never run on the UI isolate.
///
/// The bodies are [Uint8List]s, so they cross the isolate port zero-copy.
Future<List<_SurahProjection>> _decodeSurahs(
  List<Uint8List> bodies,
  List<int> numbers,
  List<String?> expectedHashes,
) =>
    Isolate.run(() => [
          for (var i = 0; i < numbers.length; i++)
            _projectSurah(bodies[i], expectedHashes[i]),
        ]);

/// The worker-side projection of one surah body.
///
/// The pinned hash is checked BEFORE the body is decoded; a mismatch returns
/// the [_shaMismatchError] sentinel with an empty projection. [error] is
/// otherwise the shape failure (null when the body is valid); a body that is
/// not JSON at all throws inside the worker and the failure reaches the caller
/// unchanged.
_SurahProjection _projectSurah(List<int> bytes, String? expectedSha) {
  if (expectedSha != null && sha256.convert(bytes).toString() != expectedSha) {
    return const (
      error: _shaMismatchError,
      index: <int, String>{},
      interior: '',
    );
  }
  final body = utf8.decode(bytes);
  final perSurah = jsonDecode(body);
  if (perSurah is! List || perSurah.isEmpty) {
    return const (
      error: 'empty or not an array',
      index: <int, String>{},
      interior: '',
    );
  }
  final trimmed = body.trim();
  if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
    return const (
      error: 'not a JSON array',
      index: <int, String>{},
      interior: '',
    );
  }
  final interior = trimmed.substring(1, trimmed.length - 1).trim();
  if (interior.isEmpty) {
    return const (
      error: 'empty',
      index: <int, String>{},
      interior: '',
    );
  }
  return (
    error: null,
    index: PackReader.buildAyahIndex(perSurah),
    interior: interior,
  );
}

/// The production sniff: the decode, the shape check and the projection all
/// happen inside one worker isolate — only the verdict and the projection
/// cross the port.
Future<_SniffResult> _sniffInIsolate(String path, LibraryPackInfo pack) =>
    Isolate.run(() {
      dynamic decoded;
      try {
        decoded = jsonDecode(File(path).readAsStringSync());
      } on Object {
        return const (error: _SniffError.parse, projection: null);
      }
      return _sniffTree(decoded, pack);
    });

/// The shape check and the projection of an already-decoded pack tree.
_SniffResult _sniffTree(dynamic decoded, LibraryPackInfo pack) {
  final map = decoded;
  if (map is! Map<String, dynamic>) {
    return const (error: _SniffError.notObject, projection: null);
  }
  switch (pack.kind) {
    case LibraryPackKind.translation:
      final list = map['quran'];
      if (list is! List || list.isEmpty) {
        return const (error: _SniffError.quran, projection: null);
      }
      return (error: null, projection: PackReader.buildAyahIndex(list));
    case LibraryPackKind.hadith:
      final list = map['hadiths'];
      if (list is! List || list.isEmpty) {
        return const (error: _SniffError.hadiths, projection: null);
      }
      return (error: null, projection: PackReader.buildHadithList(list));
    case LibraryPackKind.tafsir:
      if (map['pack'] != pack.id) {
        return const (error: _SniffError.packMismatch, projection: null);
      }
      final list = map['tafsirs'];
      if (list is! List || list.isEmpty) {
        return const (error: _SniffError.noTafsirs, projection: null);
      }
      return (error: null, projection: PackReader.buildAyahIndex(list));
  }
}

/// The failure message of a sniff verdict (verbatim, per pack kind).
String _sniffFailureMessage(_SniffError error, String packId) =>
    switch (error) {
      _SniffError.parse => 'downloaded pack "$packId" did not parse as JSON',
      _SniffError.notObject => 'downloaded pack "$packId" is not a JSON object',
      _SniffError.quran => 'pack "$packId" missing a non-empty quran list',
      _SniffError.hadiths => 'pack "$packId" missing a non-empty hadiths list',
      _SniffError.packMismatch => 'wrapper pack mismatch for "$packId"',
      _SniffError.noTafsirs => 'wrapper for "$packId" has no tafsirs',
    };
