import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

const citiesAssetKey = 'assets/data/cities.json';

Future<Directory> defaultAudioRootResolver() async {
  final dir = await getApplicationSupportDirectory();
  return dir;
}

Future<List<Map<String, dynamic>>> defaultCitiesLoader() async {
  final raw = await rootBundle.loadString(citiesAssetKey);
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}
