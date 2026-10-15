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
}
