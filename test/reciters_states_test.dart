import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/widgets/error_strip.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_screen.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_state.dart';

import 'support/host.dart';

class _StaticReciterRepository extends ReciterRepository {
  _StaticReciterRepository(super.db, this._rows);

  final List<ReciterRow> _rows;
  int refreshCalls = 0;
  Object? refreshError;

  @override
  Stream<List<ReciterRow>> watchAll() => Stream.value(_rows);

  @override
  Future<void> refreshFromApi() async {
    refreshCalls += 1;
    final error = refreshError;
    if (error != null) throw error;
  }
}

ReciterRow _row({required String id, required String name}) => ReciterRow(
      id: id,
      reciterName: name,
      moshafName: 'مرتل',
      server: 'https://x/',
      surahList: '1',
      surahTotal: 114,
    );

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<void> pumpScreen(WidgetTester tester, ReciterRepository repo) async {
    await pumpAppHost(
      tester,
      home: BlocProvider<RecitersCubit>(
        create: (_) => RecitersCubit(repo: repo),
        child: const RecitersScreen(),
      ),
    );
  }

  test('soft refresh failure raises the flag and keeps the cached list',
      () async {
    final repo =
        _StaticReciterRepository(db, [_row(id: '51-53', name: 'عبدالباسط')])
          ..refreshError = StateError('mp3quran HTTP 502');
    final cubit = RecitersCubit(repo: repo);
    addTearDown(cubit.close);

    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<RecitersReady>());
    expect((cubit.state as RecitersReady).dataError, isFalse);

    await cubit.refresh();

    final ready = cubit.state as RecitersReady;
    expect(ready.dataError, isTrue);
    expect(ready.reciters, hasLength(1));
    expect(repo.refreshCalls, 1);
  });

  testWidgets('refresh failure shows localized copy, never the raw exception',
      (tester) async {
    final repo =
        _StaticReciterRepository(db, [_row(id: '51-53', name: 'عبدالباسط')])
          ..refreshError = StateError('mp3quran HTTP 502');
    await pumpScreen(tester, repo);

    await tester.tap(find.byTooltip('تحديث'));
    await tester.pumpAndSettle();

    expect(find.text('تعذّر تحديث قائمة القرّاء'), findsOneWidget);
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.textContaining('502'), findsNothing);

    final dismiss = find.descendant(
      of: find.byType(ErrorStrip),
      matching: find.byType(IconButton),
    );
    await tester.tap(dismiss);
    await tester.pumpAndSettle();

    expect(find.text('تعذّر تحديث قائمة القرّاء'), findsNothing);
  });

  testWidgets('search with no matches shows the no-results copy',
      (tester) async {
    final repo =
        _StaticReciterRepository(db, [_row(id: '51-53', name: 'عبدالباسط')]);
    await pumpScreen(tester, repo);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('لا نتائج مطابقة'), findsOneWidget);
    expect(find.text('حمّل فهرس القرّاء من الإنترنت'), findsNothing);
  });
}
