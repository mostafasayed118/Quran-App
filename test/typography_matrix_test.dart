import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/theme/app_theme.dart';
import 'package:quran_yahdi/core/widgets/section_header.dart';
import 'package:quran_yahdi/core/widgets/service_tile.dart';

import 'support/type_probe.dart';

const _widths = [320.0, 360.0, 411.0];
const _scales = [1.0, 1.3, 2.0];

void main() {
  for (final width in _widths) {
    for (final scale in _scales) {
      final label = '${width.toInt()}dp x $scale';

      testWidgets('SectionHeader holds at $label', (tester) async {
        await pumpTypeProbe(
          tester,
          width: width,
          textScale: scale,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: SectionHeader(title: 'القرآن والاستماع'),
          ),
        );
        expectNoOverflow(tester);
        expectNotTruncated(tester, find.text('القرآن والاستماع'));
      });

      testWidgets('ServiceTile holds at $label', (tester) async {
        await pumpTypeProbe(
          tester,
          width: width,
          textScale: scale,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: (width - 40) / 2,
              child: ServiceTile(
                icon: Icons.book_outlined,
                label: 'مواقيت الصلاة',
                onTap: () {},
              ),
            ),
          ),
        );
        expectNoOverflow(tester);
        expectNotTruncated(tester, find.text('مواقيت الصلاة'));
        expectTapTargets(tester, find.byType(ServiceTile));
      });

      testWidgets('a reciter row holds at $label', (tester) async {
        await pumpTypeProbe(
          tester,
          width: width,
          textScale: scale,
          child: const ListTile(
            contentPadding: AppTheme.tileContentPadding,
            leading: CircleAvatar(radius: 20, child: Text('ع')),
            title: Text(
              'عبد الرحمن السديس',
              style: AppTheme.rowTitle,
            ),
            subtitle: Text('حفص عن عاصم'),
            trailing: Text('١١٤ سورة'),
          ),
        );
        expectNoOverflow(tester);
        expectNotTruncated(tester, find.text('عبد الرحمن السديس'));
      });
    }
  }
}
