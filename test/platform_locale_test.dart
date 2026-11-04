import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/app_locale.dart';
import 'package:quran_yahdi/core/l10n/app_locale_controller.dart';
import 'package:quran_yahdi/core/l10n/platform_localizations.dart';

class _Source implements AppLocaleSource {
  _Source({this.language = AppLanguage.arabic});

  AppLanguage language;

  @override
  Future<AppLanguage> load() async => language;

  @override
  Future<void> save(AppLanguage value) async {
    language = value;
  }
}

void main() {
  tearDown(() => platformLanguage = AppLanguage.arabic);

  test('outside-the-tree copy defaults to Arabic', () {
    expect(platformLanguage, AppLanguage.arabic);
    expect(platformLocalizations().settings, 'الإعدادات');
  });

  test('the controller publishes the loaded language before the first frame',
      () async {
    final controller =
        AppLocaleController(_Source(language: AppLanguage.english));

    await controller.load();

    expect(platformLanguage, AppLanguage.english);
    expect(platformLocalizations().settings, 'Settings');
  });

  test('switching the language switches the notification copy', () async {
    final controller = AppLocaleController(_Source());
    await controller.load();
    expect(platformLocalizations().reminderAzkar, 'أذكار الصباح');

    await controller.setLanguage(AppLanguage.english);

    expect(platformLanguage, AppLanguage.english);
    expect(platformLocalizations().reminderAzkar, 'Morning azkar');
    expect(platformLocalizations().settings, 'Settings');
  });

  test('switching back restores Arabic copy', () async {
    final controller = AppLocaleController(_Source());
    await controller.load();
    await controller.setLanguage(AppLanguage.english);
    await controller.setLanguage(AppLanguage.arabic);

    expect(platformLanguage, AppLanguage.arabic);
    expect(platformLocalizations().settings, 'الإعدادات');
  });

  test('the platform locale is a real, loadable bundle', () {
    for (final language in AppLanguage.values) {
      platformLanguage = language;
      expect(
        platformLocalizations().appName,
        isNotEmpty,
        reason: '${language.code} must resolve to a localization bundle',
      );
      expect(
        platformLocalizations().settings,
        isNotEmpty,
        reason: '${language.code} must carry the settings label',
      );
    }
  });
}
