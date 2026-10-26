import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/duas/data/dua_repository.dart';
import 'package:quran_yahdi/features/duas/data/ruqyah_repository.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_cubit.dart';
import 'package:quran_yahdi/features/duas/presentation/duas_screen.dart';
import 'package:quran_yahdi/features/quran/data/ayah_repository.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late DuaRepository duaRepo;
  late RuqyahRepository ruqyahRepo;

  setUp(() async {
    db = newTestDb();
    duaRepo = DuaRepository(
        loader: () async => [
              {
                'id': 'a1',
                'categoryAr': 'المنزل',
                'categoryEn': 'Home',
                'text': 'بِسْمِ اللَّهِ وَلَجْنَا',
              },
              {
                'id': 'a2',
                'categoryAr': 'السفر',
                'categoryEn': 'Travel',
                'text': 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا',
              },
            ]);
    ruqyahRepo = RuqyahRepository(
        loader: () async => [
              {
                'id': 'r1',
                'kind': 'dhikr',
                'text': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ',
                'count': 3
              },
            ]);
  });

  Future<void> pumpHost(WidgetTester tester, {double textScale = 1.0}) async {
    final cubit = DuasCubit(
      duas: duaRepo,
      ruqyah: ruqyahRepo,
      ayahs: AyahRepository(db),
    );
    addTearDown(cubit.close);
    await cubit.start();
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<DuasCubit>.value(value: cubit, child: app),
      home: const DuasScreen(),
      textScale: textScale,
    );
  }

  RenderBox chipBox(WidgetTester tester, String label) {
    final chip = find.ancestor(
      of: find.text(label),
      matching: find.byType(ChoiceChip),
    );
    return tester.renderObject<RenderBox>(chip.first);
  }

  testWidgets('category chips meet the measured 48 dp tap target (360 width)',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpHost(tester);

    for (final label in ['المنزل', 'السفر']) {
      final size = chipBox(tester, label).size;
      expect(size.height, greaterThanOrEqualTo(48),
          reason: 'chip "$label" tap target height ${size.height} < 48');
      expect(size.width, greaterThanOrEqualTo(48),
          reason: 'chip "$label" tap target width ${size.width} < 48');
    }
  });

  testWidgets('category chips survive textScale 2.0 (no clipped labels)',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpHost(tester, textScale: 2.0);

    expect(tester.takeException(), isNull);
    for (final label in ['المنزل', 'السفر']) {
      final chip = chipBox(tester, label);
      final chipRect = chip.localToGlobal(Offset.zero) & chip.size;
      final labelBox = tester.renderObject<RenderBox>(find.text(label));
      final labelRect = labelBox.localToGlobal(Offset.zero) & labelBox.size;
      expect(chip.size.height, greaterThanOrEqualTo(48),
          reason: 'chip "$label" shrinks below 48 at textScale 2.0');
      expect(labelRect.top, greaterThanOrEqualTo(chipRect.top - 0.5),
          reason: 'label "$label" leaves its chip at the top');
      expect(labelRect.bottom, lessThanOrEqualTo(chipRect.bottom + 0.5),
          reason: 'label "$label" is clipped by its chip at textScale 2.0');
    }
  });
}
