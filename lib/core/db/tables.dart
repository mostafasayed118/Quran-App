import 'package:drift/drift.dart';

class Surahs extends Table {
  IntColumn get id => integer()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get revelationType => text()();
  IntColumn get ayahCount => integer()();
  IntColumn get pagesStart => integer()();
  IntColumn get pagesEnd => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

class Ayahs extends Table {
  IntColumn get id => integer()(); // 1..6236 global ayah number
  IntColumn get surahId => integer()();
  IntColumn get numberInSurah => integer()();
  IntColumn get juz => integer()();
  IntColumn get page => integer()();
  IntColumn get lineStart => integer().nullable()();
  IntColumn get lineEnd => integer().nullable()();
  TextColumn get textUthmani => text()();
  TextColumn get textImlaei => text()();
  BoolColumn get sajda => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class KhatmaProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer()();
  IntColumn get targetPages => integer()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PrayerLog extends Table {
  DateTimeColumn get day => dateTime()();
  BoolColumn get fajr => boolean().withDefault(const Constant(false))();
  BoolColumn get dhuhr => boolean().withDefault(const Constant(false))();
  BoolColumn get asr => boolean().withDefault(const Constant(false))();
  BoolColumn get maghrib => boolean().withDefault(const Constant(false))();
  BoolColumn get isha => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {day};
}

class InstalledPacks extends Table {
  TextColumn get packId => text()();
  TextColumn get kind => text()(); // tafsir | translation | hadith
  TextColumn get language => text()();
  TextColumn get title => text()();
  RealColumn get sizeMb => real()();
  TextColumn get version => text()();
  DateTimeColumn get installedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {packId};
}

class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get reciterId => text()();
  IntColumn get surahId => integer()();
  TextColumn get status => text()(); // queued|downloading|done|failed
  IntColumn get bytes => integer().withDefault(const Constant(0))();
  TextColumn get path => text()();
}

class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('ReciterRow')
class Reciters extends Table {
  TextColumn get id => text()(); // "reciterId-moshafId"
  TextColumn get reciterName => text()();
  TextColumn get moshafName => text()();
  TextColumn get server => text()();
  TextColumn get surahList => text()(); // "1,2,3,..."
  IntColumn get surahTotal => integer()();
  @override
  Set<Column> get primaryKey => {id};
}
