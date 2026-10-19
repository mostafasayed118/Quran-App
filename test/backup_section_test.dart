import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/backup/data/backup_codec.dart';
import 'package:quran_yahdi/features/backup/data/backup_service.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_cubit.dart';
import 'package:quran_yahdi/features/backup/presentation/backup_section.dart';

import 'support/host.dart';
import 'support/test_db.dart';

class _SpyService extends BackupService {
  _SpyService({required super.db, required super.reschedule});

  int applies = 0;

  @override
  Future<BackupOutcome> apply(BackupDocument document) {
    applies++;
    return super.apply(document);
  }
}

/// Three new bookmarks + two worship days — a clean preview on an empty db.
BackupDocument craftedDoc() => BackupDocument(
      exportedAt: DateTime(2026, 10, 19),
      schemaVersion: 2,
      data: BackupData(
        bookmarks: [
          for (var i = 1; i <= 3; i++)
            BackupBookmark(ayahId: i, createdAt: DateTime(2026, 1, 1)),
        ],
        lastReadAyahId: null,
        khatma: const [],
        prayerLog: [
          BackupPrayerDay(
            day: DateTime(2026, 5, 1),
            fajr: true,
            dhuhr: false,
            asr: false,
            maghrib: false,
            isha: false,
          ),
          BackupPrayerDay(
            day: DateTime(2026, 5, 2),
            fajr: false,
            dhuhr: false,
            asr: false,
            maghrib: false,
            isha: true,
          ),
        ],
        tasbih: null,
        settings: const {},
      ),
    );

/// Bounded pumps: drift futures + dialog/snackbar animations advance on
/// explicit pumps only (no pumpAndSettle on a live DB, per the wave brief).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late _SpyService service;
  late int rescheduleCalls;

  setUp(() {
    db = newTestDb();
    rescheduleCalls = 0;
    service = _SpyService(
      db: db,
      reschedule: () async {
        rescheduleCalls++;
      },
    );
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    BackupPickBytes? pickBytes,
    BackupShareJson? shareJson,
  }) async {
    final cubit = BackupCubit(
      service: service,
      pickBytes: pickBytes ?? () async => null,
      shareJson: shareJson,
    );
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<BackupCubit>.value(value: cubit, child: app),
      home: const Scaffold(body: BackupSection()),
      settle: false,
    );
    await settle(tester);
  }

  testWidgets('renders the section title and the two rows', (tester) async {
    await pumpSection(tester);

    expect(find.text('النسخ الاحتياطي والاستعادة'), findsOneWidget);
    expect(find.text('تصدير البيانات'), findsOneWidget);
    expect(find.text('استيراد البيانات'), findsOneWidget);
  });

  testWidgets('a failed export shows the localized failure copy',
      (tester) async {
    await pumpSection(
      tester,
      shareJson: (json) async => throw StateError('no share sheet'),
    );

    await tester.tap(find.text('تصدير البيانات'));
    await settle(tester);

    expect(find.text('تعذّر تصدير البيانات'), findsOneWidget);
  });

  testWidgets('a successful export shares the encoded document',
      (tester) async {
    String? shared;
    await pumpSection(
      tester,
      shareJson: (json) async {
        shared = json;
      },
    );

    await tester.tap(find.text('تصدير البيانات'));
    await settle(tester);

    expect(shared, isNotNull);
    expect(decode(shared!), isA<BackupDecodeSuccess>());
    expect(find.text('تم تصدير البيانات'), findsOneWidget);
  });

  testWidgets('preview shows the per-entity counts; cancel writes nothing',
      (tester) async {
    await pumpSection(
      tester,
      pickBytes: () async => utf8.encode(encode(craftedDoc())),
    );

    await tester.tap(find.text('استيراد البيانات'));
    await settle(tester);

    expect(find.text('مراجعة الاستيراد'), findsOneWidget);
    expect(find.text('٣ علامة جديدة'), findsOneWidget);
    expect(find.text('٢ يوم عبادات'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await settle(tester);

    expect(find.text('مراجعة الاستيراد'), findsNothing);
    expect(service.applies, 0);
    expect(await db.select(db.bookmarks).get(), isEmpty);
    expect(await db.select(db.prayerLog).get(), isEmpty);
    expect(rescheduleCalls, 0);
  });

  testWidgets('merge applies the document and shows the success copy',
      (tester) async {
    await pumpSection(
      tester,
      pickBytes: () async => utf8.encode(encode(craftedDoc())),
    );

    await tester.tap(find.text('استيراد البيانات'));
    await settle(tester);
    await tester.tap(find.text('دمج'));
    await settle(tester);

    expect(find.text('مراجعة الاستيراد'), findsNothing);
    expect(service.applies, 1);
    expect(await db.select(db.bookmarks).get(), hasLength(3));
    expect(await db.select(db.prayerLog).get(), hasLength(2));
    expect(rescheduleCalls, 0);
    expect(find.text('تم استيراد البيانات ودمجها'), findsOneWidget);
  });

  testWidgets('an invalid file shows the invalid-file copy', (tester) async {
    await pumpSection(
      tester,
      pickBytes: () async => utf8.encode('definitely not a backup'),
    );

    await tester.tap(find.text('استيراد البيانات'));
    await settle(tester);

    expect(find.text('الملف المختار ليس نسخة احتياطية صالحة'), findsOneWidget);
    expect(service.applies, 0);
  });

  testWidgets('a cancelled pick changes nothing', (tester) async {
    await pumpSection(tester, pickBytes: () async => null);

    await tester.tap(find.text('استيراد البيانات'));
    await settle(tester);

    expect(find.text('مراجعة الاستيراد'), findsNothing);
    expect(find.text('الملف المختار ليس نسخة احتياطية صالحة'), findsNothing);
    expect(await db.select(db.bookmarks).get(), isEmpty);
  });
}
