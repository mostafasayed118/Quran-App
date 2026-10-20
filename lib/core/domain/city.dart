/// A city the user can pick for prayer times and qibla.
///
/// Lives in core/domain so the prayer, home, qibla and settings surfaces can
/// share it without importing the prayer feature's data layer.
class City {
  /// Creates a city entry. [lat] and [lng] are decimal degrees (WGS84).
  const City({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.lat,
    required this.lng,
  });

  /// The stable city id; the persisted selection refers to it.
  final String id;

  /// The Arabic display name.
  final String nameAr;

  /// The English display name.
  final String nameEn;

  /// The latitude in decimal degrees (WGS84), -90..90.
  final double lat;

  /// The longitude in decimal degrees (WGS84), -180..180.
  final double lng;

  /// The city as a bare [CityCoordinates] point.
  CityCoordinates get coordinates => CityCoordinates(lat, lng);

  /// Builds a city from its persisted JSON map.
  ///
  /// Throws when a field is missing or has the wrong type: the map comes
  /// from the bundled city list, so a malformed entry is a data bug, not a
  /// user error.
  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        nameAr: json['nameAr'] as String,
        nameEn: json['nameEn'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );

  /// The persisted JSON representation of this city (the inverse of
  /// [City.fromJson]).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'lat': lat,
        'lng': lng,
      };
}

/// A point on earth, decoupled from the city it came from.
class CityCoordinates {
  /// Creates a point from decimal degrees (WGS84).
  const CityCoordinates(this.latitude, this.longitude);

  /// The latitude in decimal degrees (WGS84), -90..90.
  final double latitude;

  /// The longitude in decimal degrees (WGS84), -180..180.
  final double longitude;
}

/// Cross-feature seam: the prayer feature owns the city storage, every other
/// consumer reaches it through this port.
abstract interface class CitySource {
  /// The persisted selection; null while no city is picked.
  Future<City?> selectedCity();

  /// Persists [city] as the selection.
  Future<void> select(City city);
}
