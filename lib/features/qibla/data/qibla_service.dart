import 'package:adhan/adhan.dart';

import '../../prayer/data/prayer_time_service.dart';

class QiblaService {
  const QiblaService();

  double bearingDeg(CityCoordinates c) =>
      Qibla(Coordinates(c.latitude, c.longitude)).direction;
}
