import 'package:flutter/material.dart';
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

  Future<TasbihCubit> pumpHost(WidgetTester tester) async {
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
        home: const TasbihScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('the done state survives an overshoot and only reset clears it',
      (tester) async {
    final cubit = await pumpHost(tester);

    double dialScale() {
      final scales =
          tester.widgetList<AnimatedScale>(find.byType(AnimatedScale)).toList();
      expect(scales, hasLength(1));
      return scales.single.scale;
    }

    await cubit.selectTarget(33);
    for (var i = 0; i < 33; i++) {
      await cubit.increment();
    }
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('تم بحمد الله'), findsOneWidget);
    expect(dialScale(), 1.06);

    await tester.tap(find.byKey(const Key('tasbih_dial')));
    await tester.pump();
    await tester.pump();

    expect(find.text('٣٤'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('تم بحمد الله'), findsOneWidget);
    expect(dialScale(), 1.06);

    await tester.tap(find.text('تصفير'));
    await tester.pump();
    await tester.pump();

    expect(find.text('٠'), findsOneWidget);
    expect(find.byIcon(Icons.touch_app_outlined), findsOneWidget);
    expect(find.text('تم بحمد الله'), findsNothing);
    expect(dialScale(), 1.0);
  });
}
