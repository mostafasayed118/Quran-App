import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/app/splash_screen.dart';

import 'support/host.dart';

void main() {
  testWidgets('the splash stops scheduling frames once it has faded out',
      (tester) async {
    await tester.pumpWidget(
      appShell(home: const SplashScreen(child: SizedBox.expand())),
    );
    await tester.pump(SplashScreen.hold);
    await tester.pump(SplashScreen.fade);
    // One frame for the fade completion's setState, one to rebuild without the
    // overlay; after that nothing should ask for another frame.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.byType(IgnorePointer), findsWidgets,
        reason: 'sanity: the shell itself still uses IgnorePointer');
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'the splash overlay is gone, so its looping bar must not keep '
            'the ticker alive for the rest of the app lifetime');
  });
}
