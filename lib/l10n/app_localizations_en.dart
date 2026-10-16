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
  String get bookmarks => 'Bookmarks';

  @override
  String get bookmarkSave => 'Bookmark this ayah';

  @override
  String get bookmarkRemove => 'Remove bookmark';

  @override
  String get noBookmarks => 'No bookmarks yet';

  @override
  String pageIndicator(String page) {
    return 'Page $page';
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
  String get qiblaDirection => 'Qibla direction';

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
  String get duasTab => 'Duas';

  @override
  String get ruqyahTab => 'Ruqyah';

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
  String hijriDate(String month, String year) {
    return '$month $year AH';
  }

  @override
  String gregorianEquivalent(String date) {
    return '= $date';
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
  String get stopAction => 'Stop';
}
