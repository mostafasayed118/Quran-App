import 'package:flutter_test/flutter_test.dart';
import 'package:quran_yahdi/core/domain/app_locale.dart';
import 'package:quran_yahdi/core/l10n/app_locale_controller.dart';

class _Source implements AppLocaleSource {
  _Source({this.language = AppLanguage.arabic});

  AppLanguage language;
  bool throwOnLoad = false;
  bool throwOnSave = false;
  int saves = 0;

  @override
  Future<AppLanguage> load() async {
    if (throwOnLoad) throw StateError('load');
    return language;
  }

  @override
  Future<void> save(AppLanguage value) async {
    if (throwOnSave) throw StateError('save');
    saves++;
    language = value;
  }
}

void main() {
  test('Arabic until the stored value lands', () async {
    final source = _Source(language: AppLanguage.english);
    final controller = AppLocaleController(source);

    expect(controller.language, AppLanguage.arabic);
    expect(controller.locale.languageCode, 'ar');
    expect(controller.loaded, isFalse);

    await controller.load();

    expect(controller.loaded, isTrue);
    expect(controller.language, AppLanguage.english);
    expect(controller.locale.languageCode, 'en');
  });

  test('a failing read keeps Arabic', () async {
    final controller = AppLocaleController(_Source()..throwOnLoad = true);

    await controller.load();

    expect(controller.language, AppLanguage.arabic);
    expect(controller.loaded, isTrue);
  });

  test('switching notifies once and persists', () async {
    final source = _Source();
    final controller = AppLocaleController(source);
    await controller.load();
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setLanguage(AppLanguage.english);

    expect(controller.locale.languageCode, 'en');
    expect(source.saves, 1);
    expect(source.language, AppLanguage.english);
    expect(notifications, 1);

    // Selecting the current language is a no-op.
    await controller.setLanguage(AppLanguage.english);
    expect(notifications, 1);
  });

  test('a failing write still switches for this session', () async {
    final source = _Source()..throwOnSave = true;
    final controller = AppLocaleController(source);
    await controller.load();

    await controller.setLanguage(AppLanguage.english);

    expect(controller.language, AppLanguage.english);
  });

  test('the app advertises both shipped locales', () {
    expect(kSupportedLocales.map((l) => l.languageCode), ['ar', 'en']);
  });
}
