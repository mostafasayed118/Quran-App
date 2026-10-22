// Generates web/public/data/prayer-times from assets/data/cities.json (WW1 C1).
// Run from repo root with TZ=UTC:
//   TZ=UTC dart run tools/export_web_prayer_times.dart
//
// City-local wall-clock MINUTES (0-1439) for fajr..isha + imsak (fajr - 10),
// Egyptian method — mirrors PrayerTimeService (lib/features/prayer/data/).
// Times are computed with PrayerTimes.utcOffset so the wall clock is the
// CITY's (DST-aware via the timezone package). adhan still rounds each time in
// the HOST timezone, so a host whose DST transition overlaps a prayer instant
// can shift that prayer by an hour: the committed data and the CI data-drift
// job both run with TZ=UTC.
import 'dart:convert';
import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const int startYear = 2026;
const int endYear = 2027; // inclusive -> 24 months
const int maxTotalBytes = 12 * 1024 * 1024;

/// Per-prefix IANA default (cities.json id prefix = country code).
const Map<String, String> tzByPrefix = {
  'eg': 'Africa/Cairo',
  'sa': 'Asia/Riyadh',
  'ae': 'Asia/Dubai',
  'qa': 'Asia/Qatar',
  'kw': 'Asia/Kuwait',
  'bh': 'Asia/Bahrain',
  'om': 'Asia/Muscat',
  'ye': 'Asia/Aden',
  'iq': 'Asia/Baghdad',
  'sy': 'Asia/Damascus',
  'lb': 'Asia/Beirut',
  'jo': 'Asia/Amman',
  'ly': 'Africa/Tripoli',
  'tn': 'Africa/Tunis',
  'dz': 'Africa/Algiers',
  'ma': 'Africa/Casablanca',
  'mr': 'Africa/Nouakchott',
  'sd': 'Africa/Khartoum',
  'so': 'Africa/Mogadishu',
  'dj': 'Africa/Djibouti',
  'km': 'Indian/Comoro',
  'gb': 'Europe/London',
  'fr': 'Europe/Paris',
  'de': 'Europe/Berlin',
  'es': 'Europe/Madrid',
  'it': 'Europe/Rome',
  'pt': 'Europe/Lisbon',
  'nl': 'Europe/Amsterdam',
  'be': 'Europe/Brussels',
  'at': 'Europe/Vienna',
  'ch': 'Europe/Zurich',
  'pl': 'Europe/Warsaw',
  'cz': 'Europe/Prague',
  'hu': 'Europe/Budapest',
  'gr': 'Europe/Athens',
  'ru': 'Europe/Moscow',
  'ua': 'Europe/Kyiv',
  'se': 'Europe/Stockholm',
  'dk': 'Europe/Copenhagen',
  'fi': 'Europe/Helsinki',
  'ie': 'Europe/Dublin',
  'ba': 'Europe/Sarajevo',
  'rs': 'Europe/Belgrade',
  'tr': 'Europe/Istanbul',
  'mx': 'America/Mexico_City',
  'cu': 'America/Havana',
  'co': 'America/Bogota',
  've': 'America/Caracas',
  'pe': 'America/Lima',
  'ar': 'America/Argentina/Buenos_Aires',
  'cl': 'America/Santiago',
  'uy': 'America/Montevideo',
  'cn': 'Asia/Shanghai',
  'jp': 'Asia/Tokyo',
  'kr': 'Asia/Seoul',
  'vn': 'Asia/Ho_Chi_Minh',
  'th': 'Asia/Bangkok',
  'my': 'Asia/Kuala_Lumpur',
  'sg': 'Asia/Singapore',
  'id': 'Asia/Jakarta',
  'ph': 'Asia/Manila',
  'bd': 'Asia/Dhaka',
  'np': 'Asia/Kathmandu',
  'in': 'Asia/Kolkata',
  'pk': 'Asia/Karachi',
  'af': 'Asia/Kabul',
  'uz': 'Asia/Tashkent',
  'kz': 'Asia/Almaty',
  'az': 'Asia/Baku',
  'ge': 'Asia/Tbilisi',
  'am': 'Asia/Yerevan',
  'ir': 'Asia/Tehran',
  'et': 'Africa/Addis_Ababa',
  'ke': 'Africa/Nairobi',
  'ng': 'Africa/Lagos',
  'sn': 'Africa/Dakar',
  'za': 'Africa/Johannesburg',
  'rw': 'Africa/Kigali',
  'nz': 'Pacific/Auckland',
};

/// Exact-city overrides (multi-timezone countries).
const Map<String, String> tzByCity = {
  'ps-jerusalem': 'Asia/Jerusalem',
  'ps-gaza': 'Asia/Gaza',
  'ps-ramallah': 'Asia/Hebron',
  'us-washington': 'America/New_York',
  'us-new-york': 'America/New_York',
  'us-chicago': 'America/Chicago',
  'ca-toronto': 'America/Toronto',
  'ca-ottawa': 'America/Toronto',
  'br-brasilia': 'America/Sao_Paulo',
  'br-sao-paulo': 'America/Sao_Paulo',
  'au-canberra': 'Australia/Sydney',
  'au-sydney': 'Australia/Sydney',
};

String? ianaFor(String id) => tzByCity[id] ?? tzByPrefix[id.split('-').first];

Never fail(String message) {
  stderr.writeln('FAIL: $message');
  exit(1);
}

int minutesOfDay(DateTime t) => t.hour * 60 + t.minute;

void main() {
  final citiesJson = File('assets/data/cities.json').readAsStringSync();
  final cities = (jsonDecode(citiesJson) as List).cast<Map<String, dynamic>>();
  if (cities.length != 156) fail('expected 156 cities, got ${cities.length}');

  tzdata.initializeTimeZones();
  final params = CalculationMethod.egyptian.getParameters();

  final outDir = Directory('web/public/data/prayer-times')
    ..createSync(recursive: true);
  final indexRows = <Map<String, Object>>[];
  var totalBytes = 0;
  var totalDays = 0;
  var wrappedIshaDays = 0;

  for (final city in cities) {
    final id = city['id'] as String;
    final lat = (city['lat'] as num).toDouble();
    final lng = (city['lng'] as num).toDouble();
    final iana = ianaFor(id);
    if (iana == null) fail('no timezone mapping for city "$id"');
    final tz.Location loc;
    try {
      loc = tz.getLocation(iana);
    } on Object {
      fail('timezone "$iana" for city "$id" not found in the bundled database');
    }
    final lngImpliedHours = lng / 15.0;
    final januaryOffset =
        tz.TZDateTime(loc, startYear, 1, 1, 12).timeZoneOffset;
    if ((januaryOffset.inMinutes / 60.0 - lngImpliedHours).abs() > 3.5) {
      fail('"$id" -> $iana offset $januaryOffset strays >3.5h from longitude '
          '$lngImpliedHours — mapping likely wrong');
    }

    final months = <Map<String, Object>>[];
    for (var month = 0; month < 24; month++) {
      final y = startYear + month ~/ 12;
      final m = month % 12 + 1;
      final daysInMonth = DateTime(y, m + 1, 0).day;
      final days = <List<int>>[];
      for (var d = 1; d <= daysInMonth; d++) {
        final offset = tz.TZDateTime(loc, y, m, d, 12).timeZoneOffset;
        final t = PrayerTimes.utcOffset(
          Coordinates(lat, lng),
          DateComponents(y, m, d),
          params,
          offset,
        );
        final fajr = minutesOfDay(t.fajr);
        final sunrise = minutesOfDay(t.sunrise);
        final dhuhr = minutesOfDay(t.dhuhr);
        final asr = minutesOfDay(t.asr);
        final maghrib = minutesOfDay(t.maghrib);
        var isha = minutesOfDay(t.isha);
        // High-latitude summer: isha may fall after local midnight. Stored as
        // 1440+minutes so every day row stays strictly ordered
        // (fajr<sunrise<dhuhr<asr<maghrib<isha); renderers use isha % 1440.
        // isha <= maghrib can only mean wrap (isha is always > maghrib by day).
        if (isha <= maghrib) {
          isha += 1440;
          wrappedIshaDays++;
        }
        if (!(fajr < sunrise &&
            sunrise < dhuhr &&
            dhuhr < asr &&
            asr < maghrib &&
            maghrib < isha &&
            fajr - 10 >= 0)) {
          fail('$id $y-$m-$d ordering broken: '
              '[$fajr, $sunrise, $dhuhr, $asr, $maghrib, $isha]');
        }
        days.add([fajr, sunrise, dhuhr, asr, maghrib, isha, fajr - 10]);
      }
      months.add({'y': y, 'm': m, 'days': days});
      totalDays += days.length;
    }

    final payload = jsonEncode({
      'city': {
        'id': id,
        'nameAr': city['nameAr'],
        'nameEn': city['nameEn'],
        'lat': lat,
        'lng': lng,
        'tz': iana,
      },
      'months': months,
    });
    final file = File('${outDir.path}/$id.json');
    file.writeAsStringSync(payload);
    totalBytes += payload.length;
    indexRows.add({
      'id': id,
      'nameAr': city['nameAr'] as String,
      'nameEn': city['nameEn'] as String,
    });
  }

  if (totalDays != cities.length * 730) {
    fail('expected ${cities.length * 730} day rows, got $totalDays');
  }
  final index = jsonEncode({'cities': indexRows});
  File('${outDir.path}/index.json').writeAsStringSync(index);
  totalBytes += index.length;

  final sampleCairo = File('${outDir.path}/eg-cairo.json').readAsStringSync();
  final firstDay = ((((jsonDecode(sampleCairo) as Map)['months'] as List).first
          as Map)['days'] as List)
      .first;
  stdout
      .writeln('OK: ${cities.length} cities x 24 months ($totalDays day rows)');
  stdout.writeln('sample eg-cairo 2026-01-01 '
      '[fajr, sunrise, dhuhr, asr, maghrib, isha, imsak]: $firstDay');
  stdout.writeln('total bytes: $totalBytes '
      '(${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB)');
  stdout.writeln('wrapped-past-midnight isha days: $wrappedIshaDays');
  if (totalBytes > maxTotalBytes) {
    fail('size guard: $totalBytes bytes exceeds '
        '${maxTotalBytes ~/ (1024 * 1024)} MB — STOP and report to PM');
  }
}
