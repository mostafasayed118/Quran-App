part of 'pack_downloader.dart';

class PackFailure implements Exception {
  PackFailure(this.message);

  final String message;
  @override
  String toString() => 'PackFailure: $message';
}

/// The projection of one tafsir surah body: the ayah index and the array
/// interior the wrapper splices verbatim. [error] is the shape failure
/// (null when the body is valid).
typedef _SurahProjection = ({
  String? error,
  Map<int, String> index,
  String interior
});

/// Why the install sniff rejected a downloaded pack.
enum _SniffError { parse, notObject, quran, hadiths, packMismatch, noTafsirs }

/// The sniff verdict: the shape failure (null when the pack is valid) and the
/// projection the read path needs — the decoded tree itself never crosses an
/// isolate port.
typedef _SniffResult = ({_SniffError? error, Object? projection});

/// The shared byte counter of one pack download.
///
/// The size cap covers the WHOLE pack, so every in-flight stream of the
/// tafsir fetch window adds to this one counter.
class _ByteCounter {
  int value = 0;
}

/// How many tafsir surahs are fetched in parallel and decoded per worker
/// isolate. A small window: enough to hide the per-request latency, small
/// enough to bound the memory and the load on the origin.
const int _tafsirBatchSize = 4;

/// Collects the single digest produced by [sha256.startChunkedConversion].
///
/// The streaming install path feeds the digest sink chunk by chunk, so the
/// whole body is never retained a second time just to hash it.
class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
