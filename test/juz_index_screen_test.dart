import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/quran/data/juz_index_source.dart';
import 'package:quran_yahdi/features/quran/domain/juz_summary.dart';
import 'package:quran_yahdi/features/quran/presentation/index/juz_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/juz_index_screen.dart';

import 'support/host.dart';

class _Source implements JuzIndexSource {
  const _Source();

  @override
  Stream<List<JuzSummary>> watchJuz() => Stream.value(const [
        JuzSummary(
          juz: 1,
          firstPage: 1,
          surahId: 1,
          numberInSurah: 1,
          surahName: 'الفاتحة',
        ),
        JuzSummary(
          juz: 2,
          firstPage: 22,
          surahId: 2,
          numberInSurah: 142,
          surahName: 'البقرة',
        ),
      ]);
}

void main() {
  testWidgets('the juz index renders the derived starts', (tester) async {
    final cubit = JuzIndexCubit(source: const _Source());
    addTearDown(cubit.close);
    await cubit.start();

    await pumpAppHost(
      tester,
      home: BlocProvider<JuzIndexCubit>.value(
        value: cubit,
        child: const JuzIndexScreen(),
      ),
    );

    expect(find.text('فهرس الأجزاء'), findsOneWidget);
    expect(find.text('الجزء ١'), findsOneWidget);
    expect(find.text('الجزء ٢'), findsOneWidget);
    expect(find.textContaining('البقرة'), findsOneWidget);
  });
}
