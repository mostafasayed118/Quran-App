import 'package:quran_yahdi/core/domain/prayer_name.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

extension PrayerNameLabel on PrayerName {
  String label(AppLocalizations loc) => switch (this) {
        PrayerName.fajr => loc.fajr,
        PrayerName.sunrise => loc.sunrise,
        PrayerName.dhuhr => loc.dhuhr,
        PrayerName.asr => loc.asr,
        PrayerName.maghrib => loc.maghrib,
        PrayerName.isha => loc.isha,
      };
}
