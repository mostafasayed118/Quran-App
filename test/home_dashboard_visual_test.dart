import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/widgets/service_tile.dart';
import 'package:quran_yahdi/features/home/presentation/home_cubit.dart';
import 'package:quran_yahdi/features/home/presentation/home_screen.dart';
import 'package:quran_yahdi/features/prayer/data/city_repository.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';
import 'package:quran_yahdi/features/quran/data/last_read_repository.dart';

import 'home_cubit_test.dart' show FakePrayerTimeService, cairoCity;
import 'support/host.dart';
import 'support/test_db.dart';

/// Every destination the dashboard must keep, in the order the groups read.
const _labels = <String>[
  'القرآن الكريم',
  'التلاوات',
  'العلامات المرجعية',
  'مواقيت الصلاة',
  'القبلة',
  'الأذكار',
  'السبحة',
  'الأدعية والرقية',
  'تتبع العبادات',
  'المكتبة',
  'الزكاة',
  'التقويم الهجري',
  'أسماء الله الحسنى',
  'الإعدادات',
];

final _clock = RegExp(r'^[٠-٩]{2}:[٠-٩]{2}:[٠-٩]{2}$');

void main() {
  late AppDatabase db;
  late LastReadRepository lastRead;
  late AyahRepository ayahs;
  late CityRepository city;

  setUp(() async {
    db = newTestDb();
    lastRead = LastReadRepository(db);
    ayahs = AyahRepository(db);
    city = CityRepository(db: db, loader: () async => [cairoCity.toJson()]);
    await db.into(db.surahs).insert(SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          revelationType: 'Medinan',
          ayahCount: 286,
          pagesStart: 2,
          pagesEnd: 49,
        ));
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: const Value(8),
          surahId: 2,
          numberInSurah: 83,
          juz: 1,
          page: 2,
          textUthmani: 'وإذ أخذنا ميثاق بني إسرائيل',
          textImlaei: 'واذ اخذنا ميثاق بني اسرائيل',
        ));
    await city.select(cairoCity);
    await lastRead.saveAyahId(8);
  });

  Future<HomeCubit> pumpDashboard(
    WidgetTester tester, {
    double? textScale,
  }) async {
    final cubit = HomeCubit(
      lastRead: lastRead,
      ayahs: ayahs,
      prayer: FakePrayerTimeService(),
      city: city,
    );
    addTearDown(cubit.close);
    await cubit.start();
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<HomeCubit>.value(value: cubit, child: app),
      home: const HomeScreen(),
      textScale: textScale,
    );
    return cubit;
  }

  testWidgets('the dashboard groups every destination under a named section',
      (tester) async {
    await pumpDashboard(tester);

    expect(find.text('القرآن والاستماع'), findsOneWidget);
    expect(find.text('العبادة اليومية'), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);
    expect(find.byType(ServiceTile), findsNWidgets(_labels.length));
    for (final label in _labels) {
      expect(find.text(label), findsOneWidget, reason: 'missing tile: $label');
    }
  });

  testWidgets('the next-prayer hero shows the city, the time and a countdown',
      (tester) async {
    await pumpDashboard(tester);

    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.text('فجر'), findsOneWidget);
    expect(find.text('القاهرة'), findsOneWidget);
    // The target time, and a countdown clamped at zero for a prayer that has
    // already passed (the cubit reloads on the real device).
    expect(find.text('٠٤:٤٥'), findsOneWidget);
    expect(find.text('٠٠:٠٠:٠٠'), findsOneWidget);

    final clocks = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.data != null && _clock.hasMatch(t.data!))
        .toList();
    expect(clocks, hasLength(1),
        reason: 'the hero renders exactly one countdown line');
  });

  testWidgets('service tiles stay at least 48 dp at a 1.0 text scale',
      (tester) async {
    await pumpDashboard(tester);

    for (final element in find.byType(ServiceTile).evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('textScale 2.0: the groups grow instead of clipping labels',
      (tester) async {
    await pumpDashboard(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    for (final label in _labels) {
      expect(find.text(label), findsOneWidget, reason: 'missing tile: $label');
    }
    // The label must be laid out with room to wrap, not truncated with an
    // ellipsis, which is what the previous fixed-aspect grid did.
    final label = tester.widget<Text>(find.text('أسماء الله الحسنى'));
    expect(label.maxLines, isNull);
    expect(label.overflow, isNull);
  });
}
