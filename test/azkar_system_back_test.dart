import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_screen.dart';

import 'azkar_screen_test.dart' show fixtureRoot;

import 'support/host.dart';

void main() {
  testWidgets('system back leaves the reciting view without leaving Azkar',
      (tester) async {
    final cubit = AzkarCubit(
      repository: AzkarRepository(loader: () async => fixtureRoot()),
    );
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(BlocProvider<AzkarCubit>.value(
      value: cubit,
      child: appShell(home: const AzkarScreen()),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
    expect(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));

    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'), findsNothing);
  });
}
