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

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = PrayerLogRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpTracker(
    WidgetTester tester, {
    double textScale = 1.0,
  }) async {
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const TrackerScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('slot rows meet the 48 dp touch-target bar', (tester) async {
    await pumpTracker(tester);

    final tiles = find.byType(ListTile);
    expect(tiles, findsNWidgets(5));
    for (var i = 0; i < 5; i++) {
      final size = tester.getSize(tiles.at(i));
      expect(
        size.height,
        greaterThanOrEqualTo(48.0),
        reason: 'slot $i measured ${size.height} x ${size.width}',
      );
    }
  });

  testWidgets(
      'textScale 2.0 on a 360-wide phone: slots, dots and streak survive',
      (tester) async {
    usePhoneViewport(tester);
    await pumpTracker(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.text('صلوات اليوم'), findsOneWidget);

    await tester.tap(find.text('فجر'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('آخر ٧ أيام'), 100,
        scrollable: scrollable);
    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(6));
    expect(find.byIcon(Icons.circle), findsOneWidget);

    await tester.scrollUntilVisible(find.text('سلسلة ١ يوم'), 100,
        scrollable: scrollable);
    expect(find.text('سلسلة ١ يوم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
