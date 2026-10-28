import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'package:quran_yahdi/core/domain/city.dart';
import 'package:quran_yahdi/core/domain/prayer_times.dart';
import 'package:quran_yahdi/core/domain/reminders.dart';
import 'package:quran_yahdi/features/library/data/library_catalog.dart';

import 'di/injector.dart';

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
  final packs = ((jsonDecode(raw) as Map<String, dynamic>)['packs'] as List)
      .cast<Map<String, dynamic>>();
  // Store-bound content: every pack must declare its integrity hashes.
  requirePinnedCatalogEntries(packs);
  return packs;
}

/// W7b boot glue: recompute + reschedule reminders once per app start (PM
/// ruling — no background isolate, no boot receiver in v1; missed-while-dead
/// reminders are accepted). The shared helper is guarded and never throws, and
/// it honours the persisted prayer-reminder toggle.
Future<void> runBootReminderSchedule() =>
    getIt<ReminderRescheduler>().reschedule(
      city: getIt<CitySource>(),
      prayer: getIt<PrayerTimesPort>(),
      scheduler: getIt<ReminderSchedulerPort>(),
    );
