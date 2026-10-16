import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../core/di/injector.dart';
import '../features/notifications/data/reminder_scheduler.dart';
import '../features/notifications/data/reminder_scheduling.dart';
import '../features/notifications/data/reminder_settings.dart';
import '../features/prayer/data/city_repository.dart';
import '../features/prayer/data/prayer_time_service.dart';

const citiesAssetKey = 'assets/data/cities.json';
const azkarAssetKey = 'assets/data/azkar.json';
const duasAssetKey = 'assets/data/duas.json';
const ruqyahAssetKey = 'assets/data/ruqyah.json';
const asmaAssetKey = 'assets/data/asma.json';
const libraryCatalogAssetKey = 'assets/data/library_catalog.json';

Future<Directory> defaultAudioRootResolver() async {
  final dir = await getApplicationSupportDirectory();
  return dir;
}

Future<Directory> defaultLibraryRootResolver() async {
  final dir = await getApplicationSupportDirectory();
  return dir;
}

Future<List<Map<String, dynamic>>> defaultCitiesLoader() async {
  final raw = await rootBundle.loadString(citiesAssetKey);
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

Future<Map<String, dynamic>> defaultAzkarLoader() async {
  final raw = await rootBundle.loadString(azkarAssetKey);
  return jsonDecode(raw) as Map<String, dynamic>;
}

Future<List<Map<String, dynamic>>> defaultDuasLoader() async {
  final raw = await rootBundle.loadString(duasAssetKey);
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> defaultRuqyahLoader() async {
  final raw = await rootBundle.loadString(ruqyahAssetKey);
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> defaultAsmaLoader() async {
  final raw = await rootBundle.loadString(asmaAssetKey);
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> defaultLibraryCatalogLoader() async {
  final raw = await rootBundle.loadString(libraryCatalogAssetKey);
  return ((jsonDecode(raw) as Map<String, dynamic>)['packs'] as List)
      .cast<Map<String, dynamic>>();
}

/// W7b boot glue: recompute + reschedule reminders once per app start (PM
/// ruling — no background isolate, no boot receiver in v1; missed-while-dead
/// reminders are accepted). The shared helper is guarded and never throws.
Future<void> runBootReminderSchedule() => scheduleReminders(
      city: getIt<CityRepository>(),
      prayer: getIt<PrayerTimeService>(),
      settings: getIt<ReminderSettings>(),
      scheduler: getIt<ReminderScheduler>(),
    );
