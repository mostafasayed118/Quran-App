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
  late TasbihCubit cubit;

  setUp(() async {
    db = newTestDb();
    cubit = TasbihCubit(repo: TasbihRepository(db));
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  Future<void> pump(WidgetTester tester, {double textScale = 1.0}) async {
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<TasbihCubit>.value(value: cubit, child: app),
      home: const TasbihScreen(),
      textScale: textScale,
    );
  }

  testWidgets('landscape 640x360 at textScale 2.0 does not overflow',
      (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('tasbih_dial')), findsOneWidget);
    expect(find.text('تصفير'), findsOneWidget);
  });

  testWidgets('the dial announces its label and count to screen readers',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await pump(tester);
      expect(find.bySemanticsLabel('السبحة'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });
}
