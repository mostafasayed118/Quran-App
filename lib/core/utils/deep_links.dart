/// P4-app: pure mapping for https://quranyahdi.pages.dev links claimed by the
/// Android manifest intent-filter. No Flutter imports on purpose — every
/// decision is unit-testable (test/deep_link_routing_test.dart pins each row)
/// and the boot wiring in main.dart stays trivial. Lives in core so both
/// `app/` boot code and features can depend on it without inverting layering.
library;

import '../domain/quran_limits.dart';
import 'app_routes.dart';

/// Final host (owner decision 2026-10-18), mirrored from web/src/lib/urls.ts.
const String deepLinkHost = 'quranyahdi.pages.dev';

/// The highest ayah number in the Quran (Al-Baqarah has 286).
///
/// The surah's own ayah count is not known at parse time, so this hard
/// maximum is the clamp an incoming link is held to: a link can never
/// point past the last ayah of the longest surah.
const int maxDeepLinkAyah = 286;

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
    if (surah == null || surah < kFirstSurahId || surah > kSurahCount) {
      return null;
    }
    final ayah = _ayahFromFragment(uri.fragment);
    return quranReaderPath(surah: surah, ayah: ayah);
  }
  if (segments.length == 1) {
    if (segments.first == 'quran') return AppRoutes.quran;
    if (segments.first == 'reciters') return AppRoutes.recitation;
  }
  return null;
}

/// `#ayah-{m}` with 1 <= m <= [maxDeepLinkAyah]; any other fragment (absent,
/// `#ayah-0`, `#x`, an out-of-range ayah) yields a surah-only route. Ayah
/// range is the reader route's contract.
int? _ayahFromFragment(String fragment) {
  if (!fragment.startsWith('ayah-')) return null;
  final m = int.tryParse(fragment.substring(5));
  return (m != null && m >= 1 && m <= maxDeepLinkAyah) ? m : null;
}

/// Shared-link builder — byte-format mirror of web/src/lib/urls.ts so that a
/// shared verse deep-links back into the app on another device.
String webSurahUrl(int surah, [int? ayah]) {
  final base = 'https://$deepLinkHost/surah/$surah';
  return ayah == null ? base : '$base#ayah-$ayah';
}
