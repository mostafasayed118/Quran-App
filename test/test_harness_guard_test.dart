import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Widget tests build the app through `test/support/host.dart` (`appShell` /
/// `pumpAppHost`) so locale, theme and the l10n delegates stay one decision.
///
/// These files still build a raw `MaterialApp`, and the list may only shrink:
/// migrating a file means deleting its entry here.
const _exempt = <String>{
  // Routed harness: the test owns the GoRouter and its route table.
  'test/app_shell_adaptive_test.dart',
  'test/app_shell_test.dart',
  'test/ayah_sheet_test.dart',
  'test/home_city_hint_test.dart',
  'test/home_shell_reentry_test.dart',
  'test/onboarding_boot_gate_test.dart',
  'test/onboarding_screen_test.dart',
  'test/optional_features_degrade_test.dart',
  'test/page_not_found_test.dart',
  'test/principles_screen_test.dart',
  'test/qibla_city_reload_test.dart',
  'test/quran_workspace_route_test.dart',
  'test/reader_route_params_test.dart',
  'test/reader_route_reentry_test.dart',
  'test/reciter_packs_screen_test.dart',
  'test/search_to_reader_navigation_test.dart',
  // Own MediaQuery builder, delegate list or extra MaterialApp arguments.
  'test/app_language_switch_test.dart',
  'test/asma_quality_probe_test.dart',
  'test/azkar_search_screen_test.dart',
  'test/azkar_textscale_probe_test.dart',
  'test/bookmarks_screen_test.dart',
  'test/city_picker_late_location_test.dart',
  'test/downloads_screen_header_test.dart',
  'test/english_locale_content_test.dart',
  'test/forbidden_windows_section_test.dart',
  'test/hijri_screen_test.dart',
  'test/home_quality_probe_test.dart',
  'test/home_refresh_on_return_test.dart',
  'test/library_screen_test.dart',
  'test/prayer_city_textscale_test.dart',
  'test/qada_screen_test.dart',
  'test/quran_core_quality_probe_test.dart',
  'test/quran_search_screen_test.dart',
  'test/ramadan_screen_test.dart',
  'test/recitation_textscale_test.dart',
  'test/splash_screen_test.dart',
  'test/tracker_quality_probe_test.dart',
  'test/translation_search_screen_test.dart',
  'test/verse_card_test.dart',
  'test/verse_share_sheet_test.dart',
  'test/zakat_quality_probe_test.dart',
};

final _rawApp = RegExp(r'MaterialApp\s*\(');
final _routedApp = RegExp(r'MaterialApp\.router\s*\(');

String _normalize(String path) => path.replaceAll(r'\', '/');

/// Every test source except the harness's own definition.
List<String> _sources() => Directory('test')
    .listSync(recursive: true)
    .whereType<File>()
    .map((file) => _normalize(file.path))
    .where((path) => path.endsWith('.dart'))
    .where((path) => path != 'test/support/host.dart')
    .toList();

bool _buildsRawApp(String path) {
  final source = File(path).readAsStringSync();
  return _rawApp.hasMatch(source) || _routedApp.hasMatch(source);
}

void main() {
  test('widget tests build the app through the shared harness', () {
    final offenders = _sources()
        .where(_buildsRawApp)
        .where((path) => !_exempt.contains(path))
        .toList();

    expect(
      offenders,
      isEmpty,
      reason: 'Use appShell/pumpAppHost from test/support/host.dart instead '
          'of a raw MaterialApp: ${offenders.join(', ')}',
    );
  });

  test('the harness allowlist has no stale entries', () {
    final stale = _exempt
        .where((path) => !File(path).existsSync() || !_buildsRawApp(path))
        .toList();

    expect(
      stale,
      isEmpty,
      reason: 'These files no longer build a raw MaterialApp; drop them from '
          '_exempt: ${stale.join(', ')}',
    );
  });
}
