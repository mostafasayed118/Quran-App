import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/widgets/empty_state.dart';
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

  Future<void> pumpHost(WidgetTester tester) async {
    final cubit = DuasCubit(
      duas: DuaRepository(loader: () async => []),
      ruqyah: RuqyahRepository(loader: () async => []),
      ayahs: AyahRepository(db),
    );
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<DuasCubit>.value(value: cubit, child: app),
      home: const DuasScreen(),
    );
  }

  testWidgets('empty duas dataset shows the localized no-results state',
      (tester) async {
    await pumpHost(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('empty ruqyah dataset shows the localized no-results state',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('الرقية'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
  });
}
