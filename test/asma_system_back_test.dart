import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/asma/data/asma_repository.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_cubit.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_screen.dart';

import 'asma_repository_test.dart' show fixtureRows;

import 'support/host.dart';

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
      child: appShell(home: const AsmaScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    await tester.tap(find.text('الرحيم'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    expect(find.text('النازل بالرحمة'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.text('النازل بالرحمة'), findsNothing);
    expect(find.text('الرحيم'), findsOneWidget);
  });
}
