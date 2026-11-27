import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/feelings/presentation/feeling_label.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

/// M5 (audit round 2): the triplicated feeling-key switch is now one helper;
/// it must return exactly the localized name the old switches returned.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the single helper maps every feeling key to its localized name',
    () async {
      final loc = await AppLocalizations.delegate.load(const Locale('ar'));

      const expected = <String, String>{
        'qalaq': '',
        'huzn': '',
        'wahda': '',
        'hayra': '',
        'khawf': '',
        'ghadab': '',
        'imtinam': '',
        'amal': '',
      };
      expect(
        {for (final key in expected.keys) key: feelingLabel(loc, key)},
        {
          'qalaq': loc.feelingQalaq,
          'huzn': loc.feelingHuzn,
          'wahda': loc.feelingWahda,
          'hayra': loc.feelingHayra,
          'khawf': loc.feelingKhawf,
          'ghadab': loc.feelingGhadab,
          'imtinam': loc.feelingImtinam,
          'amal': loc.feelingAmal,
        },
      );
      expect(feelingLabel(loc, 'unknown'), loc.feelingAmal);
    },
  );
}
