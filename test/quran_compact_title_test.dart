import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/quran/data/surah_repository.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/surah_index_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

/// The compact index title is part of the frozen compact behaviour: the
/// workspace wave must not rename it while extracting the body.
void main() {
  testWidgets('the compact surah index keeps its English title',
      (tester) async {
    final db = newTestDb();
    addTearDown(db.close);
    final cubit = SurahIndexCubit(SurahRepository(db));
    addTearDown(cubit.close);
    await cubit.start();

    await pumpAppHost(
      tester,
      locale: const Locale('en'),
      home: BlocProvider<SurahIndexCubit>.value(
        value: cubit,
        child: const SurahIndexScreen(),
      ),
    );

    expect(find.text('The Noble Quran'), findsOneWidget);
    expect(find.text('Quran'), findsNothing);
  });
}
