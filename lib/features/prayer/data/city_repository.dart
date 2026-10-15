import 'dart:convert';

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

  Future<List<City>> _all() async {
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
