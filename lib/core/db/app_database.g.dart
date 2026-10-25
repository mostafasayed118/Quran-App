// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SurahsTable extends Surahs with TableInfo<$SurahsTable, Surah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameArMeta = const VerificationMeta('nameAr');
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
      'name_ar', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
      'name_en', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _revelationTypeMeta =
      const VerificationMeta('revelationType');
  @override
  late final GeneratedColumn<String> revelationType = GeneratedColumn<String>(
      'revelation_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ayahCountMeta =
      const VerificationMeta('ayahCount');
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
      'ayah_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pagesStartMeta =
      const VerificationMeta('pagesStart');
  @override
  late final GeneratedColumn<int> pagesStart = GeneratedColumn<int>(
      'pages_start', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pagesEndMeta =
      const VerificationMeta('pagesEnd');
  @override
  late final GeneratedColumn<int> pagesEnd = GeneratedColumn<int>(
      'pages_end', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, nameAr, nameEn, revelationType, ayahCount, pagesStart, pagesEnd];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surahs';
  @override
  VerificationContext validateIntegrity(Insertable<Surah> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name_ar')) {
      context.handle(_nameArMeta,
          nameAr.isAcceptableOrUnknown(data['name_ar']!, _nameArMeta));
    } else if (isInserting) {
      context.missing(_nameArMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(_nameEnMeta,
          nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta));
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('revelation_type')) {
      context.handle(
          _revelationTypeMeta,
          revelationType.isAcceptableOrUnknown(
              data['revelation_type']!, _revelationTypeMeta));
    } else if (isInserting) {
      context.missing(_revelationTypeMeta);
    }
    if (data.containsKey('ayah_count')) {
      context.handle(_ayahCountMeta,
          ayahCount.isAcceptableOrUnknown(data['ayah_count']!, _ayahCountMeta));
    } else if (isInserting) {
      context.missing(_ayahCountMeta);
    }
    if (data.containsKey('pages_start')) {
      context.handle(
          _pagesStartMeta,
          pagesStart.isAcceptableOrUnknown(
              data['pages_start']!, _pagesStartMeta));
    } else if (isInserting) {
      context.missing(_pagesStartMeta);
    }
    if (data.containsKey('pages_end')) {
      context.handle(_pagesEndMeta,
          pagesEnd.isAcceptableOrUnknown(data['pages_end']!, _pagesEndMeta));
    } else if (isInserting) {
      context.missing(_pagesEndMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Surah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Surah(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nameAr: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_ar'])!,
      nameEn: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_en'])!,
      revelationType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}revelation_type'])!,
      ayahCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ayah_count'])!,
      pagesStart: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pages_start'])!,
      pagesEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pages_end'])!,
    );
  }

  @override
  $SurahsTable createAlias(String alias) {
    return $SurahsTable(attachedDatabase, alias);
  }
}

class Surah extends DataClass implements Insertable<Surah> {
  final int id;
  final String nameAr;
  final String nameEn;

  /// Revelation type as stored in the catalog: 'makki' or 'madani'.
  final String revelationType;
  final int ayahCount;

  /// First mushaf page of the surah (inclusive).
  final int pagesStart;

  /// Last mushaf page of the surah (inclusive).
  final int pagesEnd;
  const Surah(
      {required this.id,
      required this.nameAr,
      required this.nameEn,
      required this.revelationType,
      required this.ayahCount,
      required this.pagesStart,
      required this.pagesEnd});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_en'] = Variable<String>(nameEn);
    map['revelation_type'] = Variable<String>(revelationType);
    map['ayah_count'] = Variable<int>(ayahCount);
    map['pages_start'] = Variable<int>(pagesStart);
    map['pages_end'] = Variable<int>(pagesEnd);
    return map;
  }

  SurahsCompanion toCompanion(bool nullToAbsent) {
    return SurahsCompanion(
      id: Value(id),
      nameAr: Value(nameAr),
      nameEn: Value(nameEn),
      revelationType: Value(revelationType),
      ayahCount: Value(ayahCount),
      pagesStart: Value(pagesStart),
      pagesEnd: Value(pagesEnd),
    );
  }

  factory Surah.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Surah(
      id: serializer.fromJson<int>(json['id']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      revelationType: serializer.fromJson<String>(json['revelationType']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      pagesStart: serializer.fromJson<int>(json['pagesStart']),
      pagesEnd: serializer.fromJson<int>(json['pagesEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameEn': serializer.toJson<String>(nameEn),
      'revelationType': serializer.toJson<String>(revelationType),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'pagesStart': serializer.toJson<int>(pagesStart),
      'pagesEnd': serializer.toJson<int>(pagesEnd),
    };
  }

  Surah copyWith(
          {int? id,
          String? nameAr,
          String? nameEn,
          String? revelationType,
          int? ayahCount,
          int? pagesStart,
          int? pagesEnd}) =>
      Surah(
        id: id ?? this.id,
        nameAr: nameAr ?? this.nameAr,
        nameEn: nameEn ?? this.nameEn,
        revelationType: revelationType ?? this.revelationType,
        ayahCount: ayahCount ?? this.ayahCount,
        pagesStart: pagesStart ?? this.pagesStart,
        pagesEnd: pagesEnd ?? this.pagesEnd,
      );
  Surah copyWithCompanion(SurahsCompanion data) {
    return Surah(
      id: data.id.present ? data.id.value : this.id,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      revelationType: data.revelationType.present
          ? data.revelationType.value
          : this.revelationType,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      pagesStart:
          data.pagesStart.present ? data.pagesStart.value : this.pagesStart,
      pagesEnd: data.pagesEnd.present ? data.pagesEnd.value : this.pagesEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Surah(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('revelationType: $revelationType, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('pagesStart: $pagesStart, ')
          ..write('pagesEnd: $pagesEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, nameAr, nameEn, revelationType, ayahCount, pagesStart, pagesEnd);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Surah &&
          other.id == this.id &&
          other.nameAr == this.nameAr &&
          other.nameEn == this.nameEn &&
          other.revelationType == this.revelationType &&
          other.ayahCount == this.ayahCount &&
          other.pagesStart == this.pagesStart &&
          other.pagesEnd == this.pagesEnd);
}

class SurahsCompanion extends UpdateCompanion<Surah> {
  final Value<int> id;
  final Value<String> nameAr;
  final Value<String> nameEn;
  final Value<String> revelationType;
  final Value<int> ayahCount;
  final Value<int> pagesStart;
  final Value<int> pagesEnd;
  const SurahsCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.revelationType = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.pagesStart = const Value.absent(),
    this.pagesEnd = const Value.absent(),
  });
  SurahsCompanion.insert({
    this.id = const Value.absent(),
    required String nameAr,
    required String nameEn,
    required String revelationType,
    required int ayahCount,
    required int pagesStart,
    required int pagesEnd,
  })  : nameAr = Value(nameAr),
        nameEn = Value(nameEn),
        revelationType = Value(revelationType),
        ayahCount = Value(ayahCount),
        pagesStart = Value(pagesStart),
        pagesEnd = Value(pagesEnd);
  static Insertable<Surah> custom({
    Expression<int>? id,
    Expression<String>? nameAr,
    Expression<String>? nameEn,
    Expression<String>? revelationType,
    Expression<int>? ayahCount,
    Expression<int>? pagesStart,
    Expression<int>? pagesEnd,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameEn != null) 'name_en': nameEn,
      if (revelationType != null) 'revelation_type': revelationType,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (pagesStart != null) 'pages_start': pagesStart,
      if (pagesEnd != null) 'pages_end': pagesEnd,
    });
  }

  SurahsCompanion copyWith(
      {Value<int>? id,
      Value<String>? nameAr,
      Value<String>? nameEn,
      Value<String>? revelationType,
      Value<int>? ayahCount,
      Value<int>? pagesStart,
      Value<int>? pagesEnd}) {
    return SurahsCompanion(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      revelationType: revelationType ?? this.revelationType,
      ayahCount: ayahCount ?? this.ayahCount,
      pagesStart: pagesStart ?? this.pagesStart,
      pagesEnd: pagesEnd ?? this.pagesEnd,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (revelationType.present) {
      map['revelation_type'] = Variable<String>(revelationType.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (pagesStart.present) {
      map['pages_start'] = Variable<int>(pagesStart.value);
    }
    if (pagesEnd.present) {
      map['pages_end'] = Variable<int>(pagesEnd.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahsCompanion(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameEn: $nameEn, ')
          ..write('revelationType: $revelationType, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('pagesStart: $pagesStart, ')
          ..write('pagesEnd: $pagesEnd')
          ..write(')'))
        .toString();
  }
}

class $AyahsTable extends Ayahs with TableInfo<$AyahsTable, Ayah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _surahIdMeta =
      const VerificationMeta('surahId');
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
      'surah_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _numberInSurahMeta =
      const VerificationMeta('numberInSurah');
  @override
  late final GeneratedColumn<int> numberInSurah = GeneratedColumn<int>(
      'number_in_surah', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _juzMeta = const VerificationMeta('juz');
  @override
  late final GeneratedColumn<int> juz = GeneratedColumn<int>(
      'juz', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
      'page', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lineStartMeta =
      const VerificationMeta('lineStart');
  @override
  late final GeneratedColumn<int> lineStart = GeneratedColumn<int>(
      'line_start', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lineEndMeta =
      const VerificationMeta('lineEnd');
  @override
  late final GeneratedColumn<int> lineEnd = GeneratedColumn<int>(
      'line_end', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _textUthmaniMeta =
      const VerificationMeta('textUthmani');
  @override
  late final GeneratedColumn<String> textUthmani = GeneratedColumn<String>(
      'text_uthmani', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _textImlaeiMeta =
      const VerificationMeta('textImlaei');
  @override
  late final GeneratedColumn<String> textImlaei = GeneratedColumn<String>(
      'text_imlaei', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sajdaMeta = const VerificationMeta('sajda');
  @override
  late final GeneratedColumn<bool> sajda = GeneratedColumn<bool>(
      'sajda', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("sajda" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        surahId,
        numberInSurah,
        juz,
        page,
        lineStart,
        lineEnd,
        textUthmani,
        textImlaei,
        sajda
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayahs';
  @override
  VerificationContext validateIntegrity(Insertable<Ayah> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('surah_id')) {
      context.handle(_surahIdMeta,
          surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta));
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('number_in_surah')) {
      context.handle(
          _numberInSurahMeta,
          numberInSurah.isAcceptableOrUnknown(
              data['number_in_surah']!, _numberInSurahMeta));
    } else if (isInserting) {
      context.missing(_numberInSurahMeta);
    }
    if (data.containsKey('juz')) {
      context.handle(
          _juzMeta, juz.isAcceptableOrUnknown(data['juz']!, _juzMeta));
    } else if (isInserting) {
      context.missing(_juzMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
          _pageMeta, page.isAcceptableOrUnknown(data['page']!, _pageMeta));
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('line_start')) {
      context.handle(_lineStartMeta,
          lineStart.isAcceptableOrUnknown(data['line_start']!, _lineStartMeta));
    }
    if (data.containsKey('line_end')) {
      context.handle(_lineEndMeta,
          lineEnd.isAcceptableOrUnknown(data['line_end']!, _lineEndMeta));
    }
    if (data.containsKey('text_uthmani')) {
      context.handle(
          _textUthmaniMeta,
          textUthmani.isAcceptableOrUnknown(
              data['text_uthmani']!, _textUthmaniMeta));
    } else if (isInserting) {
      context.missing(_textUthmaniMeta);
    }
    if (data.containsKey('text_imlaei')) {
      context.handle(
          _textImlaeiMeta,
          textImlaei.isAcceptableOrUnknown(
              data['text_imlaei']!, _textImlaeiMeta));
    } else if (isInserting) {
      context.missing(_textImlaeiMeta);
    }
    if (data.containsKey('sajda')) {
      context.handle(
          _sajdaMeta, sajda.isAcceptableOrUnknown(data['sajda']!, _sajdaMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ayah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ayah(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      surahId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_id'])!,
      numberInSurah: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number_in_surah'])!,
      juz: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}juz'])!,
      page: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page'])!,
      lineStart: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}line_start']),
      lineEnd: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}line_end']),
      textUthmani: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_uthmani'])!,
      textImlaei: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text_imlaei'])!,
      sajda: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}sajda'])!,
    );
  }

  @override
  $AyahsTable createAlias(String alias) {
    return $AyahsTable(attachedDatabase, alias);
  }
}

class Ayah extends DataClass implements Insertable<Ayah> {
  /// Global ayah number, 1..6236 across the whole Quran.
  final int id;
  final int surahId;

  /// Ayah number within its own surah, 1-based.
  final int numberInSurah;

  /// Juz' (30-part division) the ayah belongs to, 1-based.
  final int juz;

  /// Mushaf page the ayah starts on, 1-based.
  final int page;

  /// First line of the ayah on its page; null when the page has no line map.
  final int? lineStart;

  /// Last line of the ayah on its page; null when the page has no line map.
  final int? lineEnd;
  final String textUthmani;
  final String textImlaei;

  /// True when the ayah ends with a sajda (prostration) marker.
  final bool sajda;
  const Ayah(
      {required this.id,
      required this.surahId,
      required this.numberInSurah,
      required this.juz,
      required this.page,
      this.lineStart,
      this.lineEnd,
      required this.textUthmani,
      required this.textImlaei,
      required this.sajda});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah_id'] = Variable<int>(surahId);
    map['number_in_surah'] = Variable<int>(numberInSurah);
    map['juz'] = Variable<int>(juz);
    map['page'] = Variable<int>(page);
    if (!nullToAbsent || lineStart != null) {
      map['line_start'] = Variable<int>(lineStart);
    }
    if (!nullToAbsent || lineEnd != null) {
      map['line_end'] = Variable<int>(lineEnd);
    }
    map['text_uthmani'] = Variable<String>(textUthmani);
    map['text_imlaei'] = Variable<String>(textImlaei);
    map['sajda'] = Variable<bool>(sajda);
    return map;
  }

  AyahsCompanion toCompanion(bool nullToAbsent) {
    return AyahsCompanion(
      id: Value(id),
      surahId: Value(surahId),
      numberInSurah: Value(numberInSurah),
      juz: Value(juz),
      page: Value(page),
      lineStart: lineStart == null && nullToAbsent
          ? const Value.absent()
          : Value(lineStart),
      lineEnd: lineEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(lineEnd),
      textUthmani: Value(textUthmani),
      textImlaei: Value(textImlaei),
      sajda: Value(sajda),
    );
  }

  factory Ayah.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ayah(
      id: serializer.fromJson<int>(json['id']),
      surahId: serializer.fromJson<int>(json['surahId']),
      numberInSurah: serializer.fromJson<int>(json['numberInSurah']),
      juz: serializer.fromJson<int>(json['juz']),
      page: serializer.fromJson<int>(json['page']),
      lineStart: serializer.fromJson<int?>(json['lineStart']),
      lineEnd: serializer.fromJson<int?>(json['lineEnd']),
      textUthmani: serializer.fromJson<String>(json['textUthmani']),
      textImlaei: serializer.fromJson<String>(json['textImlaei']),
      sajda: serializer.fromJson<bool>(json['sajda']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surahId': serializer.toJson<int>(surahId),
      'numberInSurah': serializer.toJson<int>(numberInSurah),
      'juz': serializer.toJson<int>(juz),
      'page': serializer.toJson<int>(page),
      'lineStart': serializer.toJson<int?>(lineStart),
      'lineEnd': serializer.toJson<int?>(lineEnd),
      'textUthmani': serializer.toJson<String>(textUthmani),
      'textImlaei': serializer.toJson<String>(textImlaei),
      'sajda': serializer.toJson<bool>(sajda),
    };
  }

  Ayah copyWith(
          {int? id,
          int? surahId,
          int? numberInSurah,
          int? juz,
          int? page,
          Value<int?> lineStart = const Value.absent(),
          Value<int?> lineEnd = const Value.absent(),
          String? textUthmani,
          String? textImlaei,
          bool? sajda}) =>
      Ayah(
        id: id ?? this.id,
        surahId: surahId ?? this.surahId,
        numberInSurah: numberInSurah ?? this.numberInSurah,
        juz: juz ?? this.juz,
        page: page ?? this.page,
        lineStart: lineStart.present ? lineStart.value : this.lineStart,
        lineEnd: lineEnd.present ? lineEnd.value : this.lineEnd,
        textUthmani: textUthmani ?? this.textUthmani,
        textImlaei: textImlaei ?? this.textImlaei,
        sajda: sajda ?? this.sajda,
      );
  Ayah copyWithCompanion(AyahsCompanion data) {
    return Ayah(
      id: data.id.present ? data.id.value : this.id,
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      numberInSurah: data.numberInSurah.present
          ? data.numberInSurah.value
          : this.numberInSurah,
      juz: data.juz.present ? data.juz.value : this.juz,
      page: data.page.present ? data.page.value : this.page,
      lineStart: data.lineStart.present ? data.lineStart.value : this.lineStart,
      lineEnd: data.lineEnd.present ? data.lineEnd.value : this.lineEnd,
      textUthmani:
          data.textUthmani.present ? data.textUthmani.value : this.textUthmani,
      textImlaei:
          data.textImlaei.present ? data.textImlaei.value : this.textImlaei,
      sajda: data.sajda.present ? data.sajda.value : this.sajda,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ayah(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('numberInSurah: $numberInSurah, ')
          ..write('juz: $juz, ')
          ..write('page: $page, ')
          ..write('lineStart: $lineStart, ')
          ..write('lineEnd: $lineEnd, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textImlaei: $textImlaei, ')
          ..write('sajda: $sajda')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surahId, numberInSurah, juz, page,
      lineStart, lineEnd, textUthmani, textImlaei, sajda);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ayah &&
          other.id == this.id &&
          other.surahId == this.surahId &&
          other.numberInSurah == this.numberInSurah &&
          other.juz == this.juz &&
          other.page == this.page &&
          other.lineStart == this.lineStart &&
          other.lineEnd == this.lineEnd &&
          other.textUthmani == this.textUthmani &&
          other.textImlaei == this.textImlaei &&
          other.sajda == this.sajda);
}

class AyahsCompanion extends UpdateCompanion<Ayah> {
  final Value<int> id;
  final Value<int> surahId;
  final Value<int> numberInSurah;
  final Value<int> juz;
  final Value<int> page;
  final Value<int?> lineStart;
  final Value<int?> lineEnd;
  final Value<String> textUthmani;
  final Value<String> textImlaei;
  final Value<bool> sajda;
  const AyahsCompanion({
    this.id = const Value.absent(),
    this.surahId = const Value.absent(),
    this.numberInSurah = const Value.absent(),
    this.juz = const Value.absent(),
    this.page = const Value.absent(),
    this.lineStart = const Value.absent(),
    this.lineEnd = const Value.absent(),
    this.textUthmani = const Value.absent(),
    this.textImlaei = const Value.absent(),
    this.sajda = const Value.absent(),
  });
  AyahsCompanion.insert({
    this.id = const Value.absent(),
    required int surahId,
    required int numberInSurah,
    required int juz,
    required int page,
    this.lineStart = const Value.absent(),
    this.lineEnd = const Value.absent(),
    required String textUthmani,
    required String textImlaei,
    this.sajda = const Value.absent(),
  })  : surahId = Value(surahId),
        numberInSurah = Value(numberInSurah),
        juz = Value(juz),
        page = Value(page),
        textUthmani = Value(textUthmani),
        textImlaei = Value(textImlaei);
  static Insertable<Ayah> custom({
    Expression<int>? id,
    Expression<int>? surahId,
    Expression<int>? numberInSurah,
    Expression<int>? juz,
    Expression<int>? page,
    Expression<int>? lineStart,
    Expression<int>? lineEnd,
    Expression<String>? textUthmani,
    Expression<String>? textImlaei,
    Expression<bool>? sajda,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surahId != null) 'surah_id': surahId,
      if (numberInSurah != null) 'number_in_surah': numberInSurah,
      if (juz != null) 'juz': juz,
      if (page != null) 'page': page,
      if (lineStart != null) 'line_start': lineStart,
      if (lineEnd != null) 'line_end': lineEnd,
      if (textUthmani != null) 'text_uthmani': textUthmani,
      if (textImlaei != null) 'text_imlaei': textImlaei,
      if (sajda != null) 'sajda': sajda,
    });
  }

  AyahsCompanion copyWith(
      {Value<int>? id,
      Value<int>? surahId,
      Value<int>? numberInSurah,
      Value<int>? juz,
      Value<int>? page,
      Value<int?>? lineStart,
      Value<int?>? lineEnd,
      Value<String>? textUthmani,
      Value<String>? textImlaei,
      Value<bool>? sajda}) {
    return AyahsCompanion(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      numberInSurah: numberInSurah ?? this.numberInSurah,
      juz: juz ?? this.juz,
      page: page ?? this.page,
      lineStart: lineStart ?? this.lineStart,
      lineEnd: lineEnd ?? this.lineEnd,
      textUthmani: textUthmani ?? this.textUthmani,
      textImlaei: textImlaei ?? this.textImlaei,
      sajda: sajda ?? this.sajda,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (numberInSurah.present) {
      map['number_in_surah'] = Variable<int>(numberInSurah.value);
    }
    if (juz.present) {
      map['juz'] = Variable<int>(juz.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (lineStart.present) {
      map['line_start'] = Variable<int>(lineStart.value);
    }
    if (lineEnd.present) {
      map['line_end'] = Variable<int>(lineEnd.value);
    }
    if (textUthmani.present) {
      map['text_uthmani'] = Variable<String>(textUthmani.value);
    }
    if (textImlaei.present) {
      map['text_imlaei'] = Variable<String>(textImlaei.value);
    }
    if (sajda.present) {
      map['sajda'] = Variable<bool>(sajda.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahsCompanion(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('numberInSurah: $numberInSurah, ')
          ..write('juz: $juz, ')
          ..write('page: $page, ')
          ..write('lineStart: $lineStart, ')
          ..write('lineEnd: $lineEnd, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textImlaei: $textImlaei, ')
          ..write('sajda: $sajda')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
      'ayah_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, ayahId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<Bookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ayah_id')) {
      context.handle(_ayahIdMeta,
          ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta));
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ayahId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ayah_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final int id;

  /// Global ayah number that was bookmarked.
  final int ayahId;

  /// When the bookmark was created (defaults to write time).
  final DateTime createdAt;
  const Bookmark(
      {required this.id, required this.ayahId, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bookmark copyWith({int? id, int? ayahId, DateTime? createdAt}) => Bookmark(
        id: id ?? this.id,
        ayahId: ayahId ?? this.ayahId,
        createdAt: createdAt ?? this.createdAt,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ayahId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<DateTime> createdAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    this.createdAt = const Value.absent(),
  }) : ayahId = Value(ayahId);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BookmarksCompanion copyWith(
      {Value<int>? id, Value<int>? ayahId, Value<DateTime>? createdAt}) {
    return BookmarksCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KhatmaProgressTable extends KhatmaProgress
    with TableInfo<$KhatmaProgressTable, KhatmaProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KhatmaProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _ayahIdMeta = const VerificationMeta('ayahId');
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
      'ayah_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetPagesMeta =
      const VerificationMeta('targetPages');
  @override
  late final GeneratedColumn<int> targetPages = GeneratedColumn<int>(
      'target_pages', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, ayahId, targetPages, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'khatma_progress';
  @override
  VerificationContext validateIntegrity(Insertable<KhatmaProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ayah_id')) {
      context.handle(_ayahIdMeta,
          ayahId.isAcceptableOrUnknown(data['ayah_id']!, _ayahIdMeta));
    } else if (isInserting) {
      context.missing(_ayahIdMeta);
    }
    if (data.containsKey('target_pages')) {
      context.handle(
          _targetPagesMeta,
          targetPages.isAcceptableOrUnknown(
              data['target_pages']!, _targetPagesMeta));
    } else if (isInserting) {
      context.missing(_targetPagesMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KhatmaProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KhatmaProgressData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      ayahId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ayah_id'])!,
      targetPages: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_pages'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $KhatmaProgressTable createAlias(String alias) {
    return $KhatmaProgressTable(attachedDatabase, alias);
  }
}

class KhatmaProgressData extends DataClass
    implements Insertable<KhatmaProgressData> {
  final int id;

  /// Global ayah number the plan is anchored at.
  final int ayahId;

  /// Page count the user aimed to finish.
  final int targetPages;

  /// When the plan last moved (defaults to write time).
  final DateTime updatedAt;
  const KhatmaProgressData(
      {required this.id,
      required this.ayahId,
      required this.targetPages,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['target_pages'] = Variable<int>(targetPages);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  KhatmaProgressCompanion toCompanion(bool nullToAbsent) {
    return KhatmaProgressCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      targetPages: Value(targetPages),
      updatedAt: Value(updatedAt),
    );
  }

  factory KhatmaProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KhatmaProgressData(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      targetPages: serializer.fromJson<int>(json['targetPages']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'targetPages': serializer.toJson<int>(targetPages),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  KhatmaProgressData copyWith(
          {int? id, int? ayahId, int? targetPages, DateTime? updatedAt}) =>
      KhatmaProgressData(
        id: id ?? this.id,
        ayahId: ayahId ?? this.ayahId,
        targetPages: targetPages ?? this.targetPages,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  KhatmaProgressData copyWithCompanion(KhatmaProgressCompanion data) {
    return KhatmaProgressData(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      targetPages:
          data.targetPages.present ? data.targetPages.value : this.targetPages,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaProgressData(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('targetPages: $targetPages, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ayahId, targetPages, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KhatmaProgressData &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.targetPages == this.targetPages &&
          other.updatedAt == this.updatedAt);
}

class KhatmaProgressCompanion extends UpdateCompanion<KhatmaProgressData> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<int> targetPages;
  final Value<DateTime> updatedAt;
  const KhatmaProgressCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.targetPages = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  KhatmaProgressCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required int targetPages,
    this.updatedAt = const Value.absent(),
  })  : ayahId = Value(ayahId),
        targetPages = Value(targetPages);
  static Insertable<KhatmaProgressData> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<int>? targetPages,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (targetPages != null) 'target_pages': targetPages,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  KhatmaProgressCompanion copyWith(
      {Value<int>? id,
      Value<int>? ayahId,
      Value<int>? targetPages,
      Value<DateTime>? updatedAt}) {
    return KhatmaProgressCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      targetPages: targetPages ?? this.targetPages,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (targetPages.present) {
      map['target_pages'] = Variable<int>(targetPages.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KhatmaProgressCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('targetPages: $targetPages, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PrayerLogTable extends PrayerLog
    with TableInfo<$PrayerLogTable, PrayerLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
      'day', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _fajrMeta = const VerificationMeta('fajr');
  @override
  late final GeneratedColumn<bool> fajr = GeneratedColumn<bool>(
      'fajr', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("fajr" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dhuhrMeta = const VerificationMeta('dhuhr');
  @override
  late final GeneratedColumn<bool> dhuhr = GeneratedColumn<bool>(
      'dhuhr', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dhuhr" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _asrMeta = const VerificationMeta('asr');
  @override
  late final GeneratedColumn<bool> asr = GeneratedColumn<bool>(
      'asr', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("asr" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _maghribMeta =
      const VerificationMeta('maghrib');
  @override
  late final GeneratedColumn<bool> maghrib = GeneratedColumn<bool>(
      'maghrib', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("maghrib" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _ishaMeta = const VerificationMeta('isha');
  @override
  late final GeneratedColumn<bool> isha = GeneratedColumn<bool>(
      'isha', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("isha" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [day, fajr, dhuhr, asr, maghrib, isha];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_log';
  @override
  VerificationContext validateIntegrity(Insertable<PrayerLogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('fajr')) {
      context.handle(
          _fajrMeta, fajr.isAcceptableOrUnknown(data['fajr']!, _fajrMeta));
    }
    if (data.containsKey('dhuhr')) {
      context.handle(
          _dhuhrMeta, dhuhr.isAcceptableOrUnknown(data['dhuhr']!, _dhuhrMeta));
    }
    if (data.containsKey('asr')) {
      context.handle(
          _asrMeta, asr.isAcceptableOrUnknown(data['asr']!, _asrMeta));
    }
    if (data.containsKey('maghrib')) {
      context.handle(_maghribMeta,
          maghrib.isAcceptableOrUnknown(data['maghrib']!, _maghribMeta));
    }
    if (data.containsKey('isha')) {
      context.handle(
          _ishaMeta, isha.isAcceptableOrUnknown(data['isha']!, _ishaMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  PrayerLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerLogData(
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}day'])!,
      fajr: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}fajr'])!,
      dhuhr: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dhuhr'])!,
      asr: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}asr'])!,
      maghrib: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}maghrib'])!,
      isha: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}isha'])!,
    );
  }

  @override
  $PrayerLogTable createAlias(String alias) {
    return $PrayerLogTable(attachedDatabase, alias);
  }
}

class PrayerLogData extends DataClass implements Insertable<PrayerLogData> {
  /// The calendar day this row describes.
  final DateTime day;

  /// Fajr marked on [day].
  final bool fajr;

  /// Dhuhr marked on [day].
  final bool dhuhr;

  /// Asr marked on [day].
  final bool asr;

  /// Maghrib marked on [day].
  final bool maghrib;

  /// Isha marked on [day].
  final bool isha;
  const PrayerLogData(
      {required this.day,
      required this.fajr,
      required this.dhuhr,
      required this.asr,
      required this.maghrib,
      required this.isha});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    map['fajr'] = Variable<bool>(fajr);
    map['dhuhr'] = Variable<bool>(dhuhr);
    map['asr'] = Variable<bool>(asr);
    map['maghrib'] = Variable<bool>(maghrib);
    map['isha'] = Variable<bool>(isha);
    return map;
  }

  PrayerLogCompanion toCompanion(bool nullToAbsent) {
    return PrayerLogCompanion(
      day: Value(day),
      fajr: Value(fajr),
      dhuhr: Value(dhuhr),
      asr: Value(asr),
      maghrib: Value(maghrib),
      isha: Value(isha),
    );
  }

  factory PrayerLogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerLogData(
      day: serializer.fromJson<DateTime>(json['day']),
      fajr: serializer.fromJson<bool>(json['fajr']),
      dhuhr: serializer.fromJson<bool>(json['dhuhr']),
      asr: serializer.fromJson<bool>(json['asr']),
      maghrib: serializer.fromJson<bool>(json['maghrib']),
      isha: serializer.fromJson<bool>(json['isha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<DateTime>(day),
      'fajr': serializer.toJson<bool>(fajr),
      'dhuhr': serializer.toJson<bool>(dhuhr),
      'asr': serializer.toJson<bool>(asr),
      'maghrib': serializer.toJson<bool>(maghrib),
      'isha': serializer.toJson<bool>(isha),
    };
  }

  PrayerLogData copyWith(
          {DateTime? day,
          bool? fajr,
          bool? dhuhr,
          bool? asr,
          bool? maghrib,
          bool? isha}) =>
      PrayerLogData(
        day: day ?? this.day,
        fajr: fajr ?? this.fajr,
        dhuhr: dhuhr ?? this.dhuhr,
        asr: asr ?? this.asr,
        maghrib: maghrib ?? this.maghrib,
        isha: isha ?? this.isha,
      );
  PrayerLogData copyWithCompanion(PrayerLogCompanion data) {
    return PrayerLogData(
      day: data.day.present ? data.day.value : this.day,
      fajr: data.fajr.present ? data.fajr.value : this.fajr,
      dhuhr: data.dhuhr.present ? data.dhuhr.value : this.dhuhr,
      asr: data.asr.present ? data.asr.value : this.asr,
      maghrib: data.maghrib.present ? data.maghrib.value : this.maghrib,
      isha: data.isha.present ? data.isha.value : this.isha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerLogData(')
          ..write('day: $day, ')
          ..write('fajr: $fajr, ')
          ..write('dhuhr: $dhuhr, ')
          ..write('asr: $asr, ')
          ..write('maghrib: $maghrib, ')
          ..write('isha: $isha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, fajr, dhuhr, asr, maghrib, isha);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerLogData &&
          other.day == this.day &&
          other.fajr == this.fajr &&
          other.dhuhr == this.dhuhr &&
          other.asr == this.asr &&
          other.maghrib == this.maghrib &&
          other.isha == this.isha);
}

class PrayerLogCompanion extends UpdateCompanion<PrayerLogData> {
  final Value<DateTime> day;
  final Value<bool> fajr;
  final Value<bool> dhuhr;
  final Value<bool> asr;
  final Value<bool> maghrib;
  final Value<bool> isha;
  final Value<int> rowid;
  const PrayerLogCompanion({
    this.day = const Value.absent(),
    this.fajr = const Value.absent(),
    this.dhuhr = const Value.absent(),
    this.asr = const Value.absent(),
    this.maghrib = const Value.absent(),
    this.isha = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrayerLogCompanion.insert({
    required DateTime day,
    this.fajr = const Value.absent(),
    this.dhuhr = const Value.absent(),
    this.asr = const Value.absent(),
    this.maghrib = const Value.absent(),
    this.isha = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day);
  static Insertable<PrayerLogData> custom({
    Expression<DateTime>? day,
    Expression<bool>? fajr,
    Expression<bool>? dhuhr,
    Expression<bool>? asr,
    Expression<bool>? maghrib,
    Expression<bool>? isha,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (fajr != null) 'fajr': fajr,
      if (dhuhr != null) 'dhuhr': dhuhr,
      if (asr != null) 'asr': asr,
      if (maghrib != null) 'maghrib': maghrib,
      if (isha != null) 'isha': isha,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrayerLogCompanion copyWith(
      {Value<DateTime>? day,
      Value<bool>? fajr,
      Value<bool>? dhuhr,
      Value<bool>? asr,
      Value<bool>? maghrib,
      Value<bool>? isha,
      Value<int>? rowid}) {
    return PrayerLogCompanion(
      day: day ?? this.day,
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (fajr.present) {
      map['fajr'] = Variable<bool>(fajr.value);
    }
    if (dhuhr.present) {
      map['dhuhr'] = Variable<bool>(dhuhr.value);
    }
    if (asr.present) {
      map['asr'] = Variable<bool>(asr.value);
    }
    if (maghrib.present) {
      map['maghrib'] = Variable<bool>(maghrib.value);
    }
    if (isha.present) {
      map['isha'] = Variable<bool>(isha.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerLogCompanion(')
          ..write('day: $day, ')
          ..write('fajr: $fajr, ')
          ..write('dhuhr: $dhuhr, ')
          ..write('asr: $asr, ')
          ..write('maghrib: $maghrib, ')
          ..write('isha: $isha, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstalledPacksTable extends InstalledPacks
    with TableInfo<$InstalledPacksTable, InstalledPack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstalledPacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<String> packId = GeneratedColumn<String>(
      'pack_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeMbMeta = const VerificationMeta('sizeMb');
  @override
  late final GeneratedColumn<double> sizeMb = GeneratedColumn<double>(
      'size_mb', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
      'version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _installedAtMeta =
      const VerificationMeta('installedAt');
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
      'installed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [packId, kind, language, title, sizeMb, version, installedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installed_packs';
  @override
  VerificationContext validateIntegrity(Insertable<InstalledPack> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_id')) {
      context.handle(_packIdMeta,
          packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta));
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('size_mb')) {
      context.handle(_sizeMbMeta,
          sizeMb.isAcceptableOrUnknown(data['size_mb']!, _sizeMbMeta));
    } else if (isInserting) {
      context.missing(_sizeMbMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
          _installedAtMeta,
          installedAt.isAcceptableOrUnknown(
              data['installed_at']!, _installedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packId};
  @override
  InstalledPack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstalledPack(
      packId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pack_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      sizeMb: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}size_mb'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version'])!,
      installedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}installed_at'])!,
    );
  }

  @override
  $InstalledPacksTable createAlias(String alias) {
    return $InstalledPacksTable(attachedDatabase, alias);
  }
}

class InstalledPack extends DataClass implements Insertable<InstalledPack> {
  /// Catalog id of the installed pack.
  final String packId;

  /// Pack kind as stored: 'tafsir', 'translation' or 'hadith'.
  final String kind;
  final String language;

  /// Display title of the installed pack.
  final String title;

  /// Installed size in megabytes.
  final double sizeMb;

  /// Catalog version of the installed pack.
  final String version;

  /// When the pack finished installing (defaults to write time).
  final DateTime installedAt;
  const InstalledPack(
      {required this.packId,
      required this.kind,
      required this.language,
      required this.title,
      required this.sizeMb,
      required this.version,
      required this.installedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_id'] = Variable<String>(packId);
    map['kind'] = Variable<String>(kind);
    map['language'] = Variable<String>(language);
    map['title'] = Variable<String>(title);
    map['size_mb'] = Variable<double>(sizeMb);
    map['version'] = Variable<String>(version);
    map['installed_at'] = Variable<DateTime>(installedAt);
    return map;
  }

  InstalledPacksCompanion toCompanion(bool nullToAbsent) {
    return InstalledPacksCompanion(
      packId: Value(packId),
      kind: Value(kind),
      language: Value(language),
      title: Value(title),
      sizeMb: Value(sizeMb),
      version: Value(version),
      installedAt: Value(installedAt),
    );
  }

  factory InstalledPack.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstalledPack(
      packId: serializer.fromJson<String>(json['packId']),
      kind: serializer.fromJson<String>(json['kind']),
      language: serializer.fromJson<String>(json['language']),
      title: serializer.fromJson<String>(json['title']),
      sizeMb: serializer.fromJson<double>(json['sizeMb']),
      version: serializer.fromJson<String>(json['version']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packId': serializer.toJson<String>(packId),
      'kind': serializer.toJson<String>(kind),
      'language': serializer.toJson<String>(language),
      'title': serializer.toJson<String>(title),
      'sizeMb': serializer.toJson<double>(sizeMb),
      'version': serializer.toJson<String>(version),
      'installedAt': serializer.toJson<DateTime>(installedAt),
    };
  }

  InstalledPack copyWith(
          {String? packId,
          String? kind,
          String? language,
          String? title,
          double? sizeMb,
          String? version,
          DateTime? installedAt}) =>
      InstalledPack(
        packId: packId ?? this.packId,
        kind: kind ?? this.kind,
        language: language ?? this.language,
        title: title ?? this.title,
        sizeMb: sizeMb ?? this.sizeMb,
        version: version ?? this.version,
        installedAt: installedAt ?? this.installedAt,
      );
  InstalledPack copyWithCompanion(InstalledPacksCompanion data) {
    return InstalledPack(
      packId: data.packId.present ? data.packId.value : this.packId,
      kind: data.kind.present ? data.kind.value : this.kind,
      language: data.language.present ? data.language.value : this.language,
      title: data.title.present ? data.title.value : this.title,
      sizeMb: data.sizeMb.present ? data.sizeMb.value : this.sizeMb,
      version: data.version.present ? data.version.value : this.version,
      installedAt:
          data.installedAt.present ? data.installedAt.value : this.installedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstalledPack(')
          ..write('packId: $packId, ')
          ..write('kind: $kind, ')
          ..write('language: $language, ')
          ..write('title: $title, ')
          ..write('sizeMb: $sizeMb, ')
          ..write('version: $version, ')
          ..write('installedAt: $installedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(packId, kind, language, title, sizeMb, version, installedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstalledPack &&
          other.packId == this.packId &&
          other.kind == this.kind &&
          other.language == this.language &&
          other.title == this.title &&
          other.sizeMb == this.sizeMb &&
          other.version == this.version &&
          other.installedAt == this.installedAt);
}

class InstalledPacksCompanion extends UpdateCompanion<InstalledPack> {
  final Value<String> packId;
  final Value<String> kind;
  final Value<String> language;
  final Value<String> title;
  final Value<double> sizeMb;
  final Value<String> version;
  final Value<DateTime> installedAt;
  final Value<int> rowid;
  const InstalledPacksCompanion({
    this.packId = const Value.absent(),
    this.kind = const Value.absent(),
    this.language = const Value.absent(),
    this.title = const Value.absent(),
    this.sizeMb = const Value.absent(),
    this.version = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstalledPacksCompanion.insert({
    required String packId,
    required String kind,
    required String language,
    required String title,
    required double sizeMb,
    required String version,
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : packId = Value(packId),
        kind = Value(kind),
        language = Value(language),
        title = Value(title),
        sizeMb = Value(sizeMb),
        version = Value(version);
  static Insertable<InstalledPack> custom({
    Expression<String>? packId,
    Expression<String>? kind,
    Expression<String>? language,
    Expression<String>? title,
    Expression<double>? sizeMb,
    Expression<String>? version,
    Expression<DateTime>? installedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packId != null) 'pack_id': packId,
      if (kind != null) 'kind': kind,
      if (language != null) 'language': language,
      if (title != null) 'title': title,
      if (sizeMb != null) 'size_mb': sizeMb,
      if (version != null) 'version': version,
      if (installedAt != null) 'installed_at': installedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstalledPacksCompanion copyWith(
      {Value<String>? packId,
      Value<String>? kind,
      Value<String>? language,
      Value<String>? title,
      Value<double>? sizeMb,
      Value<String>? version,
      Value<DateTime>? installedAt,
      Value<int>? rowid}) {
    return InstalledPacksCompanion(
      packId: packId ?? this.packId,
      kind: kind ?? this.kind,
      language: language ?? this.language,
      title: title ?? this.title,
      sizeMb: sizeMb ?? this.sizeMb,
      version: version ?? this.version,
      installedAt: installedAt ?? this.installedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packId.present) {
      map['pack_id'] = Variable<String>(packId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sizeMb.present) {
      map['size_mb'] = Variable<double>(sizeMb.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstalledPacksCompanion(')
          ..write('packId: $packId, ')
          ..write('kind: $kind, ')
          ..write('language: $language, ')
          ..write('title: $title, ')
          ..write('sizeMb: $sizeMb, ')
          ..write('version: $version, ')
          ..write('installedAt: $installedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _reciterIdMeta =
      const VerificationMeta('reciterId');
  @override
  late final GeneratedColumn<String> reciterId = GeneratedColumn<String>(
      'reciter_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surahIdMeta =
      const VerificationMeta('surahId');
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
      'surah_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
      'bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, reciterId, surahId, status, bytes, path];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(Insertable<Download> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reciter_id')) {
      context.handle(_reciterIdMeta,
          reciterId.isAcceptableOrUnknown(data['reciter_id']!, _reciterIdMeta));
    } else if (isInserting) {
      context.missing(_reciterIdMeta);
    }
    if (data.containsKey('surah_id')) {
      context.handle(_surahIdMeta,
          surahId.isAcceptableOrUnknown(data['surah_id']!, _surahIdMeta));
    } else if (isInserting) {
      context.missing(_surahIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
          _bytesMeta, bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      reciterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reciter_id'])!,
      surahId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      bytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class Download extends DataClass implements Insertable<Download> {
  final int id;

  /// Reciter (moshaf) id owning the download.
  final String reciterId;

  /// Surah number being downloaded.
  final int surahId;

  /// Download state: 'queued', 'downloading', 'done' or 'failed'.
  final String status;

  /// Bytes received so far.
  final int bytes;

  /// Absolute path of the finished file; empty while downloading.
  final String path;
  const Download(
      {required this.id,
      required this.reciterId,
      required this.surahId,
      required this.status,
      required this.bytes,
      required this.path});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reciter_id'] = Variable<String>(reciterId);
    map['surah_id'] = Variable<int>(surahId);
    map['status'] = Variable<String>(status);
    map['bytes'] = Variable<int>(bytes);
    map['path'] = Variable<String>(path);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      id: Value(id),
      reciterId: Value(reciterId),
      surahId: Value(surahId),
      status: Value(status),
      bytes: Value(bytes),
      path: Value(path),
    );
  }

  factory Download.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      id: serializer.fromJson<int>(json['id']),
      reciterId: serializer.fromJson<String>(json['reciterId']),
      surahId: serializer.fromJson<int>(json['surahId']),
      status: serializer.fromJson<String>(json['status']),
      bytes: serializer.fromJson<int>(json['bytes']),
      path: serializer.fromJson<String>(json['path']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reciterId': serializer.toJson<String>(reciterId),
      'surahId': serializer.toJson<int>(surahId),
      'status': serializer.toJson<String>(status),
      'bytes': serializer.toJson<int>(bytes),
      'path': serializer.toJson<String>(path),
    };
  }

  Download copyWith(
          {int? id,
          String? reciterId,
          int? surahId,
          String? status,
          int? bytes,
          String? path}) =>
      Download(
        id: id ?? this.id,
        reciterId: reciterId ?? this.reciterId,
        surahId: surahId ?? this.surahId,
        status: status ?? this.status,
        bytes: bytes ?? this.bytes,
        path: path ?? this.path,
      );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      id: data.id.present ? data.id.value : this.id,
      reciterId: data.reciterId.present ? data.reciterId.value : this.reciterId,
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      status: data.status.present ? data.status.value : this.status,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      path: data.path.present ? data.path.value : this.path,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('surahId: $surahId, ')
          ..write('status: $status, ')
          ..write('bytes: $bytes, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reciterId, surahId, status, bytes, path);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.id == this.id &&
          other.reciterId == this.reciterId &&
          other.surahId == this.surahId &&
          other.status == this.status &&
          other.bytes == this.bytes &&
          other.path == this.path);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<int> id;
  final Value<String> reciterId;
  final Value<int> surahId;
  final Value<String> status;
  final Value<int> bytes;
  final Value<String> path;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.reciterId = const Value.absent(),
    this.surahId = const Value.absent(),
    this.status = const Value.absent(),
    this.bytes = const Value.absent(),
    this.path = const Value.absent(),
  });
  DownloadsCompanion.insert({
    this.id = const Value.absent(),
    required String reciterId,
    required int surahId,
    required String status,
    this.bytes = const Value.absent(),
    required String path,
  })  : reciterId = Value(reciterId),
        surahId = Value(surahId),
        status = Value(status),
        path = Value(path);
  static Insertable<Download> custom({
    Expression<int>? id,
    Expression<String>? reciterId,
    Expression<int>? surahId,
    Expression<String>? status,
    Expression<int>? bytes,
    Expression<String>? path,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reciterId != null) 'reciter_id': reciterId,
      if (surahId != null) 'surah_id': surahId,
      if (status != null) 'status': status,
      if (bytes != null) 'bytes': bytes,
      if (path != null) 'path': path,
    });
  }

  DownloadsCompanion copyWith(
      {Value<int>? id,
      Value<String>? reciterId,
      Value<int>? surahId,
      Value<String>? status,
      Value<int>? bytes,
      Value<String>? path}) {
    return DownloadsCompanion(
      id: id ?? this.id,
      reciterId: reciterId ?? this.reciterId,
      surahId: surahId ?? this.surahId,
      status: status ?? this.status,
      bytes: bytes ?? this.bytes,
      path: path ?? this.path,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reciterId.present) {
      map['reciter_id'] = Variable<String>(reciterId.value);
    }
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('surahId: $surahId, ')
          ..write('status: $status, ')
          ..write('bytes: $bytes, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_table';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsTableData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsTableData extends DataClass
    implements Insertable<SettingsTableData> {
  /// Setting key.
  final String key;

  /// Setting value, stored as text.
  final String value;
  const SettingsTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsTableData copyWith({String? key, String? value}) => SettingsTableData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingsTableData copyWithCompanion(SettingsTableCompanion data) {
    return SettingsTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingsTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecitersTable extends Reciters
    with TableInfo<$RecitersTable, ReciterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecitersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reciterNameMeta =
      const VerificationMeta('reciterName');
  @override
  late final GeneratedColumn<String> reciterName = GeneratedColumn<String>(
      'reciter_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moshafNameMeta =
      const VerificationMeta('moshafName');
  @override
  late final GeneratedColumn<String> moshafName = GeneratedColumn<String>(
      'moshaf_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<String> server = GeneratedColumn<String>(
      'server', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surahListMeta =
      const VerificationMeta('surahList');
  @override
  late final GeneratedColumn<String> surahList = GeneratedColumn<String>(
      'surah_list', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surahTotalMeta =
      const VerificationMeta('surahTotal');
  @override
  late final GeneratedColumn<int> surahTotal = GeneratedColumn<int>(
      'surah_total', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, reciterName, moshafName, server, surahList, surahTotal];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reciters';
  @override
  VerificationContext validateIntegrity(Insertable<ReciterRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reciter_name')) {
      context.handle(
          _reciterNameMeta,
          reciterName.isAcceptableOrUnknown(
              data['reciter_name']!, _reciterNameMeta));
    } else if (isInserting) {
      context.missing(_reciterNameMeta);
    }
    if (data.containsKey('moshaf_name')) {
      context.handle(
          _moshafNameMeta,
          moshafName.isAcceptableOrUnknown(
              data['moshaf_name']!, _moshafNameMeta));
    } else if (isInserting) {
      context.missing(_moshafNameMeta);
    }
    if (data.containsKey('server')) {
      context.handle(_serverMeta,
          server.isAcceptableOrUnknown(data['server']!, _serverMeta));
    } else if (isInserting) {
      context.missing(_serverMeta);
    }
    if (data.containsKey('surah_list')) {
      context.handle(_surahListMeta,
          surahList.isAcceptableOrUnknown(data['surah_list']!, _surahListMeta));
    } else if (isInserting) {
      context.missing(_surahListMeta);
    }
    if (data.containsKey('surah_total')) {
      context.handle(
          _surahTotalMeta,
          surahTotal.isAcceptableOrUnknown(
              data['surah_total']!, _surahTotalMeta));
    } else if (isInserting) {
      context.missing(_surahTotalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReciterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReciterRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      reciterName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reciter_name'])!,
      moshafName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}moshaf_name'])!,
      server: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server'])!,
      surahList: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}surah_list'])!,
      surahTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}surah_total'])!,
    );
  }

  @override
  $RecitersTable createAlias(String alias) {
    return $RecitersTable(attachedDatabase, alias);
  }
}

class ReciterRow extends DataClass implements Insertable<ReciterRow> {
  /// Row id in `<reciterId>-<moshafId>` form.
  final String id;
  final String reciterName;
  final String moshafName;
  final String server;

  /// Comma-separated surah numbers the moshaf offers, e.g. '1,2,3'.
  final String surahList;

  /// Number of surahs the moshaf offers.
  final int surahTotal;
  const ReciterRow(
      {required this.id,
      required this.reciterName,
      required this.moshafName,
      required this.server,
      required this.surahList,
      required this.surahTotal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reciter_name'] = Variable<String>(reciterName);
    map['moshaf_name'] = Variable<String>(moshafName);
    map['server'] = Variable<String>(server);
    map['surah_list'] = Variable<String>(surahList);
    map['surah_total'] = Variable<int>(surahTotal);
    return map;
  }

  RecitersCompanion toCompanion(bool nullToAbsent) {
    return RecitersCompanion(
      id: Value(id),
      reciterName: Value(reciterName),
      moshafName: Value(moshafName),
      server: Value(server),
      surahList: Value(surahList),
      surahTotal: Value(surahTotal),
    );
  }

  factory ReciterRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReciterRow(
      id: serializer.fromJson<String>(json['id']),
      reciterName: serializer.fromJson<String>(json['reciterName']),
      moshafName: serializer.fromJson<String>(json['moshafName']),
      server: serializer.fromJson<String>(json['server']),
      surahList: serializer.fromJson<String>(json['surahList']),
      surahTotal: serializer.fromJson<int>(json['surahTotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reciterName': serializer.toJson<String>(reciterName),
      'moshafName': serializer.toJson<String>(moshafName),
      'server': serializer.toJson<String>(server),
      'surahList': serializer.toJson<String>(surahList),
      'surahTotal': serializer.toJson<int>(surahTotal),
    };
  }

  ReciterRow copyWith(
          {String? id,
          String? reciterName,
          String? moshafName,
          String? server,
          String? surahList,
          int? surahTotal}) =>
      ReciterRow(
        id: id ?? this.id,
        reciterName: reciterName ?? this.reciterName,
        moshafName: moshafName ?? this.moshafName,
        server: server ?? this.server,
        surahList: surahList ?? this.surahList,
        surahTotal: surahTotal ?? this.surahTotal,
      );
  ReciterRow copyWithCompanion(RecitersCompanion data) {
    return ReciterRow(
      id: data.id.present ? data.id.value : this.id,
      reciterName:
          data.reciterName.present ? data.reciterName.value : this.reciterName,
      moshafName:
          data.moshafName.present ? data.moshafName.value : this.moshafName,
      server: data.server.present ? data.server.value : this.server,
      surahList: data.surahList.present ? data.surahList.value : this.surahList,
      surahTotal:
          data.surahTotal.present ? data.surahTotal.value : this.surahTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReciterRow(')
          ..write('id: $id, ')
          ..write('reciterName: $reciterName, ')
          ..write('moshafName: $moshafName, ')
          ..write('server: $server, ')
          ..write('surahList: $surahList, ')
          ..write('surahTotal: $surahTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, reciterName, moshafName, server, surahList, surahTotal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReciterRow &&
          other.id == this.id &&
          other.reciterName == this.reciterName &&
          other.moshafName == this.moshafName &&
          other.server == this.server &&
          other.surahList == this.surahList &&
          other.surahTotal == this.surahTotal);
}

class RecitersCompanion extends UpdateCompanion<ReciterRow> {
  final Value<String> id;
  final Value<String> reciterName;
  final Value<String> moshafName;
  final Value<String> server;
  final Value<String> surahList;
  final Value<int> surahTotal;
  final Value<int> rowid;
  const RecitersCompanion({
    this.id = const Value.absent(),
    this.reciterName = const Value.absent(),
    this.moshafName = const Value.absent(),
    this.server = const Value.absent(),
    this.surahList = const Value.absent(),
    this.surahTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecitersCompanion.insert({
    required String id,
    required String reciterName,
    required String moshafName,
    required String server,
    required String surahList,
    required int surahTotal,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        reciterName = Value(reciterName),
        moshafName = Value(moshafName),
        server = Value(server),
        surahList = Value(surahList),
        surahTotal = Value(surahTotal);
  static Insertable<ReciterRow> custom({
    Expression<String>? id,
    Expression<String>? reciterName,
    Expression<String>? moshafName,
    Expression<String>? server,
    Expression<String>? surahList,
    Expression<int>? surahTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reciterName != null) 'reciter_name': reciterName,
      if (moshafName != null) 'moshaf_name': moshafName,
      if (server != null) 'server': server,
      if (surahList != null) 'surah_list': surahList,
      if (surahTotal != null) 'surah_total': surahTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecitersCompanion copyWith(
      {Value<String>? id,
      Value<String>? reciterName,
      Value<String>? moshafName,
      Value<String>? server,
      Value<String>? surahList,
      Value<int>? surahTotal,
      Value<int>? rowid}) {
    return RecitersCompanion(
      id: id ?? this.id,
      reciterName: reciterName ?? this.reciterName,
      moshafName: moshafName ?? this.moshafName,
      server: server ?? this.server,
      surahList: surahList ?? this.surahList,
      surahTotal: surahTotal ?? this.surahTotal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reciterName.present) {
      map['reciter_name'] = Variable<String>(reciterName.value);
    }
    if (moshafName.present) {
      map['moshaf_name'] = Variable<String>(moshafName.value);
    }
    if (server.present) {
      map['server'] = Variable<String>(server.value);
    }
    if (surahList.present) {
      map['surah_list'] = Variable<String>(surahList.value);
    }
    if (surahTotal.present) {
      map['surah_total'] = Variable<int>(surahTotal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecitersCompanion(')
          ..write('id: $id, ')
          ..write('reciterName: $reciterName, ')
          ..write('moshafName: $moshafName, ')
          ..write('server: $server, ')
          ..write('surahList: $surahList, ')
          ..write('surahTotal: $surahTotal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HadithEntriesTable extends HadithEntries
    with TableInfo<$HadithEntriesTable, HadithEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HadithEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packIdMeta = const VerificationMeta('packId');
  @override
  late final GeneratedColumn<String> packId = GeneratedColumn<String>(
      'pack_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ordinalMeta =
      const VerificationMeta('ordinal');
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
      'ordinal', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
      'number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [packId, ordinal, number, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hadith_entries';
  @override
  VerificationContext validateIntegrity(Insertable<HadithEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pack_id')) {
      context.handle(_packIdMeta,
          packId.isAcceptableOrUnknown(data['pack_id']!, _packIdMeta));
    } else if (isInserting) {
      context.missing(_packIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(_ordinalMeta,
          ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta));
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packId, ordinal};
  @override
  HadithEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HadithEntry(
      packId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pack_id'])!,
      ordinal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ordinal'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}number'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
    );
  }

  @override
  $HadithEntriesTable createAlias(String alias) {
    return $HadithEntriesTable(attachedDatabase, alias);
  }
}

class HadithEntry extends DataClass implements Insertable<HadithEntry> {
  /// Catalog id of the owning hadith pack.
  final String packId;

  /// Zero-based position in the pack's `hadiths` array. This is the stable
  /// paging key; malformed source slots keep their ordinal as empty rows.
  final int ordinal;

  /// Printed hadith number; -1 for a malformed source entry.
  final int number;

  /// Hadith body. Empty text is a valid source value (the UI hides those
  /// rows); a malformed source entry is marked by [number] == -1.
  final String body;
  const HadithEntry(
      {required this.packId,
      required this.ordinal,
      required this.number,
      required this.body});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pack_id'] = Variable<String>(packId);
    map['ordinal'] = Variable<int>(ordinal);
    map['number'] = Variable<int>(number);
    map['body'] = Variable<String>(body);
    return map;
  }

  HadithEntriesCompanion toCompanion(bool nullToAbsent) {
    return HadithEntriesCompanion(
      packId: Value(packId),
      ordinal: Value(ordinal),
      number: Value(number),
      body: Value(body),
    );
  }

  factory HadithEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HadithEntry(
      packId: serializer.fromJson<String>(json['packId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      number: serializer.fromJson<int>(json['number']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packId': serializer.toJson<String>(packId),
      'ordinal': serializer.toJson<int>(ordinal),
      'number': serializer.toJson<int>(number),
      'body': serializer.toJson<String>(body),
    };
  }

  HadithEntry copyWith(
          {String? packId, int? ordinal, int? number, String? body}) =>
      HadithEntry(
        packId: packId ?? this.packId,
        ordinal: ordinal ?? this.ordinal,
        number: number ?? this.number,
        body: body ?? this.body,
      );
  HadithEntry copyWithCompanion(HadithEntriesCompanion data) {
    return HadithEntry(
      packId: data.packId.present ? data.packId.value : this.packId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      number: data.number.present ? data.number.value : this.number,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HadithEntry(')
          ..write('packId: $packId, ')
          ..write('ordinal: $ordinal, ')
          ..write('number: $number, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(packId, ordinal, number, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HadithEntry &&
          other.packId == this.packId &&
          other.ordinal == this.ordinal &&
          other.number == this.number &&
          other.body == this.body);
}

class HadithEntriesCompanion extends UpdateCompanion<HadithEntry> {
  final Value<String> packId;
  final Value<int> ordinal;
  final Value<int> number;
  final Value<String> body;
  final Value<int> rowid;
  const HadithEntriesCompanion({
    this.packId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.number = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HadithEntriesCompanion.insert({
    required String packId,
    required int ordinal,
    required int number,
    required String body,
    this.rowid = const Value.absent(),
  })  : packId = Value(packId),
        ordinal = Value(ordinal),
        number = Value(number),
        body = Value(body);
  static Insertable<HadithEntry> custom({
    Expression<String>? packId,
    Expression<int>? ordinal,
    Expression<int>? number,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packId != null) 'pack_id': packId,
      if (ordinal != null) 'ordinal': ordinal,
      if (number != null) 'number': number,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HadithEntriesCompanion copyWith(
      {Value<String>? packId,
      Value<int>? ordinal,
      Value<int>? number,
      Value<String>? body,
      Value<int>? rowid}) {
    return HadithEntriesCompanion(
      packId: packId ?? this.packId,
      ordinal: ordinal ?? this.ordinal,
      number: number ?? this.number,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packId.present) {
      map['pack_id'] = Variable<String>(packId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HadithEntriesCompanion(')
          ..write('packId: $packId, ')
          ..write('ordinal: $ordinal, ')
          ..write('number: $number, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SurahsTable surahs = $SurahsTable(this);
  late final $AyahsTable ayahs = $AyahsTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $KhatmaProgressTable khatmaProgress = $KhatmaProgressTable(this);
  late final $PrayerLogTable prayerLog = $PrayerLogTable(this);
  late final $InstalledPacksTable installedPacks = $InstalledPacksTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final $RecitersTable reciters = $RecitersTable(this);
  late final $HadithEntriesTable hadithEntries = $HadithEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        surahs,
        ayahs,
        bookmarks,
        khatmaProgress,
        prayerLog,
        installedPacks,
        downloads,
        settingsTable,
        reciters,
        hadithEntries
      ];
}

typedef $$SurahsTableCreateCompanionBuilder = SurahsCompanion Function({
  Value<int> id,
  required String nameAr,
  required String nameEn,
  required String revelationType,
  required int ayahCount,
  required int pagesStart,
  required int pagesEnd,
});
typedef $$SurahsTableUpdateCompanionBuilder = SurahsCompanion Function({
  Value<int> id,
  Value<String> nameAr,
  Value<String> nameEn,
  Value<String> revelationType,
  Value<int> ayahCount,
  Value<int> pagesStart,
  Value<int> pagesEnd,
});

class $$SurahsTableFilterComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameAr => $composableBuilder(
      column: $table.nameAr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get revelationType => $composableBuilder(
      column: $table.revelationType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayahCount => $composableBuilder(
      column: $table.ayahCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pagesStart => $composableBuilder(
      column: $table.pagesStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pagesEnd => $composableBuilder(
      column: $table.pagesEnd, builder: (column) => ColumnFilters(column));
}

class $$SurahsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameAr => $composableBuilder(
      column: $table.nameAr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameEn => $composableBuilder(
      column: $table.nameEn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get revelationType => $composableBuilder(
      column: $table.revelationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayahCount => $composableBuilder(
      column: $table.ayahCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pagesStart => $composableBuilder(
      column: $table.pagesStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pagesEnd => $composableBuilder(
      column: $table.pagesEnd, builder: (column) => ColumnOrderings(column));
}

class $$SurahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurahsTable> {
  $$SurahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameAr =>
      $composableBuilder(column: $table.nameAr, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get revelationType => $composableBuilder(
      column: $table.revelationType, builder: (column) => column);

  GeneratedColumn<int> get ayahCount =>
      $composableBuilder(column: $table.ayahCount, builder: (column) => column);

  GeneratedColumn<int> get pagesStart => $composableBuilder(
      column: $table.pagesStart, builder: (column) => column);

  GeneratedColumn<int> get pagesEnd =>
      $composableBuilder(column: $table.pagesEnd, builder: (column) => column);
}

class $$SurahsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurahsTable,
    Surah,
    $$SurahsTableFilterComposer,
    $$SurahsTableOrderingComposer,
    $$SurahsTableAnnotationComposer,
    $$SurahsTableCreateCompanionBuilder,
    $$SurahsTableUpdateCompanionBuilder,
    (Surah, BaseReferences<_$AppDatabase, $SurahsTable, Surah>),
    Surah,
    PrefetchHooks Function()> {
  $$SurahsTableTableManager(_$AppDatabase db, $SurahsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nameAr = const Value.absent(),
            Value<String> nameEn = const Value.absent(),
            Value<String> revelationType = const Value.absent(),
            Value<int> ayahCount = const Value.absent(),
            Value<int> pagesStart = const Value.absent(),
            Value<int> pagesEnd = const Value.absent(),
          }) =>
              SurahsCompanion(
            id: id,
            nameAr: nameAr,
            nameEn: nameEn,
            revelationType: revelationType,
            ayahCount: ayahCount,
            pagesStart: pagesStart,
            pagesEnd: pagesEnd,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nameAr,
            required String nameEn,
            required String revelationType,
            required int ayahCount,
            required int pagesStart,
            required int pagesEnd,
          }) =>
              SurahsCompanion.insert(
            id: id,
            nameAr: nameAr,
            nameEn: nameEn,
            revelationType: revelationType,
            ayahCount: ayahCount,
            pagesStart: pagesStart,
            pagesEnd: pagesEnd,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SurahsTable, Surah>(table),
                    BaseReferences<_$AppDatabase, $SurahsTable, Surah>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SurahsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SurahsTable,
    Surah,
    $$SurahsTableFilterComposer,
    $$SurahsTableOrderingComposer,
    $$SurahsTableAnnotationComposer,
    $$SurahsTableCreateCompanionBuilder,
    $$SurahsTableUpdateCompanionBuilder,
    (Surah, BaseReferences<_$AppDatabase, $SurahsTable, Surah>),
    Surah,
    PrefetchHooks Function()>;
typedef $$AyahsTableCreateCompanionBuilder = AyahsCompanion Function({
  Value<int> id,
  required int surahId,
  required int numberInSurah,
  required int juz,
  required int page,
  Value<int?> lineStart,
  Value<int?> lineEnd,
  required String textUthmani,
  required String textImlaei,
  Value<bool> sajda,
});
typedef $$AyahsTableUpdateCompanionBuilder = AyahsCompanion Function({
  Value<int> id,
  Value<int> surahId,
  Value<int> numberInSurah,
  Value<int> juz,
  Value<int> page,
  Value<int?> lineStart,
  Value<int?> lineEnd,
  Value<String> textUthmani,
  Value<String> textImlaei,
  Value<bool> sajda,
});

class $$AyahsTableFilterComposer extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numberInSurah => $composableBuilder(
      column: $table.numberInSurah, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get juz => $composableBuilder(
      column: $table.juz, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineStart => $composableBuilder(
      column: $table.lineStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lineEnd => $composableBuilder(
      column: $table.lineEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textUthmani => $composableBuilder(
      column: $table.textUthmani, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get textImlaei => $composableBuilder(
      column: $table.textImlaei, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sajda => $composableBuilder(
      column: $table.sajda, builder: (column) => ColumnFilters(column));
}

class $$AyahsTableOrderingComposer
    extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numberInSurah => $composableBuilder(
      column: $table.numberInSurah,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get juz => $composableBuilder(
      column: $table.juz, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineStart => $composableBuilder(
      column: $table.lineStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lineEnd => $composableBuilder(
      column: $table.lineEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textUthmani => $composableBuilder(
      column: $table.textUthmani, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get textImlaei => $composableBuilder(
      column: $table.textImlaei, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sajda => $composableBuilder(
      column: $table.sajda, builder: (column) => ColumnOrderings(column));
}

class $$AyahsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AyahsTable> {
  $$AyahsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<int> get numberInSurah => $composableBuilder(
      column: $table.numberInSurah, builder: (column) => column);

  GeneratedColumn<int> get juz =>
      $composableBuilder(column: $table.juz, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get lineStart =>
      $composableBuilder(column: $table.lineStart, builder: (column) => column);

  GeneratedColumn<int> get lineEnd =>
      $composableBuilder(column: $table.lineEnd, builder: (column) => column);

  GeneratedColumn<String> get textUthmani => $composableBuilder(
      column: $table.textUthmani, builder: (column) => column);

  GeneratedColumn<String> get textImlaei => $composableBuilder(
      column: $table.textImlaei, builder: (column) => column);

  GeneratedColumn<bool> get sajda =>
      $composableBuilder(column: $table.sajda, builder: (column) => column);
}

class $$AyahsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AyahsTable,
    Ayah,
    $$AyahsTableFilterComposer,
    $$AyahsTableOrderingComposer,
    $$AyahsTableAnnotationComposer,
    $$AyahsTableCreateCompanionBuilder,
    $$AyahsTableUpdateCompanionBuilder,
    (Ayah, BaseReferences<_$AppDatabase, $AyahsTable, Ayah>),
    Ayah,
    PrefetchHooks Function()> {
  $$AyahsTableTableManager(_$AppDatabase db, $AyahsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AyahsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AyahsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AyahsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> surahId = const Value.absent(),
            Value<int> numberInSurah = const Value.absent(),
            Value<int> juz = const Value.absent(),
            Value<int> page = const Value.absent(),
            Value<int?> lineStart = const Value.absent(),
            Value<int?> lineEnd = const Value.absent(),
            Value<String> textUthmani = const Value.absent(),
            Value<String> textImlaei = const Value.absent(),
            Value<bool> sajda = const Value.absent(),
          }) =>
              AyahsCompanion(
            id: id,
            surahId: surahId,
            numberInSurah: numberInSurah,
            juz: juz,
            page: page,
            lineStart: lineStart,
            lineEnd: lineEnd,
            textUthmani: textUthmani,
            textImlaei: textImlaei,
            sajda: sajda,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int surahId,
            required int numberInSurah,
            required int juz,
            required int page,
            Value<int?> lineStart = const Value.absent(),
            Value<int?> lineEnd = const Value.absent(),
            required String textUthmani,
            required String textImlaei,
            Value<bool> sajda = const Value.absent(),
          }) =>
              AyahsCompanion.insert(
            id: id,
            surahId: surahId,
            numberInSurah: numberInSurah,
            juz: juz,
            page: page,
            lineStart: lineStart,
            lineEnd: lineEnd,
            textUthmani: textUthmani,
            textImlaei: textImlaei,
            sajda: sajda,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AyahsTable, Ayah>(table),
                    BaseReferences<_$AppDatabase, $AyahsTable, Ayah>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AyahsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AyahsTable,
    Ayah,
    $$AyahsTableFilterComposer,
    $$AyahsTableOrderingComposer,
    $$AyahsTableAnnotationComposer,
    $$AyahsTableCreateCompanionBuilder,
    $$AyahsTableUpdateCompanionBuilder,
    (Ayah, BaseReferences<_$AppDatabase, $AyahsTable, Ayah>),
    Ayah,
    PrefetchHooks Function()>;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  required int ayahId,
  Value<DateTime> createdAt,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  Value<int> ayahId,
  Value<DateTime> createdAt,
});

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayahId => $composableBuilder(
      column: $table.ayahId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayahId => $composableBuilder(
      column: $table.ayahId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ayahId =>
      $composableBuilder(column: $table.ayahId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookmarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableAnnotationComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
    Bookmark,
    PrefetchHooks Function()> {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> ayahId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BookmarksCompanion(
            id: id,
            ayahId: ayahId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int ayahId,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BookmarksCompanion.insert(
            id: id,
            ayahId: ayahId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$BookmarksTable, Bookmark>(table),
                    BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableAnnotationComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
    Bookmark,
    PrefetchHooks Function()>;
typedef $$KhatmaProgressTableCreateCompanionBuilder = KhatmaProgressCompanion
    Function({
  Value<int> id,
  required int ayahId,
  required int targetPages,
  Value<DateTime> updatedAt,
});
typedef $$KhatmaProgressTableUpdateCompanionBuilder = KhatmaProgressCompanion
    Function({
  Value<int> id,
  Value<int> ayahId,
  Value<int> targetPages,
  Value<DateTime> updatedAt,
});

class $$KhatmaProgressTableFilterComposer
    extends Composer<_$AppDatabase, $KhatmaProgressTable> {
  $$KhatmaProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ayahId => $composableBuilder(
      column: $table.ayahId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetPages => $composableBuilder(
      column: $table.targetPages, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$KhatmaProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $KhatmaProgressTable> {
  $$KhatmaProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ayahId => $composableBuilder(
      column: $table.ayahId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetPages => $composableBuilder(
      column: $table.targetPages, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$KhatmaProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $KhatmaProgressTable> {
  $$KhatmaProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ayahId =>
      $composableBuilder(column: $table.ayahId, builder: (column) => column);

  GeneratedColumn<int> get targetPages => $composableBuilder(
      column: $table.targetPages, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$KhatmaProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KhatmaProgressTable,
    KhatmaProgressData,
    $$KhatmaProgressTableFilterComposer,
    $$KhatmaProgressTableOrderingComposer,
    $$KhatmaProgressTableAnnotationComposer,
    $$KhatmaProgressTableCreateCompanionBuilder,
    $$KhatmaProgressTableUpdateCompanionBuilder,
    (
      KhatmaProgressData,
      BaseReferences<_$AppDatabase, $KhatmaProgressTable, KhatmaProgressData>
    ),
    KhatmaProgressData,
    PrefetchHooks Function()> {
  $$KhatmaProgressTableTableManager(
      _$AppDatabase db, $KhatmaProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KhatmaProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KhatmaProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KhatmaProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> ayahId = const Value.absent(),
            Value<int> targetPages = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              KhatmaProgressCompanion(
            id: id,
            ayahId: ayahId,
            targetPages: targetPages,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int ayahId,
            required int targetPages,
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              KhatmaProgressCompanion.insert(
            id: id,
            ayahId: ayahId,
            targetPages: targetPages,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$KhatmaProgressTable, KhatmaProgressData>(
                        table),
                    BaseReferences<_$AppDatabase, $KhatmaProgressTable,
                        KhatmaProgressData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KhatmaProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KhatmaProgressTable,
    KhatmaProgressData,
    $$KhatmaProgressTableFilterComposer,
    $$KhatmaProgressTableOrderingComposer,
    $$KhatmaProgressTableAnnotationComposer,
    $$KhatmaProgressTableCreateCompanionBuilder,
    $$KhatmaProgressTableUpdateCompanionBuilder,
    (
      KhatmaProgressData,
      BaseReferences<_$AppDatabase, $KhatmaProgressTable, KhatmaProgressData>
    ),
    KhatmaProgressData,
    PrefetchHooks Function()>;
typedef $$PrayerLogTableCreateCompanionBuilder = PrayerLogCompanion Function({
  required DateTime day,
  Value<bool> fajr,
  Value<bool> dhuhr,
  Value<bool> asr,
  Value<bool> maghrib,
  Value<bool> isha,
  Value<int> rowid,
});
typedef $$PrayerLogTableUpdateCompanionBuilder = PrayerLogCompanion Function({
  Value<DateTime> day,
  Value<bool> fajr,
  Value<bool> dhuhr,
  Value<bool> asr,
  Value<bool> maghrib,
  Value<bool> isha,
  Value<int> rowid,
});

class $$PrayerLogTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerLogTable> {
  $$PrayerLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get fajr => $composableBuilder(
      column: $table.fajr, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dhuhr => $composableBuilder(
      column: $table.dhuhr, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get asr => $composableBuilder(
      column: $table.asr, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get maghrib => $composableBuilder(
      column: $table.maghrib, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isha => $composableBuilder(
      column: $table.isha, builder: (column) => ColumnFilters(column));
}

class $$PrayerLogTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerLogTable> {
  $$PrayerLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get fajr => $composableBuilder(
      column: $table.fajr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dhuhr => $composableBuilder(
      column: $table.dhuhr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get asr => $composableBuilder(
      column: $table.asr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get maghrib => $composableBuilder(
      column: $table.maghrib, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isha => $composableBuilder(
      column: $table.isha, builder: (column) => ColumnOrderings(column));
}

class $$PrayerLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerLogTable> {
  $$PrayerLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<bool> get fajr =>
      $composableBuilder(column: $table.fajr, builder: (column) => column);

  GeneratedColumn<bool> get dhuhr =>
      $composableBuilder(column: $table.dhuhr, builder: (column) => column);

  GeneratedColumn<bool> get asr =>
      $composableBuilder(column: $table.asr, builder: (column) => column);

  GeneratedColumn<bool> get maghrib =>
      $composableBuilder(column: $table.maghrib, builder: (column) => column);

  GeneratedColumn<bool> get isha =>
      $composableBuilder(column: $table.isha, builder: (column) => column);
}

class $$PrayerLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrayerLogTable,
    PrayerLogData,
    $$PrayerLogTableFilterComposer,
    $$PrayerLogTableOrderingComposer,
    $$PrayerLogTableAnnotationComposer,
    $$PrayerLogTableCreateCompanionBuilder,
    $$PrayerLogTableUpdateCompanionBuilder,
    (
      PrayerLogData,
      BaseReferences<_$AppDatabase, $PrayerLogTable, PrayerLogData>
    ),
    PrayerLogData,
    PrefetchHooks Function()> {
  $$PrayerLogTableTableManager(_$AppDatabase db, $PrayerLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> day = const Value.absent(),
            Value<bool> fajr = const Value.absent(),
            Value<bool> dhuhr = const Value.absent(),
            Value<bool> asr = const Value.absent(),
            Value<bool> maghrib = const Value.absent(),
            Value<bool> isha = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PrayerLogCompanion(
            day: day,
            fajr: fajr,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime day,
            Value<bool> fajr = const Value.absent(),
            Value<bool> dhuhr = const Value.absent(),
            Value<bool> asr = const Value.absent(),
            Value<bool> maghrib = const Value.absent(),
            Value<bool> isha = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PrayerLogCompanion.insert(
            day: day,
            fajr: fajr,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PrayerLogTable, PrayerLogData>(table),
                    BaseReferences<_$AppDatabase, $PrayerLogTable,
                        PrayerLogData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PrayerLogTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PrayerLogTable,
    PrayerLogData,
    $$PrayerLogTableFilterComposer,
    $$PrayerLogTableOrderingComposer,
    $$PrayerLogTableAnnotationComposer,
    $$PrayerLogTableCreateCompanionBuilder,
    $$PrayerLogTableUpdateCompanionBuilder,
    (
      PrayerLogData,
      BaseReferences<_$AppDatabase, $PrayerLogTable, PrayerLogData>
    ),
    PrayerLogData,
    PrefetchHooks Function()>;
typedef $$InstalledPacksTableCreateCompanionBuilder = InstalledPacksCompanion
    Function({
  required String packId,
  required String kind,
  required String language,
  required String title,
  required double sizeMb,
  required String version,
  Value<DateTime> installedAt,
  Value<int> rowid,
});
typedef $$InstalledPacksTableUpdateCompanionBuilder = InstalledPacksCompanion
    Function({
  Value<String> packId,
  Value<String> kind,
  Value<String> language,
  Value<String> title,
  Value<double> sizeMb,
  Value<String> version,
  Value<DateTime> installedAt,
  Value<int> rowid,
});

class $$InstalledPacksTableFilterComposer
    extends Composer<_$AppDatabase, $InstalledPacksTable> {
  $$InstalledPacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packId => $composableBuilder(
      column: $table.packId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sizeMb => $composableBuilder(
      column: $table.sizeMb, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
      column: $table.installedAt, builder: (column) => ColumnFilters(column));
}

class $$InstalledPacksTableOrderingComposer
    extends Composer<_$AppDatabase, $InstalledPacksTable> {
  $$InstalledPacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packId => $composableBuilder(
      column: $table.packId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sizeMb => $composableBuilder(
      column: $table.sizeMb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
      column: $table.installedAt, builder: (column) => ColumnOrderings(column));
}

class $$InstalledPacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstalledPacksTable> {
  $$InstalledPacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packId =>
      $composableBuilder(column: $table.packId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get sizeMb =>
      $composableBuilder(column: $table.sizeMb, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
      column: $table.installedAt, builder: (column) => column);
}

class $$InstalledPacksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InstalledPacksTable,
    InstalledPack,
    $$InstalledPacksTableFilterComposer,
    $$InstalledPacksTableOrderingComposer,
    $$InstalledPacksTableAnnotationComposer,
    $$InstalledPacksTableCreateCompanionBuilder,
    $$InstalledPacksTableUpdateCompanionBuilder,
    (
      InstalledPack,
      BaseReferences<_$AppDatabase, $InstalledPacksTable, InstalledPack>
    ),
    InstalledPack,
    PrefetchHooks Function()> {
  $$InstalledPacksTableTableManager(
      _$AppDatabase db, $InstalledPacksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstalledPacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstalledPacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstalledPacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> packId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<double> sizeMb = const Value.absent(),
            Value<String> version = const Value.absent(),
            Value<DateTime> installedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstalledPacksCompanion(
            packId: packId,
            kind: kind,
            language: language,
            title: title,
            sizeMb: sizeMb,
            version: version,
            installedAt: installedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String packId,
            required String kind,
            required String language,
            required String title,
            required double sizeMb,
            required String version,
            Value<DateTime> installedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstalledPacksCompanion.insert(
            packId: packId,
            kind: kind,
            language: language,
            title: title,
            sizeMb: sizeMb,
            version: version,
            installedAt: installedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$InstalledPacksTable, InstalledPack>(table),
                    BaseReferences<_$AppDatabase, $InstalledPacksTable,
                        InstalledPack>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InstalledPacksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InstalledPacksTable,
    InstalledPack,
    $$InstalledPacksTableFilterComposer,
    $$InstalledPacksTableOrderingComposer,
    $$InstalledPacksTableAnnotationComposer,
    $$InstalledPacksTableCreateCompanionBuilder,
    $$InstalledPacksTableUpdateCompanionBuilder,
    (
      InstalledPack,
      BaseReferences<_$AppDatabase, $InstalledPacksTable, InstalledPack>
    ),
    InstalledPack,
    PrefetchHooks Function()>;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  Value<int> id,
  required String reciterId,
  required int surahId,
  required String status,
  Value<int> bytes,
  required String path,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<int> id,
  Value<String> reciterId,
  Value<int> surahId,
  Value<String> status,
  Value<int> bytes,
  Value<String> path,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reciterId => $composableBuilder(
      column: $table.reciterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reciterId => $composableBuilder(
      column: $table.reciterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surahId => $composableBuilder(
      column: $table.surahId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bytes => $composableBuilder(
      column: $table.bytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reciterId =>
      $composableBuilder(column: $table.reciterId, builder: (column) => column);

  GeneratedColumn<int> get surahId =>
      $composableBuilder(column: $table.surahId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);
}

class $$DownloadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
    Download,
    PrefetchHooks Function()> {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> reciterId = const Value.absent(),
            Value<int> surahId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> bytes = const Value.absent(),
            Value<String> path = const Value.absent(),
          }) =>
              DownloadsCompanion(
            id: id,
            reciterId: reciterId,
            surahId: surahId,
            status: status,
            bytes: bytes,
            path: path,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String reciterId,
            required int surahId,
            required String status,
            Value<int> bytes = const Value.absent(),
            required String path,
          }) =>
              DownloadsCompanion.insert(
            id: id,
            reciterId: reciterId,
            surahId: surahId,
            status: status,
            bytes: bytes,
            path: path,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$DownloadsTable, Download>(table),
                    BaseReferences<_$AppDatabase, $DownloadsTable, Download>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DownloadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
    Download,
    PrefetchHooks Function()>;
typedef $$SettingsTableTableCreateCompanionBuilder = SettingsTableCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableTableUpdateCompanionBuilder = SettingsTableCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()> {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsTableCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsTableCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SettingsTableTable, SettingsTableData>(table),
                    BaseReferences<_$AppDatabase, $SettingsTableTable,
                        SettingsTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsTableData,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsTableData,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsTableData>
    ),
    SettingsTableData,
    PrefetchHooks Function()>;
typedef $$RecitersTableCreateCompanionBuilder = RecitersCompanion Function({
  required String id,
  required String reciterName,
  required String moshafName,
  required String server,
  required String surahList,
  required int surahTotal,
  Value<int> rowid,
});
typedef $$RecitersTableUpdateCompanionBuilder = RecitersCompanion Function({
  Value<String> id,
  Value<String> reciterName,
  Value<String> moshafName,
  Value<String> server,
  Value<String> surahList,
  Value<int> surahTotal,
  Value<int> rowid,
});

class $$RecitersTableFilterComposer
    extends Composer<_$AppDatabase, $RecitersTable> {
  $$RecitersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reciterName => $composableBuilder(
      column: $table.reciterName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get moshafName => $composableBuilder(
      column: $table.moshafName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get server => $composableBuilder(
      column: $table.server, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surahList => $composableBuilder(
      column: $table.surahList, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get surahTotal => $composableBuilder(
      column: $table.surahTotal, builder: (column) => ColumnFilters(column));
}

class $$RecitersTableOrderingComposer
    extends Composer<_$AppDatabase, $RecitersTable> {
  $$RecitersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reciterName => $composableBuilder(
      column: $table.reciterName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get moshafName => $composableBuilder(
      column: $table.moshafName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get server => $composableBuilder(
      column: $table.server, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surahList => $composableBuilder(
      column: $table.surahList, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get surahTotal => $composableBuilder(
      column: $table.surahTotal, builder: (column) => ColumnOrderings(column));
}

class $$RecitersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecitersTable> {
  $$RecitersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reciterName => $composableBuilder(
      column: $table.reciterName, builder: (column) => column);

  GeneratedColumn<String> get moshafName => $composableBuilder(
      column: $table.moshafName, builder: (column) => column);

  GeneratedColumn<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => column);

  GeneratedColumn<String> get surahList =>
      $composableBuilder(column: $table.surahList, builder: (column) => column);

  GeneratedColumn<int> get surahTotal => $composableBuilder(
      column: $table.surahTotal, builder: (column) => column);
}

class $$RecitersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecitersTable,
    ReciterRow,
    $$RecitersTableFilterComposer,
    $$RecitersTableOrderingComposer,
    $$RecitersTableAnnotationComposer,
    $$RecitersTableCreateCompanionBuilder,
    $$RecitersTableUpdateCompanionBuilder,
    (ReciterRow, BaseReferences<_$AppDatabase, $RecitersTable, ReciterRow>),
    ReciterRow,
    PrefetchHooks Function()> {
  $$RecitersTableTableManager(_$AppDatabase db, $RecitersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecitersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecitersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecitersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> reciterName = const Value.absent(),
            Value<String> moshafName = const Value.absent(),
            Value<String> server = const Value.absent(),
            Value<String> surahList = const Value.absent(),
            Value<int> surahTotal = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecitersCompanion(
            id: id,
            reciterName: reciterName,
            moshafName: moshafName,
            server: server,
            surahList: surahList,
            surahTotal: surahTotal,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String reciterName,
            required String moshafName,
            required String server,
            required String surahList,
            required int surahTotal,
            Value<int> rowid = const Value.absent(),
          }) =>
              RecitersCompanion.insert(
            id: id,
            reciterName: reciterName,
            moshafName: moshafName,
            server: server,
            surahList: surahList,
            surahTotal: surahTotal,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RecitersTable, ReciterRow>(table),
                    BaseReferences<_$AppDatabase, $RecitersTable, ReciterRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecitersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecitersTable,
    ReciterRow,
    $$RecitersTableFilterComposer,
    $$RecitersTableOrderingComposer,
    $$RecitersTableAnnotationComposer,
    $$RecitersTableCreateCompanionBuilder,
    $$RecitersTableUpdateCompanionBuilder,
    (ReciterRow, BaseReferences<_$AppDatabase, $RecitersTable, ReciterRow>),
    ReciterRow,
    PrefetchHooks Function()>;
typedef $$HadithEntriesTableCreateCompanionBuilder = HadithEntriesCompanion
    Function({
  required String packId,
  required int ordinal,
  required int number,
  required String body,
  Value<int> rowid,
});
typedef $$HadithEntriesTableUpdateCompanionBuilder = HadithEntriesCompanion
    Function({
  Value<String> packId,
  Value<int> ordinal,
  Value<int> number,
  Value<String> body,
  Value<int> rowid,
});

class $$HadithEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HadithEntriesTable> {
  $$HadithEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packId => $composableBuilder(
      column: $table.packId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ordinal => $composableBuilder(
      column: $table.ordinal, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));
}

class $$HadithEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HadithEntriesTable> {
  $$HadithEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packId => $composableBuilder(
      column: $table.packId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ordinal => $composableBuilder(
      column: $table.ordinal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));
}

class $$HadithEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HadithEntriesTable> {
  $$HadithEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packId =>
      $composableBuilder(column: $table.packId, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$HadithEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HadithEntriesTable,
    HadithEntry,
    $$HadithEntriesTableFilterComposer,
    $$HadithEntriesTableOrderingComposer,
    $$HadithEntriesTableAnnotationComposer,
    $$HadithEntriesTableCreateCompanionBuilder,
    $$HadithEntriesTableUpdateCompanionBuilder,
    (
      HadithEntry,
      BaseReferences<_$AppDatabase, $HadithEntriesTable, HadithEntry>
    ),
    HadithEntry,
    PrefetchHooks Function()> {
  $$HadithEntriesTableTableManager(_$AppDatabase db, $HadithEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HadithEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HadithEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HadithEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> packId = const Value.absent(),
            Value<int> ordinal = const Value.absent(),
            Value<int> number = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HadithEntriesCompanion(
            packId: packId,
            ordinal: ordinal,
            number: number,
            body: body,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String packId,
            required int ordinal,
            required int number,
            required String body,
            Value<int> rowid = const Value.absent(),
          }) =>
              HadithEntriesCompanion.insert(
            packId: packId,
            ordinal: ordinal,
            number: number,
            body: body,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$HadithEntriesTable, HadithEntry>(table),
                    BaseReferences<_$AppDatabase, $HadithEntriesTable,
                        HadithEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HadithEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HadithEntriesTable,
    HadithEntry,
    $$HadithEntriesTableFilterComposer,
    $$HadithEntriesTableOrderingComposer,
    $$HadithEntriesTableAnnotationComposer,
    $$HadithEntriesTableCreateCompanionBuilder,
    $$HadithEntriesTableUpdateCompanionBuilder,
    (
      HadithEntry,
      BaseReferences<_$AppDatabase, $HadithEntriesTable, HadithEntry>
    ),
    HadithEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db, _db.ayahs);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$KhatmaProgressTableTableManager get khatmaProgress =>
      $$KhatmaProgressTableTableManager(_db, _db.khatmaProgress);
  $$PrayerLogTableTableManager get prayerLog =>
      $$PrayerLogTableTableManager(_db, _db.prayerLog);
  $$InstalledPacksTableTableManager get installedPacks =>
      $$InstalledPacksTableTableManager(_db, _db.installedPacks);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$RecitersTableTableManager get reciters =>
      $$RecitersTableTableManager(_db, _db.reciters);
  $$HadithEntriesTableTableManager get hadithEntries =>
      $$HadithEntriesTableTableManager(_db, _db.hadithEntries);
}
