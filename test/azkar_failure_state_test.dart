import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

Future<void> pumpAzkar(WidgetTester tester, AzkarRepository repository) async {
  final cubit = AzkarCubit(repository: repository);
  addTearDown(cubit.close);
  await cubit.start();
  await tester.pumpWidget(BlocProvider<AzkarCubit>.value(
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
      home: const AzkarScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a loader crash shows the localized error pane, not a spinner',
      (tester) async {
    await pumpAzkar(
      tester,
      AzkarRepository(loader: () async => throw StateError('boom')),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsOneWidget);
  });

  testWidgets('an empty dataset shows the empty state, not a blank body',
      (tester) async {
    await pumpAzkar(
      tester,
      AzkarRepository(loader: () async => {'collections': <Object>[]}),
    );

    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
