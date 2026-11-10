import 'package:quran_yahdi/core/utils/app_log.dart';

import 'package:home_widget/home_widget.dart';

/// The data the Android home-screen widget renders.
abstract interface class HomeWidgetUpdater {
  /// Saves the next-prayer strings and refreshes the widget.
  Future<void> update({
    required String appName,
    required String label,
    required String prayer,
    required String time,
    required String city,
  });
}

/// The production bridge to `home_widget`.
///
/// [qualifiedAndroidName] is the fully qualified provider class: the debug
/// build has an `.debug` application id suffix, so the plugin's default
/// package-prefixed lookup would miss the provider.
class PlatformHomeWidgetUpdater implements HomeWidgetUpdater {
  /// Creates the updater.
  const PlatformHomeWidgetUpdater();

  static const String providerClass =
      'com.mostafasayed.quranyahdi.QuranYahdiWidgetProvider';

  @override
  Future<void> update({
    required String appName,
    required String label,
    required String prayer,
    required String time,
    required String city,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('app_name', appName);
      await HomeWidget.saveWidgetData<String>('next_prayer_label', label);
      await HomeWidget.saveWidgetData<String>('next_prayer', prayer);
      await HomeWidget.saveWidgetData<String>('next_prayer_time', time);
      await HomeWidget.saveWidgetData<String>('city', city);
      await HomeWidget.updateWidget(qualifiedAndroidName: providerClass);
    } on Object catch (error, stackTrace) {
      // A widget refresh must never break the app or the background plan.
      appLog('home widget update failed',
          name: 'quran_yahdi/widget', error: error, stackTrace: stackTrace);
    }
  }
}
