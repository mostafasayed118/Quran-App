/// Redirect guard for library-pack downloads.
///
/// The catalog pins every pack to an `https` URL, but HTTP redirects are
/// followed by Dio unless the caller opts out. A compromised or misconfigured
/// CDN could therefore steer a pack request to `http://` or a foreign host.
/// This guard re-validates every hop on the same trust boundary as the
/// catalog: HTTPS, the jsDelivr host, and the default port.
library;

/// The only host the bundled catalog serves packs from.
///
/// A future remote catalog that uses another host must update this set
/// deliberately — the redirect guard is a security boundary, not a
/// convenience allowlist.
const Set<String> kTrustedPackHosts = {'cdn.jsdelivr.net'};

/// Maximum number of redirect hops a pack download may follow.
const int kMaxPackRedirectHops = 3;

/// A redirect that left the trusted pack boundary.
class PackRedirectException implements Exception {
  /// Creates a redirect failure with a human-readable [message].
  PackRedirectException(this.message);

  /// Why the redirect was rejected.
  final String message;

  @override
  String toString() => 'PackRedirectException: $message';
}

/// True when [uri] is an HTTPS URI on a trusted pack host and the default
/// port. An explicit non-443 port is rejected even on a trusted host.
bool isTrustedPackUri(
  Uri uri, {
  Set<String> trustedHosts = kTrustedPackHosts,
}) {
  if (uri.scheme != 'https') return false;
  if (!trustedHosts.contains(uri.host)) return false;
  if (uri.hasPort && uri.port != 443) return false;
  return true;
}

/// Resolves [location] against [current] and enforces [isTrustedPackUri].
///
/// Relative locations are allowed because a CDN may redirect within its own
/// origin. Absolute locations must stay on a trusted host and use HTTPS.
Uri resolveTrustedPackRedirect(
  Uri current,
  String location, {
  Set<String> trustedHosts = kTrustedPackHosts,
}) {
  final next = current.resolve(location.trim());
  if (!isTrustedPackUri(next, trustedHosts: trustedHosts)) {
    throw PackRedirectException(
      'pack redirect to untrusted destination ${next.scheme}://${next.host}',
    );
  }
  return next;
}
