import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_cubit.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late TasbihRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = TasbihRepository(db);
  });

  testWidgets(
      'dial shows count and target; tapping increments; chips switch target',
      (tester) async {
    final cubit = TasbihCubit(repo: repo);
    addTearDown(cubit.close);
    await cubit.start();
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

    expect(find.text('٠'), findsOneWidget);
    final targetLabels = [
      find.text('٣٣'),
      find.text('٩٩'),
      find.text('١٠٠'),
      find.text('٥٠٠')
    ];
    for (final label in targetLabels) {
      expect(label, findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('tasbih_dial')));
    await tester.pump();
    await tester.pump();
    expect(find.text('١'), findsOneWidget);

    await tester.tap(find.text('١٠٠'));
    await tester.pump();
    await tester.pump();
    expect(find.text('٠'), findsOneWidget);
  });
}
