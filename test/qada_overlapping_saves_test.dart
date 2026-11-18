import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/features/ramadan/data/qada_source.dart';
import 'package:quran_yahdi/features/ramadan/presentation/qada_cubit.dart';
import 'package:quran_yahdi/features/ramadan/presentation/qada_state.dart';

final DateTime _d1 = DateTime(2026, 3, 1);
final DateTime _d2 = DateTime(2026, 3, 2);

/// Every save returns a future the test completes by hand, so two writes can
/// be held in flight and finished in either order.
class _GatedSource implements QadaSource {
  List<DateTime> stored = const [];
  final List<List<DateTime>> calls = [];
  final List<Completer<void>> pending = [];

  @override
  Future<List<DateTime>> loadMissed() async => stored;

  @override
  Future<void> saveMissed(List<DateTime> dates) {
    calls.add(List<DateTime>.of(dates));
    final gate = Completer<void>();
    pending.add(gate);
    return gate.future.then((_) {
      stored = List<DateTime>.of(dates);
    });
  }

  void complete(int index) => pending[index].complete();

  void fail(int index) =>
      pending[index].completeError(StateError('save failed'));
}

Future<QadaCubit> _started(_GatedSource source) async {
  final cubit = QadaCubit(source: source);
  await cubit.start();
  return cubit;
}

void main() {
  test('overlapping saves are serialized and the newest state wins', () async {
    final source = _GatedSource();
    final cubit = await _started(source);
    addTearDown(cubit.close);

    final first = cubit.add(_d1);
    await Future<void>.delayed(Duration.zero);
    final second = cubit.add(_d2);
    await Future<void>.delayed(Duration.zero);

    expect(
      source.calls,
      hasLength(1),
      reason: 'the second write must wait for the first to settle',
    );

    source.complete(0);
    await Future<void>.delayed(Duration.zero);
    expect(source.calls, hasLength(2));
    source.complete(1);

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(source.stored, [_d1, _d2]);
    expect((cubit.state as QadaReady).dates, [_d1, _d2]);
  });

  test('a failed first save is not written over by the second', () async {
    final source = _GatedSource();
    final cubit = await _started(source);
    addTearDown(cubit.close);

    final first = cubit.add(_d1);
    await Future<void>.delayed(Duration.zero);
    final second = cubit.add(_d2);
    await Future<void>.delayed(Duration.zero);

    source.fail(0);
    await Future<void>.delayed(Duration.zero);
    source.complete(1);

    expect(await first, isFalse);
    expect(await second, isTrue);
    expect(source.stored, [
      _d2,
    ], reason: 'd1 was never stored, so it must not ride along in d2\'s write');
    expect((cubit.state as QadaReady).dates, [
      _d2,
    ], reason: 'the UI must show what is actually stored');
  });

  test('a failed second save reverts to the last stored state', () async {
    final source = _GatedSource();
    final cubit = await _started(source);
    addTearDown(cubit.close);

    final first = cubit.add(_d1);
    await Future<void>.delayed(Duration.zero);
    final second = cubit.add(_d2);
    await Future<void>.delayed(Duration.zero);

    source.complete(0);
    await Future<void>.delayed(Duration.zero);
    source.fail(1);

    expect(await first, isTrue);
    expect(await second, isFalse);
    expect(source.stored, [_d1]);
    expect((cubit.state as QadaReady).dates, [
      _d1,
    ], reason: 'the revert goes to the last confirmed state, not a snapshot');
  });
}
