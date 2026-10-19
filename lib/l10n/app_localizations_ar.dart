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
  String continueReadingAyah(String ayah) {
    return '﴿$ayah﴾ متابعة القراءة';
  }

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
  String get shareAyah => 'مشاركة الآية';

  @override
  String get noBookmarks => 'لا توجد علامات مرجعية بعد';

  @override
  String pageIndicator(String page) {
    return 'صفحة $page';
  }

  @override
  String ornateBrackets(String text) {
    return '﴿$text﴾';
  }

  @override
  String ayahNumberLabel(String number) {
    return 'الآية $number';
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
  String get tasbihTargetSet => 'تم ضبط الهدف — بدأ العد من جديد';

  @override
  String get duasTab => 'الأدعية';

  @override
  String get ruqyahTab => 'الرقية';

  @override
  String duaRepeat(String count) {
    return '×$count';
  }

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
  String get trackerDotToday => 'اليوم';

  @override
  String get trackerDotYesterday => 'أمس';

  @override
  String get trackerDotTwoDaysAgo => 'قبل يومين';

  @override
  String trackerDotDaysAgo(String days) {
    return 'قبل $days أيام';
  }

  @override
  String get trackerDotMarked => 'مُسجَّل';

  @override
  String get trackerDotUnmarked => 'غير مُسجَّل';

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
  String get zakatEnterPrice => 'أدخل سعر الذهب/الفضة لحساب النصاب';

  @override
  String hijriDate(String month, String year) {
    return 'الشهر $month سنة $year';
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
  String get retry => 'أعِد المحاولة';

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

  @override
  String surahFallbackName(String n) {
    return 'سورة $n';
  }

  @override
  String get defaultReciterSet => 'تم تعيينه قارئك الافتراضي';

  @override
  String get unknownInitial => '؟';

  @override
  String get hadithRead => 'اقرأ';

  @override
  String get useMyLocation => 'استخدم موقعي';

  @override
  String get locating => 'جارٍ تحديد الموقع…';

  @override
  String get locationUnavailable => 'تعذّر تحديد الموقع — اختر يدويًا';

  @override
  String get compassLive => 'المقياس حي';

  @override
  String get compassStatic =>
      'المقياس ثابت — لا يتوفر اتجاه مباشر على هذا الجهاز';

  @override
  String reminderNextPrayer(String prayer) {
    return 'حان موعد صلاة $prayer';
  }

  @override
  String get reminderAzkar => 'أذكار الصباح';

  @override
  String get notificationsEnabledHint =>
      'إن لم تصلك التذكيرات، فعِّل إذن الإشعارات من إعدادات جهازك';

  @override
  String get azkarReminder => 'تذكير الأذكار';

  @override
  String get reminderTime => 'وقت التذكير';

  @override
  String get settingsMinimalNote => 'الوضع الليلي من إعدادات جهازك';

  @override
  String get stopAction => 'وقف';

  @override
  String get previousMonth => 'الشهر السابق';

  @override
  String get nextMonth => 'الشهر التالي';

  @override
  String get clearSelection => 'مسح الاختيار';

  @override
  String get backTooltip => 'رجوع';

  @override
  String get downloadSurah => 'تنزيل السورة';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get pageNotFoundHint => 'الرابط الذي فتحت غير موجود هنا';

  @override
  String get genericError => 'عذرًا، حدث خطأ — حاول مرة أخرى';

  @override
  String get noResults => 'لا نتائج مطابقة';

  @override
  String get recitersRefreshFailed => 'تعذّر تحديث قائمة القرّاء';

  @override
  String downloadProgressReceived(String received) {
    return '$received م.ب';
  }

  @override
  String downloadProgressOfTotal(String received, String total) {
    return '$received من $total م.ب';
  }

  @override
  String get playbackNoReciters =>
      'تعذّر التشغيل — حمّل فهرس القرّاء من الإنترنت';

  @override
  String get playbackBackgroundFailed =>
      'تعذّر تشغيل التلاوة — الصوت في الخلفية غير متاح';

  @override
  String get currentCity => 'المدينة الحالية';

  @override
  String get locationSettings => 'إعدادات الموقع';

  @override
  String get reminderChannelDescription => 'تذكيرات الصلاة والأذكار';

  @override
  String get wirdTitle => 'ورد الختمة';

  @override
  String get wirdSetupHint => 'اختر وتيرة الختمة وابدأ وردك اليومي';

  @override
  String get wirdStart => 'ابدأ ختمة';

  @override
  String get wirdPaceSheetTitle => 'وتيرة الختمة';

  @override
  String get wirdPaceMonthly => 'ختمة كل شهر';

  @override
  String get wirdPaceTwoMonths => 'ختمة كل شهرين';

  @override
  String get wirdPaceThreeMonths => 'ختمة كل ٣ شهور';

  @override
  String get wirdPaceFourMonths => 'ختمة كل ٤ شهور';

  @override
  String wirdDailyPages(String pages) {
    return '$pages صفحة يوميًا تقريبًا';
  }

  @override
  String wirdProgress(String done, String total) {
    return '$done من $total صفحة';
  }

  @override
  String wirdTodayRange(String from, String to) {
    return 'اليوم: من صفحة $from إلى $to';
  }

  @override
  String wirdRemainingDays(String days) {
    return 'باقي نحو $days يوم';
  }

  @override
  String get wirdOpenToday => 'افتح الورد';

  @override
  String get wirdFinishToday => 'أنهيت ورد اليوم';

  @override
  String get wirdCompleted => 'أتممت الختمة';

  @override
  String get wirdNewPlan => 'ختمة جديدة';
}
