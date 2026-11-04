import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/quran/data/juz_index_source.dart';
import 'package:quran_yahdi/features/quran/domain/juz_summary.dart';
import 'package:quran_yahdi/features/quran/presentation/index/juz_index_cubit.dart';
import 'package:quran_yahdi/features/quran/presentation/index/juz_index_screen.dart';

import 'support/host.dart';

class _EmptySource implements JuzIndexSource {
  const _EmptySource();

  @override
  Stream<List<JuzSummary>> watchJuz() => Stream.value(const []);
}

void main() {
  testWidgets('a successful empty juz index shows the no-results copy',
      (tester) async {
    final cubit = JuzIndexCubit(source: const _EmptySource());
    addTearDown(cubit.close);
    await cubit.start();

    await pumpAppHost(
      tester,
      home: BlocProvider<JuzIndexCubit>.value(
        value: cubit,
        child: const JuzIndexScreen(),
      ),
    );

    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
    expect(find.text('عذرًا، حدث خطأ — حاول مرة أخرى'), findsNothing);
  });
}
