import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'قرآن يَهدي'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @quran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get quran;

  /// No description provided for @azkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get azkar;

  /// No description provided for @tasbih.
  ///
  /// In ar, this message translates to:
  /// **'السبحة'**
  String get tasbih;

  /// No description provided for @prayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get prayerTimes;

  /// No description provided for @qibla.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get qibla;

  /// No description provided for @duasAndRuqyah.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية والرقية'**
  String get duasAndRuqyah;

  /// No description provided for @worshipTracker.
  ///
  /// In ar, this message translates to:
  /// **'تتبع العبادات'**
  String get worshipTracker;

  /// No description provided for @zakat.
  ///
  /// In ar, this message translates to:
  /// **'الزكاة'**
  String get zakat;

  /// No description provided for @hijriCalendar.
  ///
  /// In ar, this message translates to:
  /// **'التقويم الهجري'**
  String get hijriCalendar;

  /// No description provided for @asmaUlHusna.
  ///
  /// In ar, this message translates to:
  /// **'أسماء الله الحسنى'**
  String get asmaUlHusna;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @recitations.
  ///
  /// In ar, this message translates to:
  /// **'التلاوات'**
  String get recitations;

  /// No description provided for @library.
  ///
  /// In ar, this message translates to:
  /// **'المكتبة'**
  String get library;

  /// No description provided for @nextPrayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة'**
  String get nextPrayer;

  /// No description provided for @continueReading.
  ///
  /// In ar, this message translates to:
  /// **'متابعة القراءة'**
  String get continueReading;

  /// No description provided for @continueReadingAyah.
  ///
  /// In ar, this message translates to:
  /// **'﴿{ayah}﴾ متابعة القراءة'**
  String continueReadingAyah(String ayah);

  /// No description provided for @surahIndexTitle.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get surahIndexTitle;

  /// No description provided for @searchSurahHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بسورة…'**
  String get searchSurahHint;

  /// No description provided for @revelationMakkah.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get revelationMakkah;

  /// No description provided for @revelationMadinah.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get revelationMadinah;

  /// No description provided for @ayatCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آيات'**
  String ayatCount(int count);

  /// No description provided for @mushafMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع المصحف'**
  String get mushafMode;

  /// No description provided for @versesMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع الآيات'**
  String get versesMode;

  /// No description provided for @bookmarks.
  ///
  /// In ar, this message translates to:
  /// **'العلامات المرجعية'**
  String get bookmarks;

  /// No description provided for @bookmarkSave.
  ///
  /// In ar, this message translates to:
  /// **'احفظ الآية'**
  String get bookmarkSave;

  /// No description provided for @bookmarkRemove.
  ///
  /// In ar, this message translates to:
  /// **'أزل الحفظ'**
  String get bookmarkRemove;

  /// No description provided for @noBookmarks.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد علامات مرجعية بعد'**
  String get noBookmarks;

  /// No description provided for @pageIndicator.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {page}'**
  String pageIndicator(String page);

  /// No description provided for @ornateBrackets.
  ///
  /// In ar, this message translates to:
  /// **'﴿{text}﴾'**
  String ornateBrackets(String text);

  /// No description provided for @ayahNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'الآية {number}'**
  String ayahNumberLabel(String number);

  /// No description provided for @recitationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التلاوات'**
  String get recitationsTitle;

  /// No description provided for @searchReciters.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن قارئ…'**
  String get searchReciters;

  /// No description provided for @featured.
  ///
  /// In ar, this message translates to:
  /// **'مختارات'**
  String get featured;

  /// No description provided for @allReciters.
  ///
  /// In ar, this message translates to:
  /// **'كل القرّاء'**
  String get allReciters;

  /// No description provided for @noReciters.
  ///
  /// In ar, this message translates to:
  /// **'حمّل فهرس القرّاء من الإنترنت'**
  String get noReciters;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @surahCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'{count} سورة'**
  String surahCountLabel(String count);

  /// No description provided for @nowPlaying.
  ///
  /// In ar, this message translates to:
  /// **'يُشغَّل الآن: {name}'**
  String nowPlaying(String name);

  /// No description provided for @playTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get playTooltip;

  /// No description provided for @pauseTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pauseTooltip;

  /// No description provided for @stopTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get stopTooltip;

  /// No description provided for @listenTooltip.
  ///
  /// In ar, this message translates to:
  /// **'استمع للسورة'**
  String get listenTooltip;

  /// No description provided for @surahBadge.
  ///
  /// In ar, this message translates to:
  /// **'سورة {number}'**
  String surahBadge(String number);

  /// No description provided for @playbackFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل التلاوة'**
  String get playbackFailed;

  /// No description provided for @fajr.
  ///
  /// In ar, this message translates to:
  /// **'فجر'**
  String get fajr;

  /// No description provided for @sunrise.
  ///
  /// In ar, this message translates to:
  /// **'شروق'**
  String get sunrise;

  /// No description provided for @dhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get isha;

  /// No description provided for @remaining.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ {duration}'**
  String remaining(String duration);

  /// No description provided for @selectCity.
  ///
  /// In ar, this message translates to:
  /// **'اختر مدينتك'**
  String get selectCity;

  /// No description provided for @searchCity.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مدينة…'**
  String get searchCity;

  /// No description provided for @noCity.
  ///
  /// In ar, this message translates to:
  /// **'لم تُحدَّد مدينة بعد'**
  String get noCity;

  /// No description provided for @degreesFromNorth.
  ///
  /// In ar, this message translates to:
  /// **'{degrees}° عن الشمال'**
  String degreesFromNorth(String degrees);

  /// No description provided for @azkarItemsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} ذكر'**
  String azkarItemsCount(String count);

  /// No description provided for @azkarDone.
  ///
  /// In ar, this message translates to:
  /// **'تم بحمد الله'**
  String get azkarDone;

  /// No description provided for @tasbihReset.
  ///
  /// In ar, this message translates to:
  /// **'تصفير'**
  String get tasbihReset;

  /// No description provided for @tasbihTarget.
  ///
  /// In ar, this message translates to:
  /// **'الهدف'**
  String get tasbihTarget;

  /// No description provided for @duasTab.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية'**
  String get duasTab;

  /// No description provided for @ruqyahTab.
  ///
  /// In ar, this message translates to:
  /// **'الرقية'**
  String get ruqyahTab;

  /// No description provided for @namePosition.
  ///
  /// In ar, this message translates to:
  /// **'الاسم {n} من 99'**
  String namePosition(String n);

  /// No description provided for @streak.
  ///
  /// In ar, this message translates to:
  /// **'سلسلة {days} يوم'**
  String streak(String days);

  /// No description provided for @trackerToday.
  ///
  /// In ar, this message translates to:
  /// **'صلوات اليوم'**
  String get trackerToday;

  /// No description provided for @last7Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر ٧ أيام'**
  String get last7Days;

  /// No description provided for @goldGrams.
  ///
  /// In ar, this message translates to:
  /// **'ذهب (جرام)'**
  String get goldGrams;

  /// No description provided for @silverGrams.
  ///
  /// In ar, this message translates to:
  /// **'فضة (جرام)'**
  String get silverGrams;

  /// No description provided for @goldPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر جرام الذهب'**
  String get goldPrice;

  /// No description provided for @silverPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر جرام الفضة'**
  String get silverPrice;

  /// No description provided for @cash.
  ///
  /// In ar, this message translates to:
  /// **'النقد المعروض'**
  String get cash;

  /// No description provided for @debts.
  ///
  /// In ar, this message translates to:
  /// **'الديون'**
  String get debts;

  /// No description provided for @nisabByGold.
  ///
  /// In ar, this message translates to:
  /// **'العتبة: الذهب'**
  String get nisabByGold;

  /// No description provided for @nisabBySilver.
  ///
  /// In ar, this message translates to:
  /// **'العتبة: الفضة'**
  String get nisabBySilver;

  /// No description provided for @zakatDue.
  ///
  /// In ar, this message translates to:
  /// **'الزكاة الواجبة'**
  String get zakatDue;

  /// No description provided for @zakatNotDue.
  ///
  /// In ar, this message translates to:
  /// **'لا زكاة عليك'**
  String get zakatNotDue;

  /// No description provided for @zakatFootnote.
  ///
  /// In ar, this message translates to:
  /// **'النسبة ثابتة 2.5% والعتبار على العتبة — راجع أهل العلم في تقديرك.'**
  String get zakatFootnote;

  /// No description provided for @zakatableLabel.
  ///
  /// In ar, this message translates to:
  /// **'المال الزكوي'**
  String get zakatableLabel;

  /// No description provided for @nisabLabel.
  ///
  /// In ar, this message translates to:
  /// **'العتبة'**
  String get nisabLabel;

  /// No description provided for @hijriDate.
  ///
  /// In ar, this message translates to:
  /// **'الشهر {month} سنة {year}'**
  String hijriDate(String month, String year);

  /// No description provided for @jumpToToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get jumpToToday;

  /// No description provided for @tafsirTab.
  ///
  /// In ar, this message translates to:
  /// **'التفسير'**
  String get tafsirTab;

  /// No description provided for @translationsTab.
  ///
  /// In ar, this message translates to:
  /// **'الترجمات'**
  String get translationsTab;

  /// No description provided for @hadithTab.
  ///
  /// In ar, this message translates to:
  /// **'الأحاديث'**
  String get hadithTab;

  /// No description provided for @libraryInstall.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل'**
  String get libraryInstall;

  /// No description provided for @libraryDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get libraryDelete;

  /// No description provided for @libraryInstalled.
  ///
  /// In ar, this message translates to:
  /// **'مثبّت'**
  String get libraryInstalled;

  /// No description provided for @libraryFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التنزيل'**
  String get libraryFailed;

  /// No description provided for @libraryRetry.
  ///
  /// In ar, this message translates to:
  /// **'أعِد المحاولة'**
  String get libraryRetry;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'أعِد المحاولة'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @ayahSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفسير الآية وترجمتها'**
  String get ayahSheetTitle;

  /// No description provided for @ayahSheetTafsir.
  ///
  /// In ar, this message translates to:
  /// **'تفسير'**
  String get ayahSheetTafsir;

  /// No description provided for @ayahSheetTranslation.
  ///
  /// In ar, this message translates to:
  /// **'ترجمة'**
  String get ayahSheetTranslation;

  /// No description provided for @libraryEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تفسير مثبّت — نزّل من المكتبة'**
  String get libraryEmptyHint;

  /// No description provided for @hadithNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get hadithNext;

  /// No description provided for @hadithPrev.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get hadithPrev;

  /// No description provided for @surahFallbackName.
  ///
  /// In ar, this message translates to:
  /// **'سورة {n}'**
  String surahFallbackName(String n);

  /// No description provided for @defaultReciterSet.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيينه قارئك الافتراضي'**
  String get defaultReciterSet;

  /// No description provided for @unknownInitial.
  ///
  /// In ar, this message translates to:
  /// **'؟'**
  String get unknownInitial;

  /// No description provided for @hadithRead.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ'**
  String get hadithRead;

  /// No description provided for @useMyLocation.
  ///
  /// In ar, this message translates to:
  /// **'استخدم موقعي'**
  String get useMyLocation;

  /// No description provided for @locating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديد الموقع…'**
  String get locating;

  /// No description provided for @locationUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد الموقع — اختر يدويًا'**
  String get locationUnavailable;

  /// No description provided for @compassLive.
  ///
  /// In ar, this message translates to:
  /// **'المقياس حي'**
  String get compassLive;

  /// No description provided for @reminderNextPrayer.
  ///
  /// In ar, this message translates to:
  /// **'حان موعد صلاة {prayer}'**
  String reminderNextPrayer(String prayer);

  /// No description provided for @reminderAzkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get reminderAzkar;

  /// No description provided for @notificationsEnabledHint.
  ///
  /// In ar, this message translates to:
  /// **'إن لم تصلك التذكيرات، فعِّل إذن الإشعارات من إعدادات جهازك'**
  String get notificationsEnabledHint;

  /// No description provided for @azkarReminder.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الأذكار'**
  String get azkarReminder;

  /// No description provided for @reminderTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت التذكير'**
  String get reminderTime;

  /// No description provided for @settingsMinimalNote.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي من إعدادات جهازك'**
  String get settingsMinimalNote;

  /// No description provided for @stopAction.
  ///
  /// In ar, this message translates to:
  /// **'وقف'**
  String get stopAction;

  /// No description provided for @previousMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر السابق'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر التالي'**
  String get nextMonth;

  /// No description provided for @clearSelection.
  ///
  /// In ar, this message translates to:
  /// **'مسح الاختيار'**
  String get clearSelection;

  /// No description provided for @backTooltip.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get backTooltip;

  /// No description provided for @downloadSurah.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل السورة'**
  String get downloadSurah;

  /// No description provided for @pageNotFound.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير موجودة'**
  String get pageNotFound;

  /// No description provided for @pageNotFoundHint.
  ///
  /// In ar, this message translates to:
  /// **'الرابط الذي فتحت غير موجود هنا'**
  String get pageNotFoundHint;

  /// No description provided for @genericError.
  ///
  /// In ar, this message translates to:
  /// **'عذرًا، حدث خطأ — حاول مرة أخرى'**
  String get genericError;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج مطابقة'**
  String get noResults;

  /// No description provided for @recitersRefreshFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديث قائمة القرّاء'**
  String get recitersRefreshFailed;

  /// No description provided for @downloadProgressReceived.
  ///
  /// In ar, this message translates to:
  /// **'{received} م.ب'**
  String downloadProgressReceived(String received);

  /// No description provided for @downloadProgressOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'{received} من {total} م.ب'**
  String downloadProgressOfTotal(String received, String total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
