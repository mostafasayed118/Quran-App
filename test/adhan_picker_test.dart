import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/adhan_player.dart';
import 'package:quran_yahdi/core/domain/adhan_preferences.dart';
import 'package:quran_yahdi/features/settings/presentation/adhan_picker_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/adhan_picker_screen.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import 'support/host.dart';

class _FakeAdhanPreferences implements AdhanPreferences {
  _FakeAdhanPreferences({String? adhanId, String? fajrId})
      : _id = adhanId ?? kDefaultAdhanId,
        _fajr = fajrId;

  String _id;
  String? _fajr;

  int writes = 0;

  @override
  Future<String> adhanId() async => _id;

  @override
  Future<String?> fajrAdhanId() async => _fajr;

  @override
  Future<void> setAdhanId(String id) async {
    _id = id;
    writes++;
  }

  @override
  Future<void> setFajrAdhanId(String? id) async {
    _fajr = id;
    writes++;
  }
}

class _FakeAdhanPlayer implements AdhanPlayer {
  final List<String> calls = <String>[];
  int stopCalls = 0;

  int get previews => calls.where((c) => c.startsWith('preview:')).length;

  @override
  Future<void> play(String trackId) async => calls.add('play:$trackId');

  @override
  Future<void> preview(String trackId) async => calls.add('preview:$trackId');

  @override
  Future<void> stop() async {
    stopCalls++;
    calls.add('stop');
  }

  @override
  Stream<AdhanPlaybackState> get state =>
      const Stream<AdhanPlaybackState>.empty();
}

void main() {
  late _FakeAdhanPreferences prefs;
  late _FakeAdhanPlayer player;
  late int reschedules;
  late AdhanPickerCubit cubit;

  Future<void> setUpCubit({
    String? adhanId,
    String? fajrId,
  }) async {
    prefs = _FakeAdhanPreferences(adhanId: adhanId, fajrId: fajrId);
    player = _FakeAdhanPlayer();
    reschedules = 0;
    cubit = AdhanPickerCubit(
      prefs: prefs,
      player: player,
      reschedule: () async {
        reschedules++;
      },
    );
    addTearDown(cubit.close);
    await cubit.start();
  }

  Future<void> pumpPicker(WidgetTester tester) async {
    // Both sections are long enough that a default 800x600 surface leaves the
    // Fajr list unmounted, and an unmounted row cannot be found or tapped.
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpAppHost(
      tester,
      home: const AdhanPickerScreen(),
      wrap: (app) => BlocProvider<AdhanPickerCubit>.value(
        value: cubit,
        child: app,
      ),
    );
  }

  testWidgets('renders every reciter in both sections', (tester) async {
    await setUpCubit();
    await pumpPicker(tester);

    final loc = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    // Each reciter appears once in the global list and once in the Fajr list.
    for (final track in kAdhanCatalog) {
      expect(find.text(track.nameAr), findsNWidgets(2), reason: track.id);
    }
    expect(find.text(loc.adhanSameAsDefault), findsOneWidget);
  });

  testWidgets('marks the stored global choice and "same as default" for Fajr',
      (tester) async {
    await setUpCubit(adhanId: 'omar_hisham');
    await pumpPicker(tester);

    // One tick on the global omar row, one on the "same as default" row.
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
  });

  testWidgets('tapping a row persists the choice and re-plans', (tester) async {
    await setUpCubit();
    await pumpPicker(tester);

    await tester.tap(find.text('عمر هشام العربي').first);
    await tester.pumpAndSettle();

    expect(await prefs.adhanId(), 'omar_hisham');
    expect(reschedules, 1);
  });

  testWidgets('choosing "same as default" clears the Fajr override',
      (tester) async {
    await setUpCubit(fajrId: 'khushu');
    await pumpPicker(tester);

    final loc = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    await tester.tap(find.text(loc.adhanSameAsDefault));
    await tester.pumpAndSettle();

    expect(await prefs.fajrAdhanId(), isNull);
    expect(reschedules, 1);
  });

  testWidgets('preview plays the clip and a second tap stops it',
      (tester) async {
    await setUpCubit();
    await pumpPicker(tester);

    final previewButton = find.byIcon(Icons.play_circle_outline).first;
    await tester.tap(previewButton);
    await tester.pumpAndSettle();
    expect(player.previews, 1);

    // The same row now offers "stop".
    await tester.tap(find.byIcon(Icons.stop_circle_outlined).first);
    await tester.pumpAndSettle();
    expect(player.stopCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('tapping a second row replaces the first preview',
      (tester) async {
    await setUpCubit();
    await pumpPicker(tester);

    await tester.tap(find.byIcon(Icons.play_circle_outline).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_circle_outline).at(0));
    await tester.pumpAndSettle();

    // Two previews, but the first was stopped before the second started.
    expect(player.previews, 2);
    expect(player.stopCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('disposing the screen stops an active preview', (tester) async {
    await setUpCubit();
    await pumpPicker(tester);

    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pumpAndSettle();
    final before = player.stopCalls;

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(player.stopCalls, greaterThan(before));
  });

  testWidgets('selecting a row stops an active preview', (tester) async {
    // Spec section 7: preview must stop on selection change, otherwise the old
    // reciter keeps singing under the newly ticked row.
    await setUpCubit();
    await pumpPicker(tester);

    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pumpAndSettle();
    final before = player.stopCalls;

    await tester.tap(find.text('عمر هشام العربي').first);
    await tester.pumpAndSettle();

    expect(player.stopCalls, greaterThan(before));
    expect(await prefs.adhanId(), 'omar_hisham');
  });
}
