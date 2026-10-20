import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/features/qibla/data/qibla_service.dart';

/// Cairo — the city the qibla tests seed as the selected city.
const cairoCity = City(
  id: 'cairo',
  nameAr: 'القاهرة',
  nameEn: 'Cairo',
  lat: 30.0444,
  lng: 31.2357,
);

/// A qibla service with a fixed bearing (137.2° from north) so every test
/// renders the same arrow and the same label.
class FakeQiblaService implements QiblaService {
  @override
  double bearingDeg(CityCoordinates c) => 137.2;
}
