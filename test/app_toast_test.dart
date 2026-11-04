import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/widgets/app_toast.dart';

import 'support/host.dart';

/// Two triggers so a test can prove the second toast replaces the first
/// instead of queueing behind it.
class _Probe extends StatelessWidget {
  const _Probe({this.onAction});

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => AppToast.show(
              context,
              'تم النسخ',
              tone: ToastTone.success,
            ),
            child: const Text('first'),
          ),
          TextButton(
            onPressed: () => AppToast.show(
              context,
              'تعذّر الحفظ',
              tone: ToastTone.error,
            ),
            child: const Text('second'),
          ),
          TextButton(
            onPressed: () => AppToast.show(
              context,
              'تم الحذف',
              tone: ToastTone.info,
              actionLabel: 'تراجع',
              onAction: onAction,
            ),
            child: const Text('with-action'),
          ),
        ],
      ),
    );
  }
}

/// Lets the 3–4 s auto-dismiss timer fire and the exit animation finish, so a
/// test never tears down with a pending snackbar timer.
Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a success toast shows the message and its tone icon',
      (tester) async {
    await pumpAppHost(tester, home: const _Probe());

    await tester.tap(find.text('first'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('تم النسخ'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    await _drain(tester);
  });

  testWidgets('an error toast uses the error icon', (tester) async {
    await pumpAppHost(tester, home: const _Probe());

    await tester.tap(find.text('second'));
    await tester.pump();

    expect(find.text('تعذّر الحفظ'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await _drain(tester);
  });

  testWidgets('a new toast replaces the visible one instead of stacking',
      (tester) async {
    await pumpAppHost(tester, home: const _Probe());

    await tester.tap(find.text('first'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('تم النسخ'), findsOneWidget);

    await tester.tap(find.text('second'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('تعذّر الحفظ'), findsOneWidget);
    expect(find.text('تم النسخ'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);

    await _drain(tester);
  });

  testWidgets('the action runs its callback', (tester) async {
    var undone = false;
    await pumpAppHost(tester, home: _Probe(onAction: () => undone = true));

    await tester.tap(find.text('with-action'));
    await tester.pump();
    // The entrance animation wraps the bar in an IgnorePointer until it ends;
    // a tap before that never reaches the action.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('تراجع'), findsOneWidget);

    await tester.tap(find.text('تراجع'));
    await tester.pump();

    expect(undone, isTrue);

    await _drain(tester);
  });
}
