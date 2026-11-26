import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/utils/pager_icons.dart';

void main() {
  test('the next chevron is the logical chevron_right', () {
    expect(pagerChevronFor(next: true), Icons.chevron_right);
  });

  test('the previous chevron is the logical chevron_left', () {
    expect(pagerChevronFor(next: false), Icons.chevron_left);
  });
}
