import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/widgets/lifecycle_ticker.dart';

import 'support/host.dart';

/// Pumps the ticker inside the shared shell: no database is involved and the
/// tick count is the only observable under test.
Future<void> pumpTicker(WidgetTester tester) {
  return tester.pumpWidget(
    appShell(
        home: LifecycleTicker(builder: (context, tick) => Text('tick:$tick'))),
  );
}

void main() {
  // AppLifecycleState lives on the binding, so a test that parks the app in
  // the background has to put it back for the tests that follow.
  void restoreResumed(WidgetTester tester) {
    addTearDown(
      () => tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
  }

  testWidgets('inactive stops the ticker while frames still run',
      (tester) async {
    restoreResumed(tester);
    await pumpTicker(tester);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('tick:2'), findsOneWidget);

    // `inactive` keeps frames enabled (split screen, the app switcher), so the
    // text is real evidence: a tick that ran would have been painted.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('tick:2'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('tick:3'), findsOneWidget);
  });

  for (final state in [AppLifecycleState.paused, AppLifecycleState.hidden]) {
    testWidgets('$state freezes the tick count', (tester) async {
      restoreResumed(tester);
      await pumpTicker(tester);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('tick:2'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump(const Duration(seconds: 3));

      // Frames are disabled in both states, so nothing is painted while the
      // timer would have run; the first frame after resume is the proof. A
      // ticker that ignored the state would come back on tick:5.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('tick:2'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('tick:3'), findsOneWidget);
    });
  }

  testWidgets('a ticker mounted while the app is inactive starts no timer',
      (tester) async {
    // Frames still run in `inactive`, so this is the mount-while-backgrounded
    // case the initState guard exists for. It cannot be written against
    // `paused`: frames are disabled there, so no widget ever mounts.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    restoreResumed(tester);

    await pumpTicker(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('tick:0'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('tick:1'), findsOneWidget);
  });

  testWidgets('disposing the ticker cancels the periodic timer',
      (tester) async {
    await pumpTicker(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('tick:1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    // A timer left behind would trip the binding's pending-timer check when
    // the test ends; walking two intervals past the disposal proves it is gone.
    await tester.pump(const Duration(seconds: 2));
  });
}
