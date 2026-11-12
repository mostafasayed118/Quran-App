import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_cubit.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_screen.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_state.dart';

import 'support/host.dart';

class _ThrowingHijriService extends HijriService {
  @override
  int daysInMonth(int hijriYear, int hijriMonth) =>
      throw StateError('hijri table unavailable');
}

void main() {
  test('a service throw emits HijriFailed instead of staying loading',
      () async {
    final cubit = HijriCubit(service: _ThrowingHijriService());
    addTearDown(cubit.close);

    await cubit.start();

    expect(cubit.state, isA<HijriFailed>());
  });

  testWidgets('the failed state renders the localized error pane',
      (tester) async {
    final cubit = HijriCubit(service: _ThrowingHijriService());
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(BlocProvider<HijriCubit>.value(
      value: cubit,
      child: appShell(home: const HijriScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsOneWidget);
  });
}
