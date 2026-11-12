import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_cubit.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  testWidgets('tapping the already-selected target keeps the count',
      (tester) async {
    final db = newTestDb();
    final cubit = TasbihCubit(repo: TasbihRepository(db));
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(BlocProvider<TasbihCubit>.value(
      value: cubit,
      child: appShell(home: const TasbihScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    await tester.tap(find.byKey(const Key('tasbih_dial')));
    await tester.pump();
    await tester.pump();
    expect(find.text('١'), findsOneWidget);

    // 33 is the default target and therefore already selected.
    await tester.tap(find.text('٣٣'));
    await tester.pump();
    await tester.pump();

    expect(find.text('١'), findsOneWidget,
        reason: 'a stray tap on the highlighted chip must not wipe the count');
    expect(find.text('٠'), findsNothing);
  });
}
