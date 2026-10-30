import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_cubit.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_screen.dart';

import 'support/host.dart';

void main() {
  testWidgets('each Hijri day cell exposes a dual-calendar semantics label',
      (tester) async {
    final handle = tester.ensureSemantics();
    try {
      final cubit = HijriCubit(service: HijriService());
      addTearDown(cubit.close);
      await cubit.start();

      await pumpAppHost(
        tester,
        home: BlocProvider<HijriCubit>.value(
          value: cubit,
          child: const HijriScreen(),
        ),
      );

      expect(find.bySemanticsLabel(RegExp('هجري')), findsWidgets);
    } finally {
      handle.dispose();
    }
  });
}
