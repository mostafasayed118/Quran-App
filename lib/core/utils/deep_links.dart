/// P4-app: pure mapping for https://quranyahdi.pages.dev links claimed by the
/// Android manifest intent-filter. No Flutter imports on purpose — every
/// decision is unit-testable (test/deep_link_routing_test.dart pins each row)
/// and the boot wiring in main.dart stays trivial. Lives in core so both
/// `app/` boot code and features can depend on it without inverting layering.
library;

/// Final host (owner decision 2026-10-18), mirrored from web/src/lib/urls.ts.
const String deepLinkHost = 'quranyahdi.pages.dev';

/// Maps an incoming content link to an in-app route; null for anything else
/// (other host, http, unknown path) so the caller can ignore it silently.
String? deepLinkRouteFor(Uri uri) {
  if (uri.scheme != 'https' || uri.host != deepLinkHost) return null;
  var segments = uri.pathSegments;
  // Uri.pathSegments keeps a trailing empty segment for "/x/"; tolerate one.
  if (segments.length > 1 && segments.last.isEmpty) {
    segments = segments.sublist(0, segments.length - 1);
  }
  if (segments.length == 2 && segments.first == 'surah') {
    final surah = int.tryParse(segments[1]);
    if (surah == null || surah < 1 || surah > 114) return null;
    final ayah = _ayahFromFragment(uri.fragment);
    return ayah == null
        ? '/quran/reader?surah=$surah'
        : '/quran/reader?surah=$surah&ayah=$ayah';
  }
  if (segments.length == 1) {
    if (segments.first == 'quran') return '/quran';
    if (segments.first == 'reciters') return '/recitation';
  }
  return null;
}

/// `#ayah-{m}` with m >= 1; any other fragment (absent, `#ayah-0`, `#x`)
/// yields a surah-only route. Ayah range is the reader route's contract.
int? _ayahFromFragment(String fragment) {
  if (!fragment.startsWith('ayah-')) return null;
  final m = int.tryParse(fragment.substring(5));
  return (m != null && m >= 1) ? m : null;
}

/// Shared-link builder — byte-format mirror of web/src/lib/urls.ts so that a
/// shared verse deep-links back into the app on another device.
String webSurahUrl(int surah, [int? ayah]) {
  final base = 'https://$deepLinkHost/surah/$surah';
  return ayah == null ? base : '$base#ayah-$ayah';
}
