import 'package:flutter_test/flutter_test.dart';

import '../tools/design_token_scan.dart';
import 'fixtures/design_token_baseline.dart';

/// The ratchet for design literals.
///
/// The baseline is the census taken before the W1 wave (see
/// `test/fixtures/design_token_baseline.dart`). Every batch removes the
/// entries it fixed; the map must never grow. When the map is empty the wave
/// is done and any new literal fails here.
void main() {
  test('the residual-literal map only shrinks', () {
    final current = countViolations(scanLib());
    expect(
      current,
      designTokenBaseline,
      reason:
          'The tree and the recorded baseline disagree.\n'
          'Current: $current\n'
          'If this batch fixed sites, remove them from '
          'test/fixtures/design_token_baseline.dart. If it added a literal, '
          'move it into a token instead.',
    );
  });
}
