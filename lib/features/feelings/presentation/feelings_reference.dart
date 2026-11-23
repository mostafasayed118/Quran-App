// Presentation-only formatting of a verse reference. The data layer returns
// raw numbers and raw surah names; the locale picks the name and the label
// template here. The Quranic Arabic text itself is never translated.
import 'package:flutter/widgets.dart';
import 'package:quran_yahdi/l10n/app_localizations.dart';

import '../data/feelings_repository.dart';

/// The catalog's English surah name in English mode, the Arabic name otherwise.
String feelingSurahName(BuildContext context, FeelingVerseView verse) {
  final en = Localizations.localeOf(context).languageCode == 'en';
  if (en && verse.surahNameEn.isNotEmpty) return verse.surahNameEn;
  return verse.surahName;
}

/// «سورة X، الآية Y» / "Surah X, Ayah Y".
String feelingReference(BuildContext context, FeelingVerseView verse) =>
    AppLocalizations.of(context)
        .feelingsRefLine(feelingSurahName(context, verse), verse.verse.ayah);

/// «سورة X • الآية Y • الجزء Z» / "Surah X • Ayah Y • Juz Z".
String feelingMetadata(BuildContext context, FeelingVerseView verse) =>
    AppLocalizations.of(context).feelingsMetaLine(
      feelingSurahName(context, verse),
      verse.verse.ayah,
      verse.juz,
    );
