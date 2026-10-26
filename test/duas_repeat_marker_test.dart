import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/duas/data/dua_repository.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_cubit.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_screen.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDb();
  });

  Future<void> pumpHost(WidgetTester tester, {required Locale locale}) async {
    final cubit = DuasCubit(
      duas: DuaRepository(
          loader: () async => [
                {
                  'id': 'a1',
                  'categoryAr': 'المنزل',
                  'categoryEn': 'Home',
                  'text': 'بِسْمِ اللَّهِ وَلَجْنَا',
                },
              ]),
      ruqyah: RuqyahRepository(
          loader: () async => [
                {
                  'id': 'r1',
                  'kind': 'dhikr',
                  'text': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ',
                  'count': 3,
                },
              ]),
      ayahs: AyahRepository(db),
    );
    addTearDown(cubit.close);
    await cubit.start();
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<DuasCubit>.value(value: cubit, child: app),
      home: const DuasScreen(),
      locale: locale,
    );
  }

  testWidgets('repetition marker renders from the l10n key (arabic locale)',
      (tester) async {
    await pumpHost(tester, locale: const Locale('ar'));

    await tester.tap(find.text('الرقية'));
    await tester.pumpAndSettle();

    expect(find.text('×٣'), findsOneWidget);
    expect(find.text('×3'), findsNothing,
        reason: 'marker digits must be Arabic-Indic at the call site');
  });

  testWidgets('repetition marker renders from the l10n key (english locale)',
      (tester) async {
    await pumpHost(tester, locale: const Locale('en'));

    await tester.tap(find.text('Ruqyah'));
    await tester.pumpAndSettle();

    expect(find.text('×٣'), findsOneWidget);
  });
}
