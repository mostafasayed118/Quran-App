import 'dart:convert';
import 'dart:math' as math;

import '../../../core/db/app_database.dart';
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

  Future<List<City>>? _cache;

  Future<List<City>> _all() {
    return _cache ??= _load().catchError((Object error, StackTrace stackTrace) {
      _cache = null;
      throw error;
    });
  }

  Future<List<City>> _load() async {
    final raw = await _loader();
    return [for (final json in raw) City.fromJson(json)];
  }

  Future<List<City>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _all();
    final all = await _all();
    return [
      for (final city in all)
        if (city.nameEn.toLowerCase().contains(q) ||
            city.nameAr.contains(q))
          city,
    ];
  }

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
