import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the shipped Unicode Uthmani assets.
///
/// The reader renders these files instead of the database's private-use glyph
/// column, and selection/copy depend on them being real Unicode. A corrupt or
/// truncated file would silently fall back to the glyph column, so the data
/// itself is pinned here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pua = RegExp('[\uE000-\uF8FF]');
  final latin = RegExp('[A-Za-z]');

  // Normalise away the diacritics before matching: pinning exact marks makes
  // the test brittle against legitimate Uthmani orthography.
  String plain(String text) => text
      .replaceAll(
        RegExp('[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D3-\u08FF]'),
        '',
      )
      .replaceAll('\u0671', '\u0627')
      .replaceAll('\u0622', '\u0627')
      .replaceAll('\u0623', '\u0627')
      .replaceAll('\u0625', '\u0627')
      .replaceAll('\u0649', '\u064A')
      .replaceAll(RegExp(r'\s+'), '');

  test('all 114 surahs ship, with 6236 real Unicode ayahs', () async {
    var total = 0;
    for (var surah = 1; surah <= 114; surah++) {
      final raw = await rootBundle.loadString(
        'assets/quran/uthmani/$surah.json',
      );
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded, isNotEmpty, reason: 'surah $surah is empty');
      total += decoded.length;
      for (final entry in decoded.entries) {
        final text = entry.value as String;
        expect(text.trim(), isNotEmpty, reason: '$surah:${entry.key} is blank');
        expect(pua.hasMatch(text), isFalse,
            reason: '$surah:${entry.key} leaked a glyph codepoint');
        expect(latin.hasMatch(text), isFalse,
            reason: '$surah:${entry.key} leaked latin');
      }
    }
    expect(total, 6236);
  });

  test('known verses read correctly', () async {
    final fatiha = jsonDecode(
      await rootBundle.loadString('assets/quran/uthmani/1.json'),
    ) as Map<String, dynamic>;
    expect(fatiha.length, 7);
    expect(plain(fatiha['1'] as String), contains('بسماللهالرحمنالرحيم'));
    expect(plain(fatiha['7'] as String), contains('الضالين'));

    final baqara = jsonDecode(
      await rootBundle.loadString('assets/quran/uthmani/2.json'),
    ) as Map<String, dynamic>;
    // Ayat al-Kursi, and the surah's first ayah must NOT repeat the basmala
    // (the reader draws it once as a header).
    expect(plain(baqara['255'] as String), contains('اللهلاالهالاهو'));
    expect(plain(baqara['1'] as String), isNot(contains('بسم')));
  });

  test('no surah repeats the basmala that the reader draws itself', () async {
    // Al-Fatiha carries the basmala as verse 1, and Surah 9 has none at all, so
    // the guard starts at 2. Normalised, because the omission is about the
    // words and not about one edition's marks.
    for (var surah = 2; surah <= 114; surah++) {
      final decoded = jsonDecode(
        await rootBundle.loadString('assets/quran/uthmani/$surah.json'),
      ) as Map<String, dynamic>;
      expect(
        plain(decoded['1'] as String),
        isNot(contains('بسم')),
        reason: 'surah $surah stores the repeated basmala',
      );
    }
  });
}
