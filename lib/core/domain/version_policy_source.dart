import 'version_policy.dart';

/// The network side of the update gate.
///
/// Implementations MUST fail open: any failure (offline, timeout, HTTP error,
/// malformed payload) yields null — "no valid policy" — and the app starts
/// normally. A remotely-published policy can only *restrict* an installation
/// through a valid, parseable document; it can never lock one out by example
/// of a 404.
abstract interface class VersionPolicySource {
  /// Fetches and validates the remote policy; null when unavailable.
  Future<VersionPolicy?> fetch();
}

/// The last-known-good policy store, kept so a transient failure during a
/// launch does not weaken (or wrongly strengthen) enforcement.
abstract interface class VersionPolicyCache {
  /// Returns the raw cached JSON document, or null when nothing was cached.
  Future<String?> read();

  /// Persists the raw document for the next cold start.
  Future<void> write(String rawJson);
}
