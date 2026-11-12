part of 'pack_downloader.dart';

/// The install pipeline: stream a pack into its dot-part, hash/shape-verify
/// it, promote the file and register the row.
///
/// Owns no in-flight state — [PackDownloader] keeps the single-flight gate,
/// the progress map and the broadcast, and hands [install] a progress
/// callback that fans out to both.
class _PackInstaller {
  _PackInstaller({
    required AppDatabase db,
    required Dio dio,
    required PackStore store,
    required PackReader reader,
    required HadithStore hadithStore,
    required Future<dynamic> Function(String path)? fileDecoder,
  })  : _db = db,
        _dio = dio,
        _store = store,
        _reader = reader,
        _hadithStore = hadithStore,
        _fileDecoder = fileDecoder;

  final AppDatabase _db;
  final Dio _dio;
  final PackStore _store;
  final PackReader _reader;
  final HadithStore _hadithStore;
  final Future<dynamic> Function(String path)? _fileDecoder;

  Future<File> install(
    LibraryPackInfo pack, {
    void Function(int received, int total)? onProgress,
  }) async {
    final finalFile = await _store.packFile(pack.id);
    final partFile = _store.partFileFor(finalFile);
    try {
      // Tafsir only: the ayah index merged from the per-surah bodies during
      // the install loop, so the wrapper never has to be decoded again just to
      // prime the read cache.
      final mergedIndex = await _writePack(pack, partFile, onProgress);
      // A tafsir pack pinned per surah needs no end-of-install wrapper
      // decode: every served byte was hash-verified and the wrapper itself is
      // written here. Unpinned tafsirs keep the full-wrapper sniff as the
      // validation gate.
      final pinnedTafsir =
          pack.kind == LibraryPackKind.tafsir && pack.sha256PerSurah != null;
      if (!pinnedTafsir) {
        // An unpinned pack is validated by SHAPE only - the degradation must
        // never be silent. The bundled catalog is fully pinned (the loader
        // gate), so this only fires for a pack that reached the downloader
        // without its integrity hashes.
        final gap = catalogIntegrityGap(pack);
        if (gap != null) {
          appLog(
              'pack "${pack.id}" is not integrity-pinned ($gap): the install is validated by shape only',
              name: 'quran_yahdi/library');
        }
      }
      final projection = pinnedTafsir ? null : await _sniffPack(pack, partFile);
      final promoted = await _store.promote(partFile);
      try {
        await _registerRow(pack, promoted);
      } on Object {
        // The file was promoted before the registry row was written. Leaving
        // it behind would create an invisible multi-MB orphan that the next
        // install overwrites and `uninstall` can never reach.
        await _store.deleteIfExists(promoted);
        rethrow;
      }
      await _importHadith(pack, projection);
      _primeReadCache(pack, mergedIndex, projection);
      return promoted;
    } on Object {
      _reader.invalidate(pack.id);
      await _store.deleteIfExists(partFile);
      rethrow;
    }
  }

  /// Streams the pack into its dot-part file.
  ///
  /// Returns the merged ayah index (tafsir only); the other kinds return
  /// null because their index is built by the install sniff.
  Future<Map<int, String>?> _writePack(
    LibraryPackInfo pack,
    File partFile,
    void Function(int received, int total)? onProgress,
  ) async {
    final expectedBytes = (pack.approxSizeMb * 1024 * 1024).round();
    final throttle = ProgressThrottle();
    final sink = partFile.openWrite();
    Map<int, String>? mergedIndex;
    try {
      switch (pack.kind) {
        case LibraryPackKind.tafsir:
          if (pack.urlTemplate == null) {
            await _writeSingleFile(
                pack, sink, expectedBytes, throttle, onProgress);
          } else {
            mergedIndex = await _writeTafsir(
                pack, sink, expectedBytes, throttle, onProgress);
          }
        case LibraryPackKind.translation:
        case LibraryPackKind.hadith:
          await _writeSingleFile(
              pack, sink, expectedBytes, throttle, onProgress);
      }
      await sink.flush();
    } on Object {
      await sink.close();
      rethrow;
    }
    await sink.close();
    return mergedIndex;
  }

  /// The tafsir install loop: one GET per surah, hash-verified BEFORE its
  /// body is decoded, spliced verbatim into the documented wrapper.
  ///
  /// The surahs are fetched with BOUNDED concurrency (a window of
  /// [_tafsirBatchSize] requests in flight) and decoded in batches - one
  /// worker isolate per batch, not one per surah. The wrapper is still
  /// written in surah order, and every body is hash-verified inside the
  /// worker before it is decoded or spliced, so the sha256 gate stays exactly
  /// as strict.
  Future<Map<int, String>> _writeTafsir(
    LibraryPackInfo pack,
    IOSink sink,
    int expectedBytes,
    ProgressThrottle throttle,
    void Function(int received, int total)? onProgress,
  ) async {
    final urlTemplate = pack.urlTemplate;
    final fileCount = pack.fileCount;
    if (urlTemplate == null || fileCount == null) {
      throw PackFailure('tafsir pack missing urlTemplate/fileCount');
    }
    final perSurahHashes = pack.sha256PerSurah;
    if (perSurahHashes != null && perSurahHashes.length != fileCount) {
      throw PackFailure('tafsir pack "${pack.id}" hash count mismatch');
    }
    final merged = <int, String>{};
    final received = _ByteCounter();
    var separator = '';
    sink.write(_wrapperPrefix(pack.id));
    for (var start = 1; start <= fileCount; start += _tafsirBatchSize) {
      final last = start + _tafsirBatchSize - 1;
      final end = last < fileCount ? last : fileCount;
      final numbers = <int>[for (var n = start; n <= end; n++) n];
      // (a) fetch the window with bounded concurrency.
      final bodies = await Future.wait([
        for (final n in numbers)
          _downloadSurah(
            urlTemplate.replaceFirst('{n}', '$n'),
            pack,
            expectedBytes,
            received,
          ),
      ]);
      // (b) decode the whole window in ONE worker isolate; every body is
      // hash-verified there, before it is decoded.
      final projections = await _decodeSurahs(bodies, numbers, [
        for (final n in numbers)
          perSurahHashes == null ? null : perSurahHashes[n - 1],
      ]);
      // (c) splice the window in surah order.
      for (var i = 0; i < numbers.length; i++) {
        final projection = projections[i];
        final error = projection.error;
        if (error == _shaMismatchError) {
          throw PackFailure(
              'tafsir surah ${numbers[i]} failed sha256 verification');
        }
        if (error != null) {
          throw PackFailure('tafsir surah ${numbers[i]} is $error');
        }
        // Keys are global (`surah * 1000 + ayah`), so merging the per-surah
        // indexes is exact and cannot collide.
        merged.addAll(projection.index);
        // Flatten: splice the per-surah array interior verbatim so the
        // wrapper's tafsirs list stays a flat (surah, ayah, text) list.
        sink.write('$separator${projection.interior}');
        separator = ',';
      }
      if (throttle.shouldReport(received.value, expectedBytes)) {
        onProgress?.call(received.value, expectedBytes);
      }
    }
    sink.write(']}');
    return merged;
  }

  /// Fetches [start] while following at most [kMaxPackRedirectHops] redirects
  /// manually. The seed itself and every redirect target must stay on HTTPS
  /// and [kTrustedPackHosts]; Dio is not allowed to follow a redirect it
  /// cannot re-validate.
  Future<Response<ResponseBody>> _fetchTrustedPack(Uri start) async {
    if (!isTrustedPackUri(start)) {
      throw PackFailure(
        'pack source to untrusted destination '
        '${start.scheme}://${start.host}',
      );
    }
    return followTrustedRedirects(
      dio: _dio,
      start: start,
      maxHops: kMaxPackRedirectHops,
      devLogName: 'quran_yahdi/library',
      resolveNext: (current, location) {
        try {
          return resolveTrustedPackRedirect(current, location);
        } on PackRedirectException catch (error) {
          throw PackFailure(error.message);
        }
      },
      failure: (message) => PackFailure('pack $message'),
    );
  }

  /// Streams one surah body, enforcing the pack-wide size cap.
  ///
  /// The cap counts every byte received for the whole pack, so the received
  /// total is carried across the surahs - and across the concurrent window:
  /// every in-flight stream adds to the same counter.
  ///
  /// The body is accumulated in a [BytesBuilder]: one contiguous buffer
  /// instead of a per-byte [List] (8 bytes per element), and the buffer
  /// crosses the isolate port zero-copy.
  Future<Uint8List> _downloadSurah(
    String url,
    LibraryPackInfo pack,
    int expectedBytes,
    _ByteCounter received,
  ) async {
    // Streamed, not buffered: a compromised/mutable upstream must not be able
    // to force a full multi-MB body into memory before the size guard fires.
    // The cap is checked per chunk.
    final res = await _fetchTrustedPack(Uri.parse(url));
    final body = res.data;
    if (body == null) throw PackFailure('empty response body');
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in body.stream) {
      received.value += chunk.length;
      if (received.value > _sizeCap(expectedBytes)) {
        throw PackFailure('pack "${pack.id}" exceeds its declared size');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  /// The single-file install path (translation/hadith): the body streams into
  /// the dot-part while it is hashed, and the sha256 gate runs before the
  /// file is ever promoted.
  Future<void> _writeSingleFile(
    LibraryPackInfo pack,
    IOSink sink,
    int expectedBytes,
    ProgressThrottle throttle,
    void Function(int received, int total)? onProgress,
  ) async {
    final sourceUrl = pack.sourceUrl;
    if (sourceUrl == null) {
      throw PackFailure('single-file pack missing sourceUrl');
    }
    final res = await _fetchTrustedPack(Uri.parse(sourceUrl));
    final contentLength =
        int.tryParse(res.headers.value(Headers.contentLengthHeader) ?? '') ?? 0;
    final total = contentLength > 0 ? contentLength : expectedBytes;
    final expectedSha = pack.sha256;
    // O(1) hashing: feed every chunk straight into the sha256 sink
    // instead of accumulating the whole body in a second buffer.
    final digestSink = expectedSha == null ? null : _DigestSink();
    final hasher =
        digestSink == null ? null : sha256.startChunkedConversion(digestSink);
    var received = 0;
    final body = res.data;
    if (body == null) throw PackFailure('empty response body');
    await for (final chunk in body.stream) {
      received += chunk.length;
      if (received > _sizeCap(expectedBytes)) {
        throw PackFailure('pack "${pack.id}" exceeds its declared size');
      }
      sink.add(chunk);
      hasher?.add(chunk);
      if (throttle.shouldReport(received, total)) {
        onProgress?.call(received, total);
      }
    }
    _verifyPinnedHash(pack, expectedSha, digestSink, hasher);
  }

  /// Validates the downloaded shape and returns the projection the read path
  /// needs (an ayah index, or the raw hadith list) so the caller can prime
  /// the read cache instead of decoding the file again.
  ///
  /// The decoded tree never crosses an isolate port: the production path
  /// decodes, validates and projects inside ONE worker isolate.
  Future<Object?> _sniffPack(LibraryPackInfo pack, File part) async {
    final decoder = _fileDecoder;
    final _SniffResult result;
    if (decoder == null) {
      result = await _sniffInIsolate(part.path, pack);
    } else {
      dynamic decoded;
      try {
        decoded = await decoder(part.path);
      } on Object {
        throw PackFailure('downloaded pack "${pack.id}" did not parse as JSON');
      }
      result = _sniffTree(decoded, pack);
    }
    final error = result.error;
    if (error != null) {
      throw PackFailure(_sniffFailureMessage(error, pack.id));
    }
    return result.projection;
  }

  /// Primes the read cache from the install-time projections: the merged
  /// per-surah index (tafsir) or the sniffed translation index.
  ///
  /// Hadith packs are deliberately NOT cached here: the DB import owns their
  /// read path, and retaining the full list would defeat the paging win.
  void _primeReadCache(
    LibraryPackInfo pack,
    Map<int, String>? mergedIndex,
    Object? projection,
  ) {
    switch (pack.kind) {
      case LibraryPackKind.tafsir:
        final index =
            mergedIndex ?? (projection is Map<int, String> ? projection : null);
        if (index != null) _reader.primeAyahIndex(pack.id, index);
      case LibraryPackKind.translation:
        final index = projection;
        if (index is Map<int, String>) _reader.primeAyahIndex(pack.id, index);
      case LibraryPackKind.hadith:
        break;
    }
  }

  /// Imports the install-time hadith projection into the DB index.
  ///
  /// Best-effort: a DB failure must not fail an otherwise valid install; the
  /// first browse retries the import lazily from the pack file.
  Future<void> _importHadith(LibraryPackInfo pack, Object? projection) async {
    if (pack.kind != LibraryPackKind.hadith) return;
    try {
      await _hadithStore.importProjection(pack.id, projection);
    } on Object catch (error, stackTrace) {
      appLog('hadith pack import failed',
          name: 'quran_yahdi/library', error: error, stackTrace: stackTrace);
    }
  }

  String _wrapperPrefix(String packId) => '{"pack":"$packId","tafsirs":[';

  /// Writes (or refreshes) the installed-pack row of a promoted pack.
  Future<void> _registerRow(LibraryPackInfo pack, File promoted) async {
    final sizeMb = await promoted.length() / (1024 * 1024);
    final existing = await (_db.select(_db.installedPacks)
          ..where((p) => p.packId.equals(pack.id)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.installedPacks).insert(InstalledPacksCompanion.insert(
            packId: pack.id,
            kind: pack.kind.name,
            language: pack.language,
            title: pack.titleAr,
            sizeMb: sizeMb,
            version: pack.version,
          ));
    } else {
      await (_db.update(_db.installedPacks)
            ..where((p) => p.packId.equals(existing.packId)))
          .write(InstalledPacksCompanion(
        kind: Value(pack.kind.name),
        language: Value(pack.language),
        title: Value(pack.titleAr),
        version: Value(pack.version),
        sizeMb: Value(sizeMb),
      ));
    }
  }
}
