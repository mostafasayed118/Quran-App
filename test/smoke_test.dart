import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/app/app.dart';

void main() {
  testWidgets('app boots without throwing', (tester) async {
    await tester.pumpWidget(const QuranYahdiApp());
    expect(find.byType(QuranYahdiApp), findsOneWidget);
  });
}
