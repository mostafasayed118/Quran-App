import 'package:flutter_test/flutter_test.dart';

import '../tools/design_token_scan.dart';

/// Proves the scanner sees every literal form the guard claims to cover,
/// including the multi-line and `copyWith` cases a line regex would miss.
void main() {
  test('flags the literal forms the guard must see', () {
    const source = '''
const a = Color(0xFF112233);
const b = color.withValues(alpha: .4);
final c = const TextStyle(fontFamily: 'Cairo', height: 1.7);
final d = style.copyWith(height: 1.2);
const e = StrutStyle(height: 2.0);
const f = Icon(Icons.check, size: 18);
final g = BorderRadius.circular(14);
final h = BorderSide(color: c, width: 1.5);
final i = color.withValues(alpha: dark ? .42 : .55);
final j = Opacity(opacity: done ? .8 : 1);
''';

    final hits = scanSource('lib/x.dart', source);
    expect(
      hits.map((hit) => '${hit.kind}:${hit.value}'),
      <String>[
        'hex:0xFF112233',
        'alpha:0.4',
        'lineHeight:1.7',
        'lineHeight:1.2',
        'lineHeight:2.0',
        'iconSize:18.0',
        'radius:14.0',
        'stroke:1.5',
        'alpha:0.42',
        'alpha:0.55',
        'opacity:0.8',
      ],
    );
  });

  test('allows token references and a transparent gradient stop', () {
    const source = '''
final a = bg.withValues(alpha: 0);
final b = const TextStyle(height: AppType.bodyHeight);
const c = Icon(Icons.check, size: AppIconSize.md);
final d = colors.primary.withValues(alpha: AppAlphas.chipTint);
final e = BorderRadius.circular(AppRadius.md);
final f = BorderSide(color: c, width: AppStrokes.emphasis);
final g = colors.primary.withValues(alpha: dark ? a : b);
final h = Opacity(opacity: AppAlphas.completedFade);
final i = Opacity(opacity: 1);
''';

    expect(scanSource('lib/x.dart', source), isEmpty);
  });
}
