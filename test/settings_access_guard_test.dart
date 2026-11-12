import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Files that may name `settingsTable` directly.
///
/// Every settings-backed repository goes through [SettingsStore]; the pin is
/// what keeps a new feature from quietly re-growing the twenty hand-rolled
/// select/insert pairs this wave removed. Adding an entry is a decision, not a
/// convenience.
const Map<String, String> rawSettingsAccessAllowlist = {
  'lib/core/db/app_database.dart': 'registers the table on the database',
  'lib/core/db/search_index.dart':
      'the index builder reads the content-version row while rewriting the '
          'FTS tables',
  'lib/core/db/settings_store.dart': 'the one access point',
  'lib/features/backup/data/backup_service.dart':
      'backup planner: reads the whitelist and writes inside a cross-table '
          'restore plan, not a settings repository',
};

final _settingsTableToken = RegExp(r'\bsettingsTable\b');

void main() {
  final hits = <String>{};
  for (final file
      in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    if (file.path.endsWith('.g.dart') || file.path.endsWith('.freezed.dart')) {
      continue;
    }
    if (!_settingsTableToken.hasMatch(file.readAsStringSync())) continue;
    hits.add(p.posix.joinAll(p.split(file.path)));
  }

  test('the scan actually reads the tree', () {
    expect(hits, isNotEmpty);
  });

  test('only the store (and the backup planner) touch settingsTable directly',
      () {
    final unpinned = hits
        .difference(rawSettingsAccessAllowlist.keys.toSet())
        .toList()
      ..sort();
    final stale = rawSettingsAccessAllowlist.keys
        .toSet()
        .difference(hits)
        .toList()
      ..sort();

    expect(rawSettingsAccessAllowlist.keys.toSet(), hits,
        reason: 'A settings read/write must go through SettingsStore '
            '(lib/core/db/settings_store.dart). Unpinned files: $unpinned. '
            'Stale entries to delete: $stale.');
  });
}
