import 'dart:convert';
import 'package:quran_yahdi/core/utils/app_log.dart';

import 'package:flutter/services.dart';

/// The Unicode Uthmani reading of the Quran, one asset file per surah.
///
/// The database keeps `text_uthmani` as a private-use glyph encoding that only
/// the bundled Hafs face can draw; copying or selecting it produces garbage in
/// any other app. The real text ships separately (`assets/quran/uthmani/<id>.json`,
/// UTF-8, `{"<ayah>":"<text>"}`) so no database migration and no user-data risk
/// is involved: the column and every existing bookmark keep working untouched.
abstract interface class UthmaniTextSource {
  /// Ayah number → Unicode Uthmani text for [surahId]. Empty when unavailable.
  Future<Map<int, String>> forSurah(int surahId);
}

/// Loads the per-surah JSON assets, caching each surah after the first read.
class AssetUthmaniTextSource implements UthmaniTextSource {
  AssetUthmaniTextSource(this._bundle);

  final AssetBundle _bundle;
  final Map<int, Map<int, String>> _cache = <int, Map<int, String>>{};

  @override
  Future<Map<int, String>> forSurah(int surahId) async {
    final cached = _cache[surahId];
    if (cached != null) return cached;
    try {
      final raw = await _bundle.loadString(
        'assets/quran/uthmani/$surahId.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = <int, String>{
        for (final entry in decoded.entries)
          int.parse(entry.key): entry.value as String,
      };
      _cache[surahId] = map;
      return map;
    } on Object catch (error, stackTrace) {
      // A missing/corrupt asset must not break the reader: it falls back to
      // the glyph column and simply loses selection for that surah.
      appLog(
        'uthmani asset unavailable for surah $surahId',
        name: 'quran_yahdi/uthmani',
        error: error,
        stackTrace: stackTrace,
      );
      return const <int, String>{};
    }
  }
}
