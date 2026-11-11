import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/hijri/data/hijri_offset_source.dart';
import 'package:quran_yahdi/features/hijri/data/hijri_service.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_cubit.dart';
import 'package:quran_yahdi/features/hijri/presentation/hijri_state.dart';

class _Offset implements HijriOffsetSource {
  int value = 0;

  @override
  Future<int> loadOffsetDays() async => value;

  @override
  Future<void> saveOffsetDays(int days) async {
    value = days;
  }
}

void main() {
  test('start applies the saved offset before the first render', () async {
    final offset = _Offset()..value = 1;
    final service = HijriService();
    final cubit = HijriCubit(service: service, offset: offset);
    addTearDown(cubit.close);

    await cubit.start();

    expect(cubit.state, isA<HijriReady>());
    expect((cubit.state as HijriReady).dayOffset, 1);
    expect(service.offsetDays, 1);
  });

  test('setOffset persists, clamps and re-renders the open month', () async {
    final offset = _Offset();
    final service = HijriService();
    final cubit = HijriCubit(service: service, offset: offset);
    addTearDown(cubit.close);

    await cubit.start();
    final before = cubit.state as HijriReady;

    await cubit.setOffset(2);
    final after = cubit.state as HijriReady;
    expect(after.dayOffset, 2);
    expect(offset.value, 2);
    expect((after.month, after.year), (before.month, before.year));

    await cubit.setOffset(9);
    expect((cubit.state as HijriReady).dayOffset, HijriService.maxOffsetDays);
    expect(offset.value, HijriService.maxOffsetDays);

    await cubit.setOffset(-9);
    expect((cubit.state as HijriReady).dayOffset, HijriService.minOffsetDays);
    expect(offset.value, HijriService.minOffsetDays);
  });

  test('a throwing offset source degrades to zero', () async {
    final service = HijriService();
    final cubit = HijriCubit(service: service, offset: _ThrowingOffset());
    addTearDown(cubit.close);

    await cubit.start();

    expect(cubit.state, isA<HijriReady>());
    expect((cubit.state as HijriReady).dayOffset, 0);
  });

  test('a failed offset write leaves the applied offset unchanged', () async {
    final service = HijriService();
    final cubit = HijriCubit(service: service, offset: _ThrowingSave());
    addTearDown(cubit.close);

    await cubit.start();
    await cubit.setOffset(2);

    expect((cubit.state as HijriReady).dayOffset, 0);
    expect(service.offsetDays, 0);
  });
}

class _ThrowingSave implements HijriOffsetSource {
  @override
  Future<int> loadOffsetDays() async => 0;

  @override
  Future<void> saveOffsetDays(int days) async {
    throw StateError('disk full');
  }
}

class _ThrowingOffset implements HijriOffsetSource {
  @override
  Future<int> loadOffsetDays() async => throw StateError('corrupt row');

  @override
  Future<void> saveOffsetDays(int days) async {}
}
