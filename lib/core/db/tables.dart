import 'package:drift/drift.dart';

/// Surah metadata: names, revelation type and the mushaf page range.
class Surahs extends Table {
  IntColumn get id => integer()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();

  /// Revelation type as stored in the catalog: 'makki' or 'madani'.
  TextColumn get revelationType => text()();
  IntColumn get ayahCount => integer()();

  /// First mushaf page of the surah (inclusive).
  IntColumn get pagesStart => integer()();

  /// Last mushaf page of the surah (inclusive).
  IntColumn get pagesEnd => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

/// The Quran text: one row per ayah, with page/line and sajda flags.
class Ayahs extends Table {
  /// Global ayah number, 1..6236 across the whole Quran.
  IntColumn get id => integer()(); // 1..6236 global ayah number
  IntColumn get surahId => integer()();

  /// Ayah number within its own surah, 1-based.
  IntColumn get numberInSurah => integer()();

  /// Juz' (30-part division) the ayah belongs to, 1-based.
  IntColumn get juz => integer()();

  /// Mushaf page the ayah starts on, 1-based.
  IntColumn get page => integer()();

  /// First line of the ayah on its page; null when the page has no line map.
  IntColumn get lineStart => integer().nullable()();

  /// Last line of the ayah on its page; null when the page has no line map.
  IntColumn get lineEnd => integer().nullable()();
  TextColumn get textUthmani => text()();
  TextColumn get textImlaei => text()();

  /// True when the ayah ends with a sajda (prostration) marker.
  BoolColumn get sajda => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

/// User bookmarks, one row per bookmarked ayah.
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Global ayah number that was bookmarked.
  IntColumn get ayahId => integer()();

  /// When the bookmark was created (defaults to write time).
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// The single active khatma (reading-plan) row.
class KhatmaProgress extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Global ayah number the plan is anchored at.
  IntColumn get ayahId => integer()();

  /// Page count the user aimed to finish.
  IntColumn get targetPages => integer()();

  /// When the plan last moved (defaults to write time).
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per day recording which prayers were marked.
class PrayerLog extends Table {
  /// The calendar day this row describes.
  DateTimeColumn get day => dateTime()();

  /// Fajr marked on [day].
  BoolColumn get fajr => boolean().withDefault(const Constant(false))();

  /// Dhuhr marked on [day].
  BoolColumn get dhuhr => boolean().withDefault(const Constant(false))();

  /// Asr marked on [day].
  BoolColumn get asr => boolean().withDefault(const Constant(false))();

  /// Maghrib marked on [day].
  BoolColumn get maghrib => boolean().withDefault(const Constant(false))();

  /// Isha marked on [day].
  BoolColumn get isha => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {day};
}

/// Library packs installed on this device.
class InstalledPacks extends Table {
  /// Catalog id of the installed pack.
  TextColumn get packId => text()();

  /// Pack kind as stored: 'tafsir', 'translation' or 'hadith'.
  TextColumn get kind => text()(); // tafsir | translation | hadith
  TextColumn get language => text()();

  /// Display title of the installed pack.
  TextColumn get title => text()();

  /// Installed size in megabytes.
  RealColumn get sizeMb => real()();

  /// Catalog version of the installed pack.
  TextColumn get version => text()();

  /// When the pack finished installing (defaults to write time).
  DateTimeColumn get installedAt =>
      dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {packId};
}

/// Audio download queue: one row per reciter/surah pair.
class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Reciter (moshaf) id owning the download.
  TextColumn get reciterId => text()();

  /// Surah number being downloaded.
  IntColumn get surahId => integer()();

  /// Download state: 'queued', 'downloading', 'done' or 'failed'.
  TextColumn get status => text()(); // queued|downloading|done|failed
  /// Bytes received so far.
  IntColumn get bytes => integer().withDefault(const Constant(0))();

  /// Absolute path of the finished file; empty while downloading.
  TextColumn get path => text()();
}

/// Key/value store for app settings (selected city, reminders, …).
class SettingsTable extends Table {
  /// Setting key.
  TextColumn get key => text()();

  /// Setting value, stored as text.
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('ReciterRow')

/// Cached reciter rows mirroring the remote reciters catalog.
class Reciters extends Table {
  /// Row id in `<reciterId>-<moshafId>` form.
  TextColumn get id => text()(); // "reciterId-moshafId"
  TextColumn get reciterName => text()();
  TextColumn get moshafName => text()();
  TextColumn get server => text()();

  /// Comma-separated surah numbers the moshaf offers, e.g. '1,2,3'.
  TextColumn get surahList => text()(); // "1,2,3,..."
  /// Number of surahs the moshaf offers.
  IntColumn get surahTotal => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Hadith rows imported from an installed hadith pack.
///
/// The pack JSON stays the canonical downloaded artifact; this table is a
/// derived read index so a browse page can use SQL LIMIT/OFFSET instead of
/// retaining the whole decoded pack in memory.
class HadithEntries extends Table {
  /// Catalog id of the owning hadith pack.
  TextColumn get packId => text()();

  /// Zero-based position in the pack's `hadiths` array. This is the stable
  /// paging key; malformed source slots keep their ordinal as empty rows.
  IntColumn get ordinal => integer()();

  /// Printed hadith number; -1 for a malformed source entry.
  IntColumn get number => integer()();

  /// Hadith body. Empty text is a valid source value (the UI hides those
  /// rows); a malformed source entry is marked by [number] == -1.
  TextColumn get body => text()();

  @override
  Set<Column> get primaryKey => {packId, ordinal};
}
