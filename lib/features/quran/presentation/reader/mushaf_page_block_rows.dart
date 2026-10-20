import 'package:quran_yahdi/core/db/app_database.dart';

import '../../data/verse_mapping.dart';
import 'mushaf_page_block.dart';

/// The parameter stays a list of drift rows: the frozen grouping test feeds
/// `repo.surahAyahs(...)` straight in; rows are mapped to entities here.
List<MushafPageBlock> groupAyahsByPage(List<Ayah> ayahs) =>
    groupVersesByPage([for (final ayah in ayahs) ayah.toVerse()]);
