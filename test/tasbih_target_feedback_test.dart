import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_cubit.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late TasbihRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = TasbihRepository(db);
  });

  Future<TasbihCubit> pumpHost(WidgetTester tester) async {
    final cubit = TasbihCubit(repo: repo);
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<TasbihCubit>.value(value: cubit, child: app),
      home: const TasbihScreen(),
    );
    return cubit;
  }

  testWidgets('picking a target announces the restart; counting does not',
      (tester) async {
    await pumpHost(tester);

    expect(find.text('تم ضبط الهدف — بدأ العد من جديد'), findsNothing);

    await tester.tap(find.byKey(const Key('tasbih_dial')));
    await tester.pump();
    await tester.pump();
    expect(find.text('تم ضبط الهدف — بدأ العد من جديد'), findsNothing);

    await tester.tap(find.text('١٠٠'));
    await tester.pump();
    await tester.pump();

    expect(find.text('تم ضبط الهدف — بدأ العد من جديد'), findsOneWidget);
    expect(find.text('٠'), findsOneWidget);
  });
}
