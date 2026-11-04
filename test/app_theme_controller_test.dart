import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/domain/app_theme.dart';
import 'package:quran_yahdi/core/theme/app_theme_controller.dart';

class _Source implements AppThemeSource {
  _Source({this.mode = AppThemeMode.system});

  AppThemeMode mode;
  bool throwOnLoad = false;
  bool throwOnSave = false;
  int saves = 0;

  @override
  Future<AppThemeMode> load() async {
    if (throwOnLoad) throw StateError('load');
    return mode;
  }

  @override
  Future<void> save(AppThemeMode value) async {
    if (throwOnSave) throw StateError('save');
    saves++;
    mode = value;
  }
}

void main() {
  test('system until the stored value lands', () async {
    final source = _Source(mode: AppThemeMode.dark);
    final controller = AppThemeController(source);

    expect(controller.mode, AppThemeMode.system);
    expect(controller.themeMode, ThemeMode.system);
    expect(controller.loaded, isFalse);

    await controller.load();

    expect(controller.loaded, isTrue);
    expect(controller.mode, AppThemeMode.dark);
    expect(controller.themeMode, ThemeMode.dark);
  });

  test('a failing read keeps system', () async {
    final controller = AppThemeController(_Source()..throwOnLoad = true);

    await controller.load();

    expect(controller.mode, AppThemeMode.system);
    expect(controller.loaded, isTrue);
  });

  test('setting a mode notifies first and persists', () async {
    final source = _Source();
    final controller = AppThemeController(source);
    await controller.load();
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setMode(AppThemeMode.light);

    expect(controller.mode, AppThemeMode.light);
    expect(controller.themeMode, ThemeMode.light);
    expect(notifications, 1);
    expect(source.saves, 1);
    expect(await source.load(), AppThemeMode.light);
  });

  test('a failing write still applies the mode', () async {
    final controller = AppThemeController(_Source()..throwOnSave = true);
    await controller.load();

    await controller.setMode(AppThemeMode.dark);

    expect(controller.mode, AppThemeMode.dark);
    expect(controller.themeMode, ThemeMode.dark);
  });

  test('re-selecting the current mode does not write again', () async {
    final source = _Source(mode: AppThemeMode.light);
    final controller = AppThemeController(source);
    await controller.load();

    await controller.setMode(AppThemeMode.light);

    expect(source.saves, 0);
  });

  test('an unknown persisted code falls back to system', () {
    expect(AppThemeMode.fromCode('sepia'), AppThemeMode.system);
    expect(AppThemeMode.fromCode(null), AppThemeMode.system);
    expect(AppThemeMode.fromCode('dark'), AppThemeMode.dark);
    expect(AppThemeMode.fromCode('light'), AppThemeMode.light);
  });

  test('every mode maps to its ThemeMode', () async {
    const expected = <AppThemeMode, ThemeMode>{
      AppThemeMode.system: ThemeMode.system,
      AppThemeMode.light: ThemeMode.light,
      AppThemeMode.dark: ThemeMode.dark,
    };

    for (final entry in expected.entries) {
      final controller = AppThemeController(_Source(mode: entry.key));
      await controller.load();
      expect(controller.themeMode, entry.value, reason: '${entry.key}');
    }
  });
}
