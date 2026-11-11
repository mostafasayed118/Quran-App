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
  String get splashTagline => 'القرآن الكريم بين يديك';

  @override
  String get home => 'الرئيسية';

  @override
  String get quran => 'القرآن الكريم';

  @override
  String get quranTabSurahs => 'سور';

  @override
  String get quranTabJuz => 'أجزاء';

  @override
  String get quranTabBookmarks => 'علامات';

  @override
  String get quranWorkspacePrompt => 'اختر سورة أو جزءًا أو علامة للقراءة';

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
  String get hijriOffsetTitle => 'ضبط التاريخ الهجري';

  @override
  String hijriOffsetValue(String days) {
    return 'الإزاحة: $days';
  }

  @override
  String get hijriOffsetMinus => 'يوم أقل';

  @override
  String get hijriOffsetPlus => 'يوم أكثر';

  @override
  String get ramadanTitle => 'رمضان';

  @override
  String ramadanToday(String day) {
    return 'اليوم $day رمضان';
  }

  @override
  String ramadanStartsOn(String date) {
    return 'يبدأ رمضان في $date';
  }

  @override
  String get ramadanImsak => 'الإمساك';

  @override
  String get ramadanIftar => 'الإفطار';

  @override
  String get ramadanDayColumn => 'اليوم';

  @override
  String get ramadanImsakNote => 'الإمساك قبل الفجر بعشر دقائق.';

  @override
  String get qadaTitle => 'قضاء الصيام';

  @override
  String get qadaAdd => 'إضافة يوم';

  @override
  String get qadaPickDate => 'اختر اليوم الفائت';

  @override
  String qadaCount(String count) {
    return '$count يوم مسجّل';
  }

  @override
  String get qadaEmpty => 'لا توجد أيام مسجلة';

  @override
  String get qadaDeleteTitle => 'حذف اليوم؟';

  @override
  String qadaDeleteBody(String date) {
    return 'سيُحذف $date من القضاء.';
  }

  @override
  String get asmaUlHusna => 'أسماء الله الحسنى';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'غامق';

  @override
  String get recitations => 'التلاوات';

  @override
  String get library => 'المكتبة';

  @override
  String get translationSearchTitle => 'بحث في الترجمات';

  @override
  String get translationSearchHint => 'ابحث في الترجمات المثبتة';

  @override
  String get translationSearchEmpty => 'اكتب كلمة للبحث في الترجمة.';

  @override
  String get translationSearchNoResults => 'لا توجد نتائج';

  @override
  String get translationSearchNoPacks =>
      'لا توجد ترجمة مثبتة. ثبّت ترجمة من المكتبة أولًا.';

  @override
  String translationSearchResults(String count) {
    return '$count نتيجة';
  }

  @override
  String translationSearchTruncated(Object shown, Object total) {
    return 'عرض أول $shown من $total نتيجة';
  }

  @override
  String get translationSearchAction => 'بحث في الترجمات';

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
  String get searchQuranTitle => 'البحث في القرآن';

  @override
  String get searchQuranHint => 'ابحث في آيات القرآن…';

  @override
  String get searchQuranPrompt => 'اكتب حرفين على الأقل للبحث في الآيات';

  @override
  String searchQuranResultsCount(String count) {
    return 'عدد النتائج: $count';
  }

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
  String get basmala => 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  String get bookmarks => 'العلامات المرجعية';

  @override
  String get bookmarkSave => 'احفظ الآية';

  @override
  String get bookmarkRemove => 'أزل الحفظ';

  @override
  String get bookmarkSaved => 'تم حفظ الآية';

  @override
  String get bookmarkRemoved => 'تم إزالة الحفظ';

  @override
  String get bookmarkEdit => 'تعديل الملاحظة والمجلد';

  @override
  String get bookmarkMetaSave => 'حفظ';

  @override
  String get bookmarkFolder => 'المجلد';

  @override
  String get bookmarkNote => 'ملاحظة';

  @override
  String get bookmarkFolderHint => 'اسم المجلد (اختياري)';

  @override
  String get bookmarkNoteHint => 'ملاحظة (اختياري)';

  @override
  String get bookmarkFolderEmpty => 'لا توجد علامات في هذا المجلد';

  @override
  String get shareAyah => 'مشاركة الآية';

  @override
  String get shareAsImage => 'مشاركة كصورة';

  @override
  String get shareAsText => 'مشاركة كنص';

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
  String get repeatSurah => 'تكرار السورة';

  @override
  String get playbackSpeed => 'سرعة التشغيل';

  @override
  String get sleepTimer => 'مؤقت النوم';

  @override
  String get sleepTimerOff => 'بدون مؤقت';

  @override
  String sleepTimerMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get previousSurah => 'السورة السابقة';

  @override
  String get nextSurah => 'السورة التالية';

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
  String get onboardingTitle => 'البداية';

  @override
  String get onboardingIntro => 'خطوتان سريعتان ويصبح التطبيق جاهزًا لك.';

  @override
  String onboardingCityDone(String city) {
    return 'المدينة: $city';
  }

  @override
  String get onboardingChangeCity => 'تغيير المدينة';

  @override
  String get onboardingRemindersTitle => 'تفعيل تذكير الصلوات';

  @override
  String get onboardingRemindersBody =>
      'يصلك تنبيه عند دخول وقت الصلاة، ويمكنك إيقافه في أي وقت.';

  @override
  String get onboardingAllow => 'تفعيل';

  @override
  String get onboardingEnabled => 'التنبيهات مفعّلة';

  @override
  String get onboardingStart => 'ابدأ الاستخدام';

  @override
  String get onboardingSkip => 'تخطّي';

  @override
  String get searchCity => 'ابحث عن مدينة…';

  @override
  String get noCity => 'لم تُحدَّد مدينة بعد';

  @override
  String degreesFromNorth(String degrees) {
    return '$degrees درجة عن الشمال';
  }

  @override
  String azkarItemsCount(String count) {
    return '$count ذكر';
  }

  @override
  String get azkarDone => 'تم بحمد الله';

  @override
  String get azkarRestart => 'إعادة العد';

  @override
  String get azkarFavoriteAdd => 'إضافة إلى المفضلة';

  @override
  String get azkarFavoriteRemove => 'إزالة من المفضلة';

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
  String get zakatRateNote =>
      'النسبة ثابتة ٢٫٥٪ والعتبار على العتبة — راجع أهل العلم في تقديرك.';

  @override
  String get zakatableLabel => 'المال الزكوي';

  @override
  String get nisabLabel => 'العتبة';

  @override
  String get zakatEnterPrice => 'أدخل سعر الذهب/الفضة لحساب النصاب';

  @override
  String get zakatInvalidNumber => 'أدخل رقمًا صحيحًا';

  @override
  String get zakatFixInputs => 'صحّح الحقول غير الصحيحة أولًا';

  @override
  String hijriDate(String month, String year) {
    return 'الشهر $month سنة $year';
  }

  @override
  String hijriCellSemantics(String hijri, String gregorian) {
    return 'هجري $hijri، ميلادي $gregorian';
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
  String get setAsDefaultReciter => 'تعيين كقارئ افتراضي';

  @override
  String get downloadAllSurahs => 'تنزيل كل السور';

  @override
  String downloadAllQueued(String count) {
    return 'جارٍ تنزيل $count سورة';
  }

  @override
  String get downloadAllNothing => 'كل السور منزّلة بالفعل';

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
  String get settingsWirdReminder => 'تذكير الورد';

  @override
  String get settingsWirdReminderTime => 'وقت تذكير الورد';

  @override
  String get settingsPrayerReminder => 'تذكير الصلاة';

  @override
  String get fajrFollowUp => 'تذكير متابعة الفجر';

  @override
  String get fajrFollowUpHint => 'تذكير إضافي بعد ٥ و١٠ دقائق من الفجر';

  @override
  String get reminderFajrFollowUp => 'تذكير: صلاة الفجر';

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
  String readerNoAyahs(String number) {
    return 'لا توجد آيات قابلة للقراءة في السورة $number';
  }

  @override
  String get noResults => 'لا نتائج مطابقة';

  @override
  String searchAyahsFor(String query) {
    return 'ابحث عن «$query» في الآيات';
  }

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
  String get reminderWird => 'حان وقت ورد الختمة';

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

  @override
  String get backupSectionTitle => 'النسخ الاحتياطي والاستعادة';

  @override
  String get backupExport => 'تصدير البيانات';

  @override
  String get backupImport => 'استيراد البيانات';

  @override
  String get backupPreviewTitle => 'مراجعة الاستيراد';

  @override
  String get backupPreviewNothing =>
      'لا توجد تغييرات — النسخة مطابقة لبياناتك الحالية';

  @override
  String get backupMerge => 'دمج';

  @override
  String get backupExportSuccess => 'تم تصدير البيانات';

  @override
  String get backupImportSuccess => 'تم استيراد البيانات ودمجها';

  @override
  String get backupExportFailure => 'تعذّر تصدير البيانات';

  @override
  String get backupImportFailure => 'تعذّر استيراد البيانات';

  @override
  String get backupInvalidFile => 'الملف المختار ليس نسخة احتياطية صالحة';

  @override
  String get backupUnencryptedWarning =>
      'الملف المصدَّر غير مشفَّر — أي شخص يحصل عليه يمكنه قراءة علاماتك وسجل العبادات وإعداداتك. احفظه في مكان آمن.';

  @override
  String get backupExportEncrypted => 'تصدير مشفّر';

  @override
  String get backupEncryptedExportHint =>
      'لا يمكن فتح الملف لاحقًا إلا بعبارة المرور التي تختارها.';

  @override
  String get backupEncryptedPassphrase => 'عبارة مرور التشفير';

  @override
  String get backupEncryptedConfirmPassphrase => 'تأكيد عبارة المرور';

  @override
  String get backupPassphraseMismatch => 'عبارتا المرور غير متطابقتين';

  @override
  String get backupPassphraseEmpty => 'عبارة المرور مطلوبة';

  @override
  String get backupImportPassphraseTitle => 'هذه النسخة مشفّرة';

  @override
  String get backupImportPassphraseBody =>
      'أدخل عبارة مرور التشفير لفكّ النسخة واستعادتها.';

  @override
  String get backupPassphraseCancel => 'إلغاء';

  @override
  String get backupPassphraseConfirm => 'استعادة';

  @override
  String get licensesTitle => 'التراخيص والمصادر';

  @override
  String get licensesContentSection => 'المحتوى';

  @override
  String get licensesQuranText =>
      'نص القرآن الكريم (رواية حفص) — مضمّن في التطبيق';

  @override
  String get licensesSiraj =>
      'المختصر في التفسير (سِراج) — QuranEnc.com، بدون تعديل';

  @override
  String get licensesPickthall => 'ترجمة بيكثال (1930) — ملك عام';

  @override
  String get licensesBukhari => 'صحيح البخاري — النص العربي';

  @override
  String get licensesAzkar =>
      'الأذكار والأدعية والرقية — من المصنفات التقليدية';

  @override
  String get licensesAudio => 'التلاوات الصوتية — mp3quran.net';

  @override
  String get licensesFontsSection => 'الخطوط';

  @override
  String get licensesHafsSmart =>
      'خط KFGQPC Hafs Smart — مملوك لـ KFGQPC، يُستخدم دون تعديل';

  @override
  String get licensesMeQuran =>
      'خط me_quran — © Meor Ridzuan، للاستخدام غير التجاري';

  @override
  String get licensesCairo => 'خط Cairo — SIL Open Font License';

  @override
  String get licensesHafsEula => 'عرض اتفاقية ترخيص خط Hafs Smart';

  @override
  String get licensesMeQuranTerms => 'عرض شروط خط me_quran';

  @override
  String get licensesCairoOfl => 'عرض رخصة Cairo (OFL)';

  @override
  String get licensesOpenSource => 'تراخيص الحزم مفتوحة المصدر';

  @override
  String get licensesWithdrawn =>
      'حِزم التفسير والترجمة غير المرخّصة أُزيلت من التطبيق في 2026-10-24.';

  @override
  String get licensesClose => 'إغلاق';

  @override
  String get licensesUnavailable => 'تعذّر تحميل النص';

  @override
  String backupPreviewBookmarks(String count) {
    return '$count علامة جديدة';
  }

  @override
  String get backupPreviewLastRead => 'سيُحدَّث موضع القراءة';

  @override
  String backupPreviewPrayerDays(String count) {
    return '$count يوم عبادات';
  }

  @override
  String get backupPreviewPlan => 'سيُحدَّث تقدّم الورد';

  @override
  String get backupPreviewTasbih => 'ستُدمج بيانات المسبحة';

  @override
  String backupPreviewSettings(String count) {
    return '$count إعداد';
  }

  @override
  String backupPreviewRejected(String count) {
    return 'تم تجاهل $count عنصرًا غير صالح';
  }

  @override
  String get azkarSearchPlaceholder => 'ابحث في الأذكار…';

  @override
  String azkarSearchResultsFor(String count) {
    return 'نتائج البحث: $count';
  }

  @override
  String get azkarSearchNoResults => 'لا توجد أذكار مطابقة لبحثك';

  @override
  String azkarSearchMore(String count) {
    return 'تُعرض أول $count نتيجة — جرّب تضييق البحث';
  }

  @override
  String libraryPackMeta(String size, String version) {
    return '$size م.ب · $version';
  }

  @override
  String libraryPackSubtitle(String meta, String titleEn) {
    return '$meta · $titleEn';
  }

  @override
  String libraryPackSize(String size) {
    return '$size م.ب';
  }

  @override
  String libraryFailedForPack(String failed, String pack) {
    return '$failed — $pack';
  }

  @override
  String trackerGregorianDate(String day, String month, String year) {
    return '$day/$month/$year';
  }

  @override
  String trackerDotSemantics(String day, String state) {
    return '$day: $state';
  }

  @override
  String shareAyahText(String text, String url) {
    return '$text\n\n$url';
  }

  @override
  String get homeSectionQuran => 'القرآن والاستماع';

  @override
  String get homeSectionWorship => 'العبادة اليومية';

  @override
  String get homeSectionMore => 'المزيد';

  @override
  String get qiblaAligned => 'أنت تواجه القبلة';

  @override
  String get cardinalNorth => 'شمال';

  @override
  String get cardinalEast => 'شرق';

  @override
  String get cardinalSouth => 'جنوب';

  @override
  String get cardinalWest => 'غرب';

  @override
  String qiblaTurnRight(String degrees) {
    return 'أدر الهاتف $degrees درجة يمينًا';
  }

  @override
  String qiblaTurnLeft(String degrees) {
    return 'أدر الهاتف $degrees درجة يسارًا';
  }

  @override
  String get more => 'المزيد';

  @override
  String get copyAyah => 'نسخ الآية';

  @override
  String get ayahCopied => 'تم نسخ الآية';

  @override
  String get libraryEmpty => 'لا توجد حزم معرفية بعد';

  @override
  String get bookmarkRemoveBody => 'ستُحذف هذه العلامة من قائمتك.';

  @override
  String nextPrayerTomorrow(String name, String time) {
    return 'غدًا $name $time';
  }

  @override
  String get hadithEmpty => 'لا توجد أحاديث في هذه الحزمة';

  @override
  String get hadithSearchHint => 'ابحث في الأحاديث';

  @override
  String get hadithSearchEmpty => 'لا توجد نتائج';

  @override
  String get hadithBookmarks => 'الأحاديث المحفوظة';

  @override
  String get hadithNoBookmarks => 'لا توجد أحاديث محفوظة';

  @override
  String get hadithShowAll => 'عرض الكل';

  @override
  String get hadithBookmark => 'حفظ الحديث';

  @override
  String get hadithUnbookmark => 'إزالة الحفظ';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get downloadsTitle => 'التنزيلات';

  @override
  String get downloadsEmpty => 'لا توجد تلاوات منزّلة بعد';

  @override
  String get downloadsNoSpace =>
      'لا توجد مساحة كافية على الجهاز. أفرغ بعض المساحة ثم أعد المحاولة.';

  @override
  String get downloadsDeleteBody => 'سيُحذف هذا الملف من جهازك.';

  @override
  String downloadsTotal(String size) {
    return 'المساحة المستخدمة: $size م.ب';
  }

  @override
  String downloadsCount(String count) {
    return '$count سورة منزّلة';
  }

  @override
  String get downloadsDeleteAll => 'حذف الكل';

  @override
  String get downloadsDeleteAllBody => 'ستُحذف كل التلاوات المنزّلة من جهازك.';

  @override
  String get downloadDeleted => 'تم حذف التنزيل';

  @override
  String get downloadsDeletedAll => 'تم حذف كل التنزيلات';

  @override
  String get licensesQuranUthmani =>
      'نص القرآن العثماني (يونيكود) — مشروع تَنزيل';

  @override
  String get licensesTanzilTerms => 'الإسناد وشروط الاستخدام';

  @override
  String get prayerSettings => 'إعدادات الصلاة';

  @override
  String get prayerCalcMethod => 'طريقة حساب المواقيت';

  @override
  String get prayerMadhab => 'مذهب العصر';

  @override
  String get prayerConfigNote =>
      'تُطبَّق هذه الإعدادات على المواقيت والتذكيرات في هذا الجهاز.';

  @override
  String get forbiddenWindowsTitle => 'أوقات النهي';

  @override
  String get forbiddenWindowsNote => 'تُنهى الصلاة في هذه الأوقات.';

  @override
  String get forbiddenAfterFajr => 'بعد الفجر حتى الشروق';

  @override
  String get forbiddenZenith => 'قبيل الظهر';

  @override
  String get forbiddenAfterAsr => 'بعد العصر حتى المغرب';

  @override
  String get methodEgyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get methodMuslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get methodKarachi => 'جامعة العلوم الإسلامية — كراتشي';

  @override
  String get methodUmmAlQura => 'أم القرى — مكة المكرمة';

  @override
  String get methodDubai => 'دبي';

  @override
  String get methodKuwait => 'الكويت';

  @override
  String get methodQatar => 'قطر';

  @override
  String get methodTurkey => 'ديانت — تركيا';

  @override
  String get methodNorthAmerica => 'ISNA — أمريكا الشمالية';

  @override
  String get madhabShafi => 'الشافعي (الافتراضي)';

  @override
  String get madhabHanafi => 'الحنفي';

  @override
  String get qiblaCalibrationHint =>
      'الاتجاه غير دقيق — أبعد الهاتف عن المعادن وحرّكه على شكل ٨.';

  @override
  String get prayerReminderPerPrayer => 'تنبيه الصلوات';

  @override
  String get preAdhanReminder => 'تذكير قبل الأذان';

  @override
  String get preAdhanOff => 'بدون';

  @override
  String get preAdhanFive => '٥ دقائق';

  @override
  String get preAdhanTen => '١٠ دقائق';

  @override
  String get preAdhanFifteen => '١٥ دقيقة';

  @override
  String get prayerTuning => 'ضبط دقيق';

  @override
  String get prayerHighLatitude => 'قاعدة خطوط العرض العالية';

  @override
  String get highLatitudeNone => 'افتراضي الطريقة';

  @override
  String get highLatitudeMiddle => 'منتصف الليل';

  @override
  String get highLatitudeSeventh => 'سُبع الليل';

  @override
  String get highLatitudeTwilight => 'زاوية الشفق';

  @override
  String get prayerAdjustmentHint =>
      'عدّل دقائق كل صلاة لتطابق مسجدك. القيمة صفر تعني بلا تعديل.';

  @override
  String get prayerAdjustmentDecrease => 'دقيقة أقل';

  @override
  String get prayerAdjustmentIncrease => 'دقيقة أكثر';

  @override
  String reminderAdhanSoon(String prayer, String minutes) {
    return 'اقتربت صلاة $prayer — بعد $minutes دقيقة';
  }

  @override
  String get monthlyTimetable => 'جدول الشهر';

  @override
  String get juzIndexTitle => 'فهرس الأجزاء';

  @override
  String juzLabel(String number) {
    return 'الجزء $number';
  }

  @override
  String get pageJump => 'الانتقال إلى صفحة';

  @override
  String get pageJumpHint => 'رقم الصفحة ١–٦٠٤';

  @override
  String get pageJumpInvalid => 'صفحة غير موجودة';

  @override
  String get pageJumpGo => 'انتقال';

  @override
  String get readerFontSize => 'حجم الخط';

  @override
  String get readerLineSpacing => 'تباعد الأسطر';

  @override
  String get reminderReliabilityTitle => 'موثوقية التذكيرات';

  @override
  String get reminderReliabilityIntro =>
      'قد يوقف نظام التشغيل تذكيرات الصلاة والأذكار — راجع الحالات التالية.';

  @override
  String get reminderIssueNotifications =>
      'إذن الإشعارات مغلق — فعِّله من إعدادات جهازك.';

  @override
  String get reminderIssueExactAlarms =>
      'التنبيهات الدقيقة غير مسموحة — قد تتأخر التذكيرات.';

  @override
  String get reminderIssueBattery =>
      'تحسين استهلاك البطارية قد يوقف التذكيرات — استثنِ التطبيق.';

  @override
  String get reminderIssueScheduleFailed =>
      'تعذّر جدولة التذكيرات — افتح التطبيق مرة أخرى ليُعيد المحاولة.';

  @override
  String get reminderIssueBatteryUnknown =>
      'تعذّر فحص تحسين استهلاك البطارية — تأكد من استثناء التطبيق من تحسين البطارية يدويًا.';

  @override
  String get reminderFixAction => 'إصلاح';

  @override
  String get principlesTitle => 'مبادئ التطبيق';

  @override
  String get principlesFree => 'مجاني بلا إعلانات — ولا نيّة لإدخال إعلانات.';

  @override
  String get principlesNoAccount =>
      'بلا حساب — كل شيء يبقى على جهازك، والنسخ الاحتياطي بيدك أنت.';

  @override
  String get principlesAttribution =>
      'التلاوات منسوبة لأصحابها — أي قائمة مستقبلية تُراجع بشريًا قبل النشر.';

  @override
  String get principlesFuturePaid =>
      'إن أضفنا يومًا ميزة مدفوعة، تبقى كل الميزات الحالية مجانية.';

  @override
  String get reciterPacksTitle => 'حزم القرّاء';

  @override
  String get reciterPacksIntro =>
      'قوائم قرّاء مختارة بعناية، تُراجع بشريًا قبل النشر — بلا ترتيب مدفوع وبلا معيار تجاري. التلاوات تُبثّ من مصادرها كما هي، والتنزيل قرارك في كل سورة.';

  @override
  String get reciterPacksCriteriaTitle => 'معايير الانتقاء';

  @override
  String get reciterPacksCriterion1 =>
      'صحة الأداء ومخارج الحروف — مراجعة بشرية';

  @override
  String get reciterPacksCriterion2 => 'اكتمال المصحف (١١٤ سورة)';

  @override
  String get reciterPacksCriterion3 => 'جودة التسجيل وثباته';

  @override
  String get reciterPacksCriterion4 => 'تنوّع الأسلوب (مرتل/مجوّد/معلّم)';

  @override
  String get reciterPacksCriterion5 => 'لا معيار تجاري ولا ترتيب مدفوع';

  @override
  String reciterPacksReviewer(String reviewer) {
    return 'راجعها: $reviewer';
  }

  @override
  String get reciterPacksEmpty =>
      'لا توجد حزمة منشورة بعد — تُنشر أول حزمة بعد توقيع مراجع بشري.';

  @override
  String get adhanTitle => 'صوت الأذان';

  @override
  String get adhanDefaultSection => 'الأذان الافتراضي';

  @override
  String get adhanFajrSection => 'أذان الفجر';

  @override
  String get adhanSameAsDefault => 'مثل الافتراضي';

  @override
  String get adhanPreview => 'استماع';

  @override
  String get adhanStopPreview => 'إيقاف';

  @override
  String get adhanPlayAction => 'تشغيل الأذان';

  @override
  String get updateRequiredTitle => 'تحديث مطلوب';

  @override
  String get updateRequiredBody =>
      'النسخة المثبّتة من التطبيق لم تعد مدعومة. حدّث التطبيق للمتابعة — لا يمكن استخدام التطبيق قبل التحديث.';

  @override
  String get updateRecommendedTitle => 'يتوفر تحديث';

  @override
  String get updateRecommendedBody =>
      'نسخة أحدث متاحة. نوصي بالتحديث للاستفادة من التحسينات وإصلاحات المشاكل.';

  @override
  String get updateNow => 'حدّث الآن';

  @override
  String get updateLater => 'لاحقاً';

  @override
  String get updateUnavailable =>
      'تعذر فتح المتجر. يمكنك التحديث من صفحة التطبيق على متجر Play.';
}
