import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/features/azkar/data/azkar_repository.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_cubit.dart';
import 'package:quran_yahdi/features/azkar/presentation/azkar_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

Map<String, dynamic> fixtureRoot() => {
      'collections': [
        {
          'id': 'c1',
          'nameAr': 'أذكار الصباح',
          'nameEn': 'Morning',
          'items': [
            {'text': 'ذِكْرٌ لَهُ ثَلَاثٌ', 'count': 3},
            {'text': 'ذِكْرٌ وَاحِدٌ'},
          ],
        },
      ],
    };

void main() {
  testWidgets('reciting taps fire selection haptics; done and browsing do not',
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

    final cubit = AzkarCubit(
      repository: AzkarRepository(loader: () async => fixtureRoot()),
    );
    addTearDown(cubit.close);
    await cubit.start();
    await tester.pumpWidget(BlocProvider<AzkarCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: const AzkarScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('أذكار الصباح'));
    await tester.pumpAndSettle();
    expect(haptics, isEmpty);

    await tester.tap(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'));
    await tester.pumpAndSettle();
    expect(haptics, hasLength(1));
    expect(haptics.single.arguments, 'HapticFeedbackType.selectionClick');

    await tester.tap(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'));
    await tester.pumpAndSettle();
    expect(haptics, hasLength(3));
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('ذِكْرٌ لَهُ ثَلَاثٌ'));
    await tester.pumpAndSettle();
    expect(haptics, hasLength(3));
  });
}
