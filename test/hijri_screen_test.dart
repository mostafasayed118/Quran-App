import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_cubit.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/host.dart';

void main() {
  testWidgets('grid renders today with a dual label; jump chip highlights',
      (tester) async {
    final cubit = HijriCubit(service: HijriService());
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(BlocProvider<HijriCubit>.value(
      value: cubit,
      child: appShell(home: const HijriScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.byTooltip('اليوم'), findsOneWidget);
    expect(find.textContaining('الشهر'), findsOneWidget);
    expect(find.textContaining('١٥'), findsAtLeastNWidgets(1));
  });

  testWidgets('320 dp at textScale 2.0 survives the month grid',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = HijriCubit(service: HijriService());
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(BlocProvider<HijriCubit>.value(
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
              .copyWith(textScaler: const TextScaler.linear(2.0)),
          child: child!,
        ),
        home: const HijriScreen(),
      ),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('اليوم'), findsOneWidget);
  });
}
