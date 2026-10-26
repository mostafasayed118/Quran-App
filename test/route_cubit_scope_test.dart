import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/route_cubit_scope.dart';

class _FakeCubit extends Cubit<int> {
  _FakeCubit(this.id) : super(0);

  final int id;
  bool closed = false;

  @override
  Future<void> close() {
    closed = true;
    return super.close();
  }
}

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// The cubit the mounted scope is currently providing.
_FakeCubit _provided(WidgetTester tester) =>
    BlocProvider.of<_FakeCubit>(tester.element(find.byType(_Probe)));

class _Harness extends StatelessWidget {
  const _Harness({
    required this.identity,
    required this.cubits,
    required this.started,
  });

  final Object identity;
  final List<_FakeCubit> cubits;
  final List<int> started;

  @override
  Widget build(BuildContext context) {
    return RouteCubitScope<_FakeCubit>(
      identity: identity,
      create: () {
        final cubit = _FakeCubit(cubits.length);
        cubits.add(cubit);
        return cubit;
      },
      start: (cubit) async => started.add(cubit.id),
      child: const _Probe(),
    );
  }
}

Widget _app(Object identity, List<_FakeCubit> cubits, List<int> started) =>
    MaterialApp(
      home: _Harness(identity: identity, cubits: cubits, started: started),
    );

void main() {
  testWidgets('creates and starts the cubit exactly once', (tester) async {
    final cubits = <_FakeCubit>[];
    final started = <int>[];

    await tester.pumpWidget(_app('route', cubits, started));
    expect(cubits, hasLength(1));
    expect(started, [0]);
    expect(_provided(tester).id, 0);

    await tester.pumpWidget(_app('route', cubits, started));
    await tester.pump();

    expect(cubits, hasLength(1), reason: 'a rebuild must not remount');
    expect(started, [0], reason: 'start must stay one-shot per cubit');
  });

  testWidgets('a changed identity closes the old cubit and mounts a new one',
      (tester) async {
    final cubits = <_FakeCubit>[];
    final started = <int>[];

    await tester.pumpWidget(_app('surah:1', cubits, started));
    await tester.pumpWidget(_app('surah:2', cubits, started));
    await tester.pump();

    expect(cubits, hasLength(2));
    expect(cubits.first.closed, isTrue, reason: 'stale cubit must be closed');
    expect(cubits.last.closed, isFalse);
    expect(started, [0, 1]);
    expect(_provided(tester).id, 1);
    expect(cubits.last, same(_provided(tester)));
  });

  testWidgets('unmounting the scope closes the cubit', (tester) async {
    final cubits = <_FakeCubit>[];
    final started = <int>[];

    await tester.pumpWidget(_app('route', cubits, started));
    expect(cubits.single.closed, isFalse);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    expect(cubits.single.closed, isTrue);
  });
}
