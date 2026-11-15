import 'dart:ui' show Tristate;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/adhan_catalog.dart';
import 'package:quran_yahdi/core/domain/adhan_player.dart';
import 'package:quran_yahdi/core/domain/adhan_preferences.dart';
import 'package:quran_yahdi/features/settings/presentation/adhan_picker_cubit.dart';
import 'package:quran_yahdi/features/settings/presentation/adhan_picker_screen.dart';

import 'support/host.dart';

class _FakePreferences implements AdhanPreferences {
  _FakePreferences(this._id);

  String _id;

  @override
  Future<String> adhanId() async => _id;

  @override
  Future<String?> fajrAdhanId() async => null;

  @override
  Future<void> setAdhanId(String id) async => _id = id;

  @override
  Future<void> setFajrAdhanId(String? id) async {}
}

class _SilentPlayer implements AdhanPlayer {
  @override
  Future<void> play(String trackId) async {}

  @override
  Future<void> preview(String trackId) async {}

  @override
  Future<void> stop() async {}

  @override
  Stream<AdhanPlaybackState> get state =>
      const Stream<AdhanPlaybackState>.empty();
}

void main() {
  testWidgets('the selected adhan row announces that it is selected',
      (tester) async {
    final track = kAdhanCatalog.first;
    final cubit = AdhanPickerCubit(
      prefs: _FakePreferences(track.id),
      player: _SilentPlayer(),
      reschedule: () async {},
    );
    addTearDown(cubit.close);
    await cubit.start();

    await pumpAppHost(
      tester,
      home: const AdhanPickerScreen(),
      wrap: (app) => BlocProvider<AdhanPickerCubit>.value(
        value: cubit,
        child: app,
      ),
    );

    final semantics = tester.ensureSemantics();
    // The trailing tick is the only visual selection indicator; assistive tech
    // needs the state on the row itself.
    final row =
        tester.getSemantics(find.text(track.nameAr).first).getSemanticsData();
    semantics.dispose();

    expect(row.flagsCollection.isSelected, Tristate.isTrue,
        reason: 'a tick icon is not announced; the row must expose selection');
  });
}
