import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/asma/data/asma_repository.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_cubit.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'asma_repository_test.dart' show fixtureRows;

void main() {
  testWidgets('system back closes the name sheet without leaving Asma',
      (tester) async {
    final cubit = AsmaCubit(
      repository: AsmaRepository(loader: () async => fixtureRows()),
    );
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(BlocProvider<AsmaCubit>.value(
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
        home: const AsmaScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الرحيم'));
    await tester.pumpAndSettle();
    expect(find.text('النازل بالرحمة'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('النازل بالرحمة'), findsNothing);
    expect(find.text('الرحيم'), findsOneWidget);
  });
}
