/// Canonical in-app routes shared by the router, boot wiring, deep links, and
/// feature navigation.
///
/// These are the exact strings the router already serves; centralising them
/// makes a rename one edit instead of a tree-wide search, and keeps a feature
/// push from silently drifting away from the declared route.
library;

abstract final class AppRoutes {
  static const home = '/home';
  static const quran = '/quran';
  static const reader = '/quran/reader';
  static const quranSearch = '/quran/search';
  static const recitation = '/recitation';
  static const reciter = '/recitation/reciter';
  static const library = '/library';
  static const hadith = '/library/hadith';
  static const prayerTimes = '/prayer-times';
  static const cityPicker = '/prayer-times/city';
  static const qibla = '/qibla';
  static const azkar = '/azkar';
  static const tasbih = '/tasbih';
  static const duas = '/duas';
  static const worship = '/worship';
  static const zakat = '/zakat';
  static const hijri = '/hijri';
  static const asma = '/asma';
  static const settings = '/settings';
  static const bookmarks = '/bookmarks';
}

abstract final class AppRouteQuery {
  static const surah = 'surah';
  static const ayah = 'ayah';
  static const pack = 'pack';
  static const row = 'row';
}

/// `/quran/reader?surah={surah}[&ayah={ayah}]`
///
/// Omitting [ayah] keeps the surah-only form used by shared links.
String quranReaderPath({required int surah, int? ayah}) {
  final base = '${AppRoutes.reader}?${AppRouteQuery.surah}=$surah';
  return ayah == null ? base : '$base&${AppRouteQuery.ayah}=$ayah';
}

String hadithBrowsePath(String packId) =>
    '${AppRoutes.hadith}?${AppRouteQuery.pack}=$packId';

String reciterSurahsPath(String rowId) =>
    '${AppRoutes.reciter}?${AppRouteQuery.row}=${Uri.encodeComponent(rowId)}';
