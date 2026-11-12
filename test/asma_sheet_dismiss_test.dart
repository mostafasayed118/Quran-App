import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/asma/data/asma_repository.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_cubit.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_screen.dart';

import 'asma_repository_test.dart' show fixtureRows;

import 'support/host.dart';

Future<void> pumpAsma(WidgetTester tester) async {
  final cubit = AsmaCubit(
    repository: AsmaRepository(loader: () async => fixtureRows()),
  );
  addTearDown(cubit.close);
  await cubit.start();
  await tester.pumpWidget(BlocProvider<AsmaCubit>.value(
    value: cubit,
    child: appShell(home: const AsmaScreen()),
  ));
  await tester.pumpAndSettle(const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
}

void main() {
  testWidgets('tapping the scrim closes the meanings sheet', (tester) async {
    await pumpAsma(tester);

    await tester.tap(find.text('الرحيم'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    expect(find.text('النازل بالرحمة'), findsOneWidget);

    await tester.tapAt(const Offset(20, 300));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(tester.takeException(), isNull);
    expect(find.text('النازل بالرحمة'), findsNothing);
  });

  testWidgets('tapping inside the sheet keeps it open', (tester) async {
    await pumpAsma(tester);

    await tester.tap(find.text('الرحيم'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    await tester.tap(find.text('النازل بالرحمة'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.text('النازل بالرحمة'), findsOneWidget);
  });

  testWidgets('after dismissal the grid selects again', (tester) async {
    await pumpAsma(tester);

    await tester.tap(find.text('الرحيم'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    await tester.tapAt(const Offset(20, 300));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    await tester.tap(find.text('الرحمن'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.text('ذو الرحمة الواسعة'), findsOneWidget);
  });
}
