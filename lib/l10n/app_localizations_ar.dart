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

  @override
  String get mushafMode => 'وضع المصحف';

  @override
  String get versesMode => 'وضع الآيات';

  @override
  String get bookmarks => 'العلامات المرجعية';

  @override
  String get bookmarkSave => 'احفظ الآية';

  @override
  String get bookmarkRemove => 'أزل الحفظ';

  @override
  String get noBookmarks => 'لا توجد علامات مرجعية بعد';

  @override
  String pageIndicator(String page) {
    return 'صفحة $page';
  }

  @override
  String get recitationsTitle => 'التلاوات';

  @override
  String get searchReciters => 'ابحث عن قارئ…';

  @override
  String get featured => 'مختارات';

  @override
  String get allReciters => 'كل القرّاء';

  @override
  String get noReciters => 'حمّل فهرس القرّاء من الإنترنت';

  @override
  String get refresh => 'تحديث';

  @override
  String surahCountLabel(String count) {
    return '$count سورة';
  }

  @override
  String nowPlaying(String name) {
    return 'يُشغَّل الآن: $name';
  }

  @override
  String get playTooltip => 'تشغيل';

  @override
  String get pauseTooltip => 'إيقاف مؤقت';

  @override
  String get stopTooltip => 'إيقاف';

  @override
  String get listenTooltip => 'استمع للسورة';

  @override
  String surahBadge(String number) {
    return 'سورة $number';
  }

  @override
  String get playbackFailed => 'تعذّر تشغيل التلاوة';

  @override
  String get fajr => 'فجر';

  @override
  String get sunrise => 'شروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String remaining(String duration) {
    return 'متبقٍ $duration';
  }

  @override
  String get selectCity => 'اختر مدينتك';

  @override
  String get searchCity => 'ابحث عن مدينة…';

  @override
  String get noCity => 'لم تُحدَّد مدينة بعد';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String degreesFromNorth(String degrees) {
    return '$degrees° عن الشمال';
  }

  @override
  String azkarItemsCount(String count) {
    return '$count ذكر';
  }

  @override
  String get azkarDone => 'تم بحمد الله';

  @override
  String get tasbihReset => 'تصفير';

  @override
  String get tasbihTarget => 'الهدف';

  @override
  String get duasTab => 'الأدعية';

  @override
  String get ruqyahTab => 'الرقية';

  @override
  String namePosition(String n) {
    return 'الاسم $n من 99';
  }

  @override
  String streak(String days) {
    return 'سلسلة $days يوم';
  }

  @override
  String get trackerToday => 'صلوات اليوم';

  @override
  String get last7Days => 'آخر ٧ أيام';

  @override
  String get goldGrams => 'ذهب (جرام)';

  @override
  String get silverGrams => 'فضة (جرام)';

  @override
  String get goldPrice => 'سعر جرام الذهب';

  @override
  String get silverPrice => 'سعر جرام الفضة';

  @override
  String get cash => 'النقد المعروض';

  @override
  String get debts => 'الديون';

  @override
  String get nisabByGold => 'العتبة: الذهب';

  @override
  String get nisabBySilver => 'العتبة: الفضة';

  @override
  String get zakatDue => 'الزكاة الواجبة';

  @override
  String get zakatNotDue => 'لا زكاة عليك';

  @override
  String get zakatFootnote =>
      'النسبة ثابتة 2.5% والعتبار على العتبة — راجع أهل العلم في تقديرك.';

  @override
  String get zakatableLabel => 'المال الزكوي';

  @override
  String get nisabLabel => 'العتبة';

  @override
  String hijriDate(String month, String year) {
    return 'الشهر $month سنة $year';
  }

  @override
  String gregorianEquivalent(String date) {
    return 'يوافق $date';
  }

  @override
  String get jumpToToday => 'اليوم';

  @override
  String get tafsirTab => 'التفسير';

  @override
  String get translationsTab => 'الترجمات';

  @override
  String get hadithTab => 'الأحاديث';

  @override
  String get libraryInstall => 'تنزيل';

  @override
  String get libraryDelete => 'حذف';

  @override
  String get libraryInstalled => 'مثبّت';

  @override
  String get libraryFailed => 'تعذّر التنزيل';

  @override
  String get libraryRetry => 'أعِد المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ayahSheetTitle => 'تفسير الآية وترجمتها';

  @override
  String get ayahSheetTafsir => 'تفسير';

  @override
  String get ayahSheetTranslation => 'ترجمة';

  @override
  String get libraryEmptyHint => 'لا يوجد تفسير مثبّت — نزّل من المكتبة';

  @override
  String get hadithNext => 'التالي';

  @override
  String get hadithPrev => 'السابق';
}
