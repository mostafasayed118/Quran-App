import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/asma/data/asma_repository.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_cubit.dart';
import 'package:quran_yahdi/features/asma/presentation/asma_screen.dart';

import 'support/host.dart';

Future<void> pumpAsma(WidgetTester tester, AsmaRepository repository) async {
  final cubit = AsmaCubit(repository: repository);
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
  testWidgets('a loader crash shows the localized error pane, not a spinner',
      (tester) async {
    await pumpAsma(
      tester,
      AsmaRepository(loader: () async => throw StateError('boom')),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsOneWidget);
  });

  testWidgets('an empty dataset shows the empty state, not a blank body',
      (tester) async {
    await pumpAsma(
      tester,
      AsmaRepository(loader: () async => <Map<String, dynamic>>[]),
    );

    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
