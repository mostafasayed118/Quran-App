import 'dart:ui' show CheckedState;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/tracker/data/prayer_log_repository.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_cubit.dart';
import 'package:quran_yahdi/features/tracker/presentation/tracker_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late PrayerLogRepository repo;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = PrayerLogRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpTracker(WidgetTester tester) async {
    final cubit = TrackerCubit(repo: repo);
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<TrackerCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: const TrackerScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('each of the seven dots announces its day and marked state',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTracker(tester);

    const labels = [
      'اليوم: غير مُسجَّل',
      'أمس: غير مُسجَّل',
      'قبل يومين: غير مُسجَّل',
      'قبل ٣ أيام: غير مُسجَّل',
      'قبل ٤ أيام: غير مُسجَّل',
      'قبل ٥ أيام: غير مُسجَّل',
      'قبل ٦ أيام: غير مُسجَّل',
    ];
    for (final label in labels) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    handle.dispose();
  });

  testWidgets('slot rows expose a checked state that follows the toggle',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTracker(tester);

    var data =
        tester.getSemantics(find.bySemanticsLabel('فجر')).getSemanticsData();
    expect(data.flagsCollection.isChecked, CheckedState.isFalse);

    await tester.tap(find.text('فجر'));
    await tester.pumpAndSettle();

    data = tester.getSemantics(find.bySemanticsLabel('فجر')).getSemanticsData();
    expect(data.flagsCollection.isChecked, CheckedState.isTrue);
    expect(find.bySemanticsLabel('اليوم: مُسجَّل'), findsOneWidget);
    handle.dispose();
  });
}
