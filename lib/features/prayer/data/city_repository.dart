import 'dart:convert';
import 'dart:math' as math;

import '../../../core/db/app_database.dart';
import '../../../core/utils/cached_loader.dart';
import 'prayer_time_service.dart';

const selectedCityKey = 'selected_city';

class City {
  const City({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;

  CityCoordinates get coordinates => CityCoordinates(lat, lng);

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        nameAr: json['nameAr'] as String,
        nameEn: json['nameEn'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'lat': lat,
        'lng': lng,
      };
}

class CityRepository {
  CityRepository({
    required AppDatabase db,
    required Future<List<Map<String, dynamic>>> Function() loader,
  })  : _db = db,
        _loader = loader;

  final AppDatabase _db;
  final Future<List<Map<String, dynamic>>> Function() _loader;

  late final CachedLoader<List<City>> _cities = CachedLoader(_load);

  Future<List<City>> _all() {
    return _cities.load();
  }

  Future<List<City>> _load() async {
    final raw = await _loader();
    return [for (final json in raw) City.fromJson(json)];
  }

  Future<List<City>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _all();
    final all = await _all();
    final normalizedQuery = _normalizeArabic(q);
    return [
      for (final city in all)
        if (city.nameEn.toLowerCase().contains(q) ||
            _normalizeArabic(city.nameAr).contains(normalizedQuery))
          city,
    ];
  }

  /// Folds Arabic letter variants (hamza forms, alef maqsura, ta marbuta)
  /// and strips diacritics/tatweel so plain-keyboard queries match curated
  /// names (e.g. «الاسكندرية» finds «الإسكندرية»).
  static String _normalizeArabic(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (_isArabicDiacritic(rune)) continue;
      buffer.writeCharCode(_foldArabicLetter(rune));
    }
    return buffer.toString();
  }

  static bool _isArabicDiacritic(int rune) =>
      (rune >= 0x064B && rune <= 0x065F) || rune == 0x0670 || rune == 0x0640;

  static int _foldArabicLetter(int rune) => switch (rune) {
        0x0622 || 0x0623 || 0x0625 || 0x0671 => 0x0627, // آ أ إ ٱ -> ا
        0x0624 => 0x0648, // ؤ -> و
        0x0626 || 0x0649 => 0x064A, // ئ ى -> ي
        0x0629 => 0x0647, // ة -> ه
        _ => rune,
      };

  Future<City> nearestTo(double lat, double lng) async {
    final all = await _all();
    if (all.isEmpty) {
      throw StateError('No cities available to match against');
    }
    var best = all.first;
    var bestDistance = _haversineKm(lat, lng, best.lat, best.lng);
    for (final city in all.skip(1)) {
      final distance = _haversineKm(lat, lng, city.lat, city.lng);
      if (distance < bestDistance) {
        best = city;
        bestDistance = distance;
      }
    }
    return best;
  }

  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0088;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  Future<String?> selectedCityJson() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(selectedCityKey)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<City?> selectedCity() async {
    final json = await selectedCityJson();
    if (json == null || json.isEmpty) return null;
    try {
      return City.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> select(City city) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: selectedCityKey,
            value: jsonEncode(city.toJson()),
          ),
        );
  }
}
