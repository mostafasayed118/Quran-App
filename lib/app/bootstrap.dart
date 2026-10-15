import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

const citiesAssetKey = 'assets/data/cities.json';
const azkarAssetKey = 'assets/data/azkar.json';
const duasAssetKey = 'assets/data/duas.json';
const ruqyahAssetKey = 'assets/data/ruqyah.json';

Future<Directory> defaultAudioRootResolver() async {
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
