import 'dart:convert';
import 'dart:math' as math;

import '../../../core/db/app_database.dart';
import '../../../core/domain/city.dart';
import '../../../core/utils/arabic_search.dart';
import '../../../core/utils/cached_loader.dart';

// Compat: existing importers of this file keep resolving [City].
export '../../../core/domain/city.dart' show City;

const selectedCityKey = 'selected_city';

/// Offline city catalog: search, nearest-city lookup and the selected city.
class CityRepository implements CitySource {
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

  /// Cities matching [query]; Arabic is matched diacritics-insensitively. An empty query returns every city.
  Future<List<City>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _all();
    final all = await _all();
    final normalizedQuery = normalizeArabicLetters(q);
    return [
      for (final city in all)
        if (city.nameEn.toLowerCase().contains(q) ||
            normalizeArabicLetters(city.nameAr).contains(normalizedQuery))
          city,
    ];
  }

  /// Closest catalog city to the given coordinates; throws when the catalog is empty.
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

  /// Raw JSON of the stored selected city, or null when none is stored.
  Future<String?> selectedCityJson() async {
    final row = await (_db.select(_db.settingsTable)
          ..where((s) => s.key.equals(selectedCityKey)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<City?> selectedCity() async {
    final json = await selectedCityJson();
    if (json == null || json.isEmpty) return null;
    Map<String, dynamic> city;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) return null;
      city = decoded;
    } on Object {
      return null;
    }
    try {
      return City.fromJson(city);
    } on Object {
      // A backup import restores the city by id only - the coordinates are
      // never exported (they are a location, and a backup file is a file the
      // user shares). Resolve the id against the offline city catalog.
      final id = city['id'];
      if (id is! String || id.isEmpty) return null;
      for (final catalogCity in await _all()) {
        if (catalogCity.id == id) return catalogCity;
      }
      return null;
    }
  }

  @override
  Future<void> select(City city) async {
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            key: selectedCityKey,
            value: jsonEncode(city.toJson()),
          ),
        );
  }
}
