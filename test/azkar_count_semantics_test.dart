import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_screen.dart';

import 'support/host.dart';

Map<String, dynamic> _fixture() => {
  'collections': [
    {
      'id': 'c1',
      'nameAr': 'أذكار الصباح',
      'nameEn': 'Morning',
      'items': [
        {'text': 'ذِكْرٌ لَهُ ثَلَاثٌ', 'count': 3},
      ],
    },
  ],
};

void main() {
  testWidgets(
    'the remaining count is announced with meaning, not as a bare digit',
    (tester) async {
      final cubit = AzkarCubit(
        repository: AzkarRepository(loader: () async => _fixture()),
      );
      addTearDown(cubit.close);
      await cubit.start();

      await pumpAppHost(
        tester,
        home: const AzkarScreen(),
        wrap: (app) => BlocProvider<AzkarCubit>.value(value: cubit, child: app),
      );

      await tester.tap(find.text('أذكار الصباح'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 10),
      );

      final semantics = tester.ensureSemantics();
      // The badge is a bare numeral inside the card's merged label; a screen
      // reader reads "٣" with no unit and no meaning.
      final label = tester.getSemantics(find.text('ذِكْرٌ لَهُ ثَلَاثٌ')).label;
      semantics.dispose();

      expect(
        label,
        contains('باقي ٣'),
        reason: 'the count needs its own label inside the row announcement',
      );
    },
  );
}
