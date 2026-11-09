import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/ramadan/data/qada_source.dart';
import 'package:quran_yahdi/features/ramadan/presentation/qada_cubit.dart';
import 'package:quran_yahdi/features/ramadan/presentation/qada_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

class _Source implements QadaSource {
  _Source(this.dates);

  List<DateTime> dates;

  @override
  Future<List<DateTime>> loadMissed() async => dates;

  @override
  Future<void> saveMissed(List<DateTime> next) async {
    dates = next;
  }
}

Widget _app(QadaCubit cubit) => BlocProvider.value(
      value: cubit,
      child: const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: QadaScreen(),
      ),
    );

void main() {
  testWidgets('renders the count and one row per recorded day', (tester) async {
    final cubit = QadaCubit(
      source: _Source([DateTime(2027, 3, 1), DateTime(2027, 3, 2)]),
    );
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(find.text('قضاء الصيام'), findsOneWidget);
    expect(find.text('٢ يوم مسجّل'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('an empty set renders the empty state', (tester) async {
    final cubit = QadaCubit(source: _Source([]));
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    expect(find.text('لا توجد أيام مسجلة'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('deleting a day confirms and removes it', (tester) async {
    final source = _Source([DateTime(2027, 3, 1), DateTime(2027, 3, 2)]);
    final cubit = QadaCubit(source: source);
    addTearDown(cubit.close);
    await cubit.start();

    await tester.pumpWidget(_app(cubit));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    expect(find.text('حذف اليوم؟'), findsOneWidget);

    await tester.tap(find.text('حذف').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.byType(ListTile), findsOneWidget);
    expect(source.dates, hasLength(1));
  });
}
