import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/ramadan/domain/ramadan_times.dart';

void main() {
  final fajr = DateTime(2027, 2, 20, 5, 0);
  final maghrib = DateTime(2027, 2, 20, 18, 0);

  test('imsak is the Fajr lead and iftar is Maghrib', () {
    final times = ramadanTimesFor(fajr: fajr, maghrib: maghrib);

    expect(times.imsak, fajr.subtract(const Duration(minutes: 10)));
    expect(times.iftar, maghrib);
  });

  test('the lead is configurable and clamped to 0..30', () {
    expect(
      ramadanTimesFor(fajr: fajr, maghrib: maghrib, imsakLeadMinutes: 0).imsak,
      fajr,
    );
    expect(
      ramadanTimesFor(fajr: fajr, maghrib: maghrib, imsakLeadMinutes: 999)
          .imsak,
      fajr.subtract(const Duration(minutes: 30)),
    );
    expect(
      ramadanTimesFor(fajr: fajr, maghrib: maghrib, imsakLeadMinutes: -5).imsak,
      fajr,
    );
  });
}
