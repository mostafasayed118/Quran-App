import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/features/library/data/library_catalog.dart';
import 'package:quran_yahdi/features/library/presentation/library_screen.dart';

LibraryPackInfo _pack(String id, LibraryPackKind kind) => LibraryPackInfo(
      id: id,
      kind: kind,
      language: 'ar',
      titleAr: 'حزمة',
      titleEn: 'Pack',
      approxSizeMb: 1,
      version: 'v1',
      sourceUrl: 'https://example.test/$id.json',
    );

void main() {
  test('a kind with no packs is hidden (tafsir after the withdrawal)', () {
    final kinds = visibleLibraryKinds([
      _pack('translation', LibraryPackKind.translation),
      _pack('hadith', LibraryPackKind.hadith),
    ]);

    expect(kinds, [LibraryPackKind.translation, LibraryPackKind.hadith]);
  });

  test('all three kinds keep the documented tab order', () {
    final kinds = visibleLibraryKinds([
      _pack('hadith', LibraryPackKind.hadith),
      _pack('tafsir', LibraryPackKind.tafsir),
      _pack('translation', LibraryPackKind.translation),
    ]);

    expect(kinds, [
      LibraryPackKind.tafsir,
      LibraryPackKind.translation,
      LibraryPackKind.hadith,
    ]);
  });

  test('an empty catalog falls back to the three tabs', () {
    expect(visibleLibraryKinds(const []), [
      LibraryPackKind.tafsir,
      LibraryPackKind.translation,
      LibraryPackKind.hadith,
    ]);
  });
}
