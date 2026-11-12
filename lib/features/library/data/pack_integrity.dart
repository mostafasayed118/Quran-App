part of 'pack_downloader.dart';

/// Guard against a lying/compromised host streaming unbounded bytes: allow up
/// to 2x the declared size plus 64 KiB slack.
int _sizeCap(int expectedBytes) => guardedByteCap(expectedBytes);

/// Verifies the streamed body against the pinned sha256.
///
/// The digest is closed here — after the whole body was hashed and before the
/// file can ever be promoted.
void _verifyPinnedHash(
  LibraryPackInfo pack,
  String? expectedSha,
  _DigestSink? digestSink,
  ByteConversionSink? hasher,
) {
  if (expectedSha == null) return;
  if (hasher == null || digestSink == null) {
    throw PackFailure('pack "${pack.id}" hash sink missing');
  }
  hasher.close();
  if (digestSink.value.toString() != expectedSha) {
    throw PackFailure('pack "${pack.id}" failed sha256 verification');
  }
}
