// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Quran Yahdi';

  @override
  String get home => 'Home';

  @override
  String get quran => 'Quran';

  @override
  String get azkar => 'Azkar';

  @override
  String get tasbih => 'Tasbih';

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get qibla => 'Qibla';

  @override
  String get duasAndRuqyah => 'Duas & Ruqyah';

  @override
  String get worshipTracker => 'Worship Tracker';

  @override
  String get zakat => 'Zakat';

  @override
  String get hijriCalendar => 'Hijri Calendar';

  @override
  String get asmaUlHusna => '99 Names of Allah';

  @override
  String get settings => 'Settings';

  @override
  String get recitations => 'Recitations';

  @override
  String get library => 'Library';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String continueReadingAyah(String ayah) {
    return '﴿$ayah﴾ Continue Reading';
  }

  @override
  String get surahIndexTitle => 'The Noble Quran';

  @override
  String get searchSurahHint => 'Search a surah…';

  @override
  String get revelationMakkah => 'Meccan';

  @override
  String get revelationMadinah => 'Medinan';

  @override
  String ayatCount(int count) {
    return '$count verses';
  }

  @override
  String get mushafMode => 'Mushaf Mode';

  @override
  String get versesMode => 'Verses Mode';

  @override
  String get basmala => 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get bookmarkSave => 'Bookmark this ayah';

  @override
  String get bookmarkRemove => 'Remove bookmark';

  @override
  String get shareAyah => 'Share verse';

  @override
  String get noBookmarks => 'No bookmarks yet';

  @override
  String pageIndicator(String page) {
    return 'Page $page';
  }

  @override
  String ornateBrackets(String text) {
    return '﴿$text﴾';
  }

  @override
  String ayahNumberLabel(String number) {
    return 'Ayah $number';
  }

  @override
  String get recitationsTitle => 'Recitations';

  @override
  String get searchReciters => 'Search a reciter…';

  @override
  String get featured => 'Featured';

  @override
  String get allReciters => 'All reciters';

  @override
  String get noReciters => 'Load the reciters index from the internet';

  @override
  String get refresh => 'Refresh';

  @override
  String surahCountLabel(String count) {
    return '$count surahs';
  }

  @override
  String nowPlaying(String name) {
    return 'Now playing: $name';
  }

  @override
  String get playTooltip => 'Play';

  @override
  String get pauseTooltip => 'Pause';

  @override
  String get stopTooltip => 'Stop';

  @override
  String get listenTooltip => 'Listen to surah';

  @override
  String surahBadge(String number) {
    return 'Surah $number';
  }

  @override
  String get playbackFailed => 'Could not play the recitation';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String remaining(String duration) {
    return '$duration remaining';
  }

  @override
  String get selectCity => 'Select your city';

  @override
  String get searchCity => 'Search a city…';

  @override
  String get noCity => 'No city selected yet';

  @override
  String degreesFromNorth(String degrees) {
    return '$degrees° from north';
  }

  @override
  String azkarItemsCount(String count) {
    return '$count items';
  }

  @override
  String get azkarDone => 'Done';

  @override
  String get tasbihReset => 'Reset';

  @override
  String get tasbihTarget => 'Target';

  @override
  String get tasbihTargetSet => 'Target set — count restarted';

  @override
  String get duasTab => 'Duas';

  @override
  String get ruqyahTab => 'Ruqyah';

  @override
  String duaRepeat(String count) {
    return '×$count';
  }

  @override
  String namePosition(String n) {
    return 'Name $n of 99';
  }

  @override
  String streak(String days) {
    return '$days-day streak';
  }

  @override
  String get trackerToday => 'Today\'s prayers';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get trackerDotToday => 'Today';

  @override
  String get trackerDotYesterday => 'Yesterday';

  @override
  String get trackerDotTwoDaysAgo => '2 days ago';

  @override
  String trackerDotDaysAgo(String days) {
    return '$days days ago';
  }

  @override
  String get trackerDotMarked => 'Logged';

  @override
  String get trackerDotUnmarked => 'Not logged';

  @override
  String get goldGrams => 'Gold (grams)';

  @override
  String get silverGrams => 'Silver (grams)';

  @override
  String get goldPrice => 'Gold price per gram';

  @override
  String get silverPrice => 'Silver price per gram';

  @override
  String get cash => 'On-hand cash';

  @override
  String get debts => 'Debts';

  @override
  String get nisabByGold => 'Threshold: gold';

  @override
  String get nisabBySilver => 'Threshold: silver';

  @override
  String get zakatDue => 'Zakat due';

  @override
  String get zakatNotDue => 'No zakat due';

  @override
  String get zakatFootnote =>
      'The rate is fixed at 2.5% and the threshold applies — consult scholars for your estimate.';

  @override
  String get zakatableLabel => 'Money subject to zakat';

  @override
  String get nisabLabel => 'Threshold';

  @override
  String get zakatEnterPrice =>
      'Enter the gold/silver price to compute the nisab';

  @override
  String hijriDate(String month, String year) {
    return '$month $year AH';
  }

  @override
  String get jumpToToday => 'Today';

  @override
  String get tafsirTab => 'Tafsir';

  @override
  String get translationsTab => 'Translations';

  @override
  String get hadithTab => 'Hadith';

  @override
  String get libraryInstall => 'Install';

  @override
  String get libraryDelete => 'Delete';

  @override
  String get libraryInstalled => 'Installed';

  @override
  String get libraryFailed => 'Download failed';

  @override
  String get libraryRetry => 'Retry';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get ayahSheetTitle => 'Ayah tafsir & translation';

  @override
  String get ayahSheetTafsir => 'Tafsir';

  @override
  String get ayahSheetTranslation => 'Translation';

  @override
  String get libraryEmptyHint =>
      'No tafsir installed — get one from the Library';

  @override
  String get hadithNext => 'Next';

  @override
  String get hadithPrev => 'Previous';

  @override
  String surahFallbackName(String n) {
    return 'Surah $n';
  }

  @override
  String get defaultReciterSet => 'Set as your default reciter';

  @override
  String get unknownInitial => '؟';

  @override
  String get hadithRead => 'Read';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get locating => 'Locating…';

  @override
  String get locationUnavailable => 'Could not get location — pick manually';

  @override
  String get compassLive => 'Dial follows your device';

  @override
  String get compassStatic =>
      'Dial is static — live direction is not available on this device';

  @override
  String reminderNextPrayer(String prayer) {
    return 'Time for $prayer';
  }

  @override
  String get reminderAzkar => 'Morning azkar';

  @override
  String get notificationsEnabledHint =>
      'If reminders do not arrive, enable notifications permission in your device settings';

  @override
  String get azkarReminder => 'Azkar reminder';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get settingsMinimalNote => 'Dark mode follows your device';

  @override
  String get settingsWirdReminder => 'Wird reminder';

  @override
  String get settingsWirdReminderTime => 'Wird reminder time';

  @override
  String get stopAction => 'Stop';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get backTooltip => 'Back';

  @override
  String get downloadSurah => 'Download surah';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get pageNotFoundHint => 'The link you followed does not exist here';

  @override
  String get genericError => 'Sorry, something went wrong — try again';

  @override
  String readerNoAyahs(String number) {
    return 'No readable ayahs in surah $number';
  }

  @override
  String get noResults => 'No matching results';

  @override
  String get recitersRefreshFailed => 'Couldn\'t refresh the reciters list';

  @override
  String downloadProgressReceived(String received) {
    return '$received MB';
  }

  @override
  String downloadProgressOfTotal(String received, String total) {
    return '$received of $total MB';
  }

  @override
  String get playbackNoReciters =>
      'Couldn\'t play — load the reciters index from the internet';

  @override
  String get playbackBackgroundFailed =>
      'Couldn\'t play the recitation — background audio is unavailable';

  @override
  String get currentCity => 'Current city';

  @override
  String get locationSettings => 'Location settings';

  @override
  String get reminderChannelDescription => 'Prayer and azkar reminders';

  @override
  String get reminderWird => 'Time for your khatma wird';

  @override
  String get wirdTitle => 'Khatma wird';

  @override
  String get wirdSetupHint => 'Pick a khatma pace and start your daily wird';

  @override
  String get wirdStart => 'Start a khatma';

  @override
  String get wirdPaceSheetTitle => 'Khatma pace';

  @override
  String get wirdPaceMonthly => 'A khatma every month';

  @override
  String get wirdPaceTwoMonths => 'A khatma every 2 months';

  @override
  String get wirdPaceThreeMonths => 'A khatma every 3 months';

  @override
  String get wirdPaceFourMonths => 'A khatma every 4 months';

  @override
  String wirdDailyPages(String pages) {
    return 'About $pages pages a day';
  }

  @override
  String wirdProgress(String done, String total) {
    return '$done of $total pages';
  }

  @override
  String wirdTodayRange(String from, String to) {
    return 'Today: from page $from to $to';
  }

  @override
  String wirdRemainingDays(String days) {
    return 'About $days days left';
  }

  @override
  String get wirdOpenToday => 'Open the wird';

  @override
  String get wirdFinishToday => 'Finished today\'s wird';

  @override
  String get wirdCompleted => 'Khatma completed';

  @override
  String get wirdNewPlan => 'New khatma';

  @override
  String get backupSectionTitle => 'Backup & restore';

  @override
  String get backupExport => 'Export data';

  @override
  String get backupImport => 'Import data';

  @override
  String get backupPreviewTitle => 'Review import';

  @override
  String get backupMerge => 'Merge';

  @override
  String get backupExportSuccess => 'Data exported';

  @override
  String get backupImportSuccess => 'Data imported and merged';

  @override
  String get backupExportFailure => 'Couldn\'t export the data';

  @override
  String get backupImportFailure => 'Couldn\'t import the data';

  @override
  String get backupInvalidFile => 'The selected file isn\'t a valid backup';

  @override
  String get backupUnencryptedWarning =>
      'The exported file isn\'t encrypted — anyone who gets it can read your bookmarks, worship log and settings. Keep it somewhere safe.';

  @override
  String get licensesTitle => 'Licenses & sources';

  @override
  String get licensesContentSection => 'Content';

  @override
  String get licensesQuranText => 'Quran text (Hafs) — bundled in the app';

  @override
  String get licensesSiraj =>
      'At-Tafsir Al-Mukhtasar (Siraj) — QuranEnc.com, unmodified';

  @override
  String get licensesPickthall =>
      'Pickthall translation (1930) — public domain';

  @override
  String get licensesBukhari => 'Sahih al-Bukhari — Arabic text';

  @override
  String get licensesAzkar =>
      'Adhkar, duas and ruqyah — traditional compilations';

  @override
  String get licensesAudio => 'Recitation audio — mp3quran.net';

  @override
  String get licensesFontsSection => 'Fonts';

  @override
  String get licensesHafsSmart =>
      'KFGQPC Hafs Smart font — owned by KFGQPC, used unmodified';

  @override
  String get licensesMeQuran =>
      'me_quran font — © Meor Ridzuan, non-commercial use';

  @override
  String get licensesCairo => 'Cairo font — SIL Open Font License';

  @override
  String get licensesHafsEula => 'View the Hafs Smart font EULA';

  @override
  String get licensesMeQuranTerms => 'View the me_quran terms';

  @override
  String get licensesCairoOfl => 'View the Cairo OFL';

  @override
  String get licensesOpenSource => 'Open-source package licenses';

  @override
  String get licensesWithdrawn =>
      'Unlicensed tafsir/translation packs were removed from the app on 2026-10-24.';

  @override
  String get licensesClose => 'Close';

  @override
  String get licensesUnavailable => 'Couldn\'t load the text';

  @override
  String backupPreviewBookmarks(String count) {
    return '$count new bookmarks';
  }

  @override
  String get backupPreviewLastRead => 'Last-read position will be updated';

  @override
  String backupPreviewPrayerDays(String count) {
    return '$count worship days';
  }

  @override
  String get backupPreviewPlan => 'Khatma progress will be updated';

  @override
  String get backupPreviewTasbih => 'Tasbih data will be merged';

  @override
  String backupPreviewSettings(String count) {
    return '$count settings';
  }

  @override
  String get azkarSearchPlaceholder => 'Search the azkar…';

  @override
  String azkarSearchResultsFor(String count) {
    return 'Search results: $count';
  }

  @override
  String get azkarSearchNoResults => 'No azkar match your search';

  @override
  String azkarSearchMore(String count) {
    return 'Showing the first $count results — try narrowing your search';
  }
}
