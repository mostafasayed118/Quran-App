import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/tasbih/data/tasbih_repository.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_cubit.dart';
import 'package:quran_yahdi/features/tasbih/presentation/tasbih_screen.dart';

import 'support/host.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late TasbihRepository repo;

  setUp(() async {
    db = newTestDb();
    repo = TasbihRepository(db);
  });

  Future<TasbihCubit> pumpHost(WidgetTester tester) async {
    final cubit = TasbihCubit(repo: repo);
    addTearDown(cubit.close);
    await pumpAppHost(
      tester,
      wrap: (app) => BlocProvider<TasbihCubit>.value(value: cubit, child: app),
      home: const TasbihScreen(),
    );
    return cubit;
  }

  testWidgets('the dial is circular ink that keeps the tap-up haptic',
      (tester) async {
    final haptics = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpHost(tester);

    final ink = tester.widget<InkWell>(find.byKey(const Key('tasbih_dial')));
    expect(ink.customBorder, isA<CircleBorder>());
    expect(ink.onTap, isNotNull);
    final circleMaterials = tester.widgetList<Material>(find.byWidgetPredicate(
      (widget) => widget is Material && widget.shape is CircleBorder,
    ));
    expect(circleMaterials, hasLength(1));

    await tester.tap(find.byKey(const Key('tasbih_dial')));
    await tester.pump();

    expect(haptics, hasLength(1));
    expect(haptics.single.arguments, 'HapticFeedbackType.selectionClick');
    expect(find.text('١'), findsOneWidget);
  });
}
