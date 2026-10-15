// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'قرآن يَهدي';

  @override
  String get home => 'الرئيسية';

  @override
  String get quran => 'القرآن الكريم';

  @override
  String get azkar => 'الأذكار';

  @override
  String get tasbih => 'السبحة';

  @override
  String get prayerTimes => 'مواقيت الصلاة';

  @override
  String get qibla => 'القبلة';

  @override
  String get duasAndRuqyah => 'الأدعية والرقية';

  @override
  String get worshipTracker => 'تتبع العبادات';

  @override
  String get zakat => 'الزكاة';

  @override
  String get hijriCalendar => 'التقويم الهجري';

  @override
  String get asmaUlHusna => 'أسماء الله الحسنى';

  @override
  String get settings => 'الإعدادات';

  @override
  String get recitations => 'التلاوات';

  @override
  String get library => 'المكتبة';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String get surahIndexTitle => 'القرآن الكريم';

  @override
  String get searchSurahHint => 'ابحث بسورة…';

  @override
  String get revelationMakkah => 'مكية';

  @override
  String get revelationMadinah => 'مدنية';

  @override
  String ayatCount(int count) {
    return '$count آيات';
  }
}
