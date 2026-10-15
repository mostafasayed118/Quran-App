import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Widget host(ReciterRepository repo) => BlocProvider<RecitersCubit>(
        create: (_) => RecitersCubit(repo: repo),
        child: const RecitersScreen(),
      );

  Future<void> pumpHost(WidgetTester tester, List<ReciterRow> rows) async {
    final repo = _StaticReciterRepository(db, rows);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: host(repo),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('featured row appears first (lower Y), then the rest',
      (tester) async {
    await pumpHost(tester, [
      _row(id: '55-55', name: 'تجربة أحمد'),
      _row(id: '123-123', name: 'مشاري العفاسي'),
      _row(id: '51-53', name: 'عبدالباسط عبدالصمد'),
    ]);

    final basit = tester.getTopLeft(find.text('عبدالباسط عبدالصمد'));
    final afassy = tester.getTopLeft(find.text('مشاري العفاسي'));
    final other = tester.getTopLeft(find.text('تجربة أحمد'));
    expect(basit.dy, lessThan(afassy.dy));
    expect(basit.dy, lessThan(other.dy));
    expect(find.text('مختارات'), findsOneWidget);
  });

  testWidgets('search field narrows to 1 row', (tester) async {
    await pumpHost(tester, [
      _row(id: '55-55', name: 'تجربة أحمد'),
      _row(id: '123-123', name: 'مشاري العفاسي'),
      _row(id: '51-53', name: 'عبدالباسط عبدالصمد'),
    ]);

    await tester.enterText(find.byType(TextField), 'عفاسي');
    await tester.pumpAndSettle();

    expect(find.text('مشاري العفاسي'), findsOneWidget);
    expect(find.text('عبدالباسط عبدالصمد'), findsNothing);
    expect(find.text('تجربة أحمد'), findsNothing);
  });

  testWidgets('empty index shows the offline hint, never a dead screen',
      (tester) async {
    await pumpHost(tester, const []);

    expect(find.text('حمّل فهرس القرّاء من الإنترنت'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });
}

ReciterRow _row({required String id, required String name}) => ReciterRow(
      id: id,
      reciterName: name,
      moshafName: 'مرتل',
      server: 'https://x/',
      surahList: '1',
      surahTotal: 114,
    );

class _StaticReciterRepository extends ReciterRepository {
  _StaticReciterRepository(super.db, this._rows);

  final List<ReciterRow> _rows;

  @override
  Stream<List<ReciterRow>> watchAll() => Stream.value(_rows);

  @override
  Future<void> refreshFromApi() async {}
}
