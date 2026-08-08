import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranState {
  List<dynamic> arabic = [];
  List<dynamic> quran = [];
  double arabicFontSized = 28.0;
  double mushafFontSized = 40.0;
  int bookmarkedSurah = 1;
  int bookmarkedAyah = 1;

  Future<void> loadJson() async {
    final String response =
        await rootBundle.loadString('assets/json/hafs_smart_v8.json');
    final data = json.decode(response);
    arabic = data['quran'];
    quran = [arabic];
  }

  Future<void> loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      arabicFontSized = prefs.getInt('arabicFontSize')!.toDouble();
      mushafFontSized = prefs.getInt('mushafFontSize')!.toDouble();
    } catch (_) {
      arabicFontSized = 28.0;
      mushafFontSized = 40.0;
    }
  }

  Future<void> saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('arabicFontSize', arabicFontSized.toInt());
    await prefs.setInt('mushafFontSize', mushafFontSized.toInt());
  }

  Future<bool> loadBookmark() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      bookmarkedAyah = prefs.getInt('ayah')!;
      bookmarkedSurah = prefs.getInt('surah')!;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveBookmark(int surah, int ayah) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('surah', surah);
    await prefs.setInt('ayah', ayah);
  }
}

final QuranState quranState = QuranState();
