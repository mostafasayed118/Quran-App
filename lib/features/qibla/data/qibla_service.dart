import 'package:adhan/adhan.dart';

import '../../../core/domain/city.dart';

/// Computes the qibla bearing for a position.
class QiblaService {
  const QiblaService();

  /// Qibla bearing in degrees for [c].
  double bearingDeg(CityCoordinates c) =>
      Qibla(Coordinates(c.latitude, c.longitude)).direction;
}
