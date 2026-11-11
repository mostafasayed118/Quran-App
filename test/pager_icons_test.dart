import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/utils/pager_icons.dart';

void main() {
  test('the next chevron points left in RTL and right in LTR', () {
    expect(pagerChevronFor(TextDirection.rtl, next: true), Icons.chevron_left);
    expect(pagerChevronFor(TextDirection.ltr, next: true), Icons.chevron_right);
  });

  test('the previous chevron is the mirror', () {
    expect(
        pagerChevronFor(TextDirection.rtl, next: false), Icons.chevron_right);
    expect(pagerChevronFor(TextDirection.ltr, next: false), Icons.chevron_left);
  });
}
