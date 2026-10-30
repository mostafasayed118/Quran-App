import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_colors.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_cubit.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_screen.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_cubit.dart';
import 'package:quran_yahdi/features/zakat/presentation/zakat_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  testWidgets('the zakat verdict uses the AA goldText tone', (tester) async {
    final cubit = ZakatCubit();
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<ZakatCubit>.value(value: cubit, child: app),
      home: const ZakatScreen(),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(3), '1');
    await tester.enterText(fields.at(4), '1000');
    await tester.pumpAndSettle();

    final verdict = tester.widget<Text>(find.text('الزكاة الواجبة'));
    expect(verdict.style?.color, AppColors.goldText);
  });

  testWidgets('the tasbih done copy uses the AA goldText tone', (tester) async {
    final db = newTestDb();
    addTearDown(db.close);
    final cubit = TasbihCubit(repo: TasbihRepository(db));
    addTearDown(cubit.close);
    await cubit.start();
    await cubit.selectTarget(33);
    for (var i = 0; i < 33; i++) {
      await cubit.increment();
    }

    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<TasbihCubit>.value(value: cubit, child: app),
      home: const TasbihScreen(),
    );

    final done = tester.widget<Text>(find.text('تم بحمد الله'));
    expect(done.style?.color, AppColors.goldText);
    expect(AppTheme.goldText(_contextOf(tester)), AppColors.goldText);
  });
}

BuildContext _contextOf(WidgetTester tester) =>
    tester.element(find.byType(TasbihScreen));
