import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_cubit.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late PrayerLogRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = PrayerLogRepository(db);
  });

  Future<void> pumpHost(WidgetTester tester) async {
    final cubit = TrackerCubit(repo: repo);
    addTearDown(cubit.close);
    await cubit.start();
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<TrackerCubit>.value(value: cubit, child: app),
      home: const TrackerScreen(),
    );
  }

  testWidgets('five prayer toggle rows; tapping fajr fills the checkbox',
      (tester) async {
    await pumpHost(tester);

    expect(find.text('صلوات اليوم'), findsOneWidget);
    expect(find.text('فجر'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));

    await tester.tap(find.text('فجر'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));
    expect(find.text('سلسلة ١ يوم'), findsOneWidget);

    final marked = await repo.getForDay(DateTime.now());
    expect(marked, isTrue);
  });
}
