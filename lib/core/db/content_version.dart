/// Single source of truth for the bundled content version of
/// `assets/db/quran.sqlite`.
///
/// BUMP THIS whenever the asset DB's *content* changes (surah metadata, ayah
/// text/layout fields — i.e. a regenerated quran.sqlite differs). The build
/// tool stamps the value into the asset's settings table; on every open the
/// app compares the installed DB's stamp and re-seeds `surahs`/`ayahs` from
/// the bundled asset when the installed stamp is older. User-owned tables
/// (bookmarks, khatma, prayer log, downloads, installed packs, other
/// settings) are never touched by a refresh.
const int kContentVersion = 1;

/// Row key in the settings table holding the stamped content version.
const String kContentVersionKey = 'content_version';
