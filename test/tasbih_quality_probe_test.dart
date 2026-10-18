import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift/native.dart';
import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_cubit.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late TasbihRepository repo;

  setUp(() async {
    db = AppDatabase.test(NativeDatabase.memory());
    repo = TasbihRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<TasbihCubit> pumpHost(
    WidgetTester tester, {
    double textScale = 1.0,
  }) async {
    final cubit = TasbihCubit(repo: repo);
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<TasbihCubit>.value(
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
        home: const TasbihScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return cubit;
  }

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('target chips meet the 48 dp touch-target bar', (tester) async {
    await pumpHost(tester);

    final chips = find.byType(ChoiceChip);
    expect(chips, findsNWidgets(4));
    for (var i = 0; i < 4; i++) {
      final size = tester.getSize(chips.at(i));
      expect(
        size.height,
        greaterThanOrEqualTo(48.0),
        reason: 'chip $i measured ${size.height} x ${size.width}',
      );
      expect(
        size.width,
        greaterThanOrEqualTo(48.0),
        reason: 'chip $i measured ${size.height} x ${size.width}',
      );
    }
  });

  testWidgets('textScale 2.0 on a 360-wide phone: the counter survives',
      (tester) async {
    usePhoneViewport(tester);
    await pumpHost(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('tasbih_dial')), findsOneWidget);
    expect(find.text('٠'), findsOneWidget);
    expect(find.text('الهدف: ٣٣'), findsOneWidget);
  });

  testWidgets('textScale 2.0: the done state survives the layout',
      (tester) async {
    usePhoneViewport(tester);
    final cubit = await pumpHost(tester, textScale: 2.0);

    await cubit.selectTarget(33);
    for (var i = 0; i < 33; i++) {
      await cubit.increment();
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('تم بحمد الله'), findsOneWidget);
  });

  testWidgets('dial exposes a tap action to screen readers', (tester) async {
    await pumpHost(tester);

    final data = tester
        .getSemantics(find.byKey(const Key('tasbih_dial')))
        .getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isTrue);
  });
}
